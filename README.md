# roon_devwork

基于 Claude Code 插件机制的多 Agent 协作软件开发工作流插件。

将需求澄清、架构设计、任务拆解、并行开发、代码审核和验收串成一个可恢复、可追踪、可审计的开发流程。

## 安装

```bash
# 方式一：链接到插件目录
ln -s /path/to/roon_devwork ~/.claude/plugins/roon_devwork

# 方式二：直接使用 --plugin-dir
claude --plugin-dir /path/to/roon_devwork
```

## 快速开始

```bash
claude --plugin-dir /path/to/roon_devwork
```

进入 Claude Code 后，使用以下技能命令：

| 命令 | 说明 |
|------|------|
| `/start-workflow` | 启动新工作流 |
| `/workflow-status` | 查看当前状态 |
| `/approve-gate` | 确认当前阶段产出，进入下一阶段 |
| `/retry-failed-tasks` | 重试失败的任务 |

## 工作流程

```
Phase 1: 需求分析 ───────────────────────────────────────────────────────
  └── /start-workflow → 需求分析师 Agent 与你交互，澄清模糊需求
      → 产出：state/requirements/confirmed.json + Q&A 历史

Phase 2: 架构设计 ───────────────────────────────────────────────────────
  └── /approve-gate → 架构师 Agent 基于确认的需求产出架构文档
      → 产出：state/architect/architecture.md + interfaces/

Phase 3: 任务规划 ───────────────────────────────────────────────────────
  └── /approve-gate → 任务规划师 Agent 将架构拆解为 DAG 任务列表
      → 产出：state/planner/task-board.json

Phase 4: 验收标准确认 ──────────────────────────────────────────────────
  └── /approve-gate → 汇总功能级 + 任务级验收标准，你确认后锁定
      → 产出：state/acceptance-criteria/confirmed.json

Phase 5: 并行开发（TDD）──────────────────────────────────────────────
  └── workflow-lead 自动调度 N 个开发 Agent 并行实现任务
      → 每个任务：写测试 → 实现 → 修复 → commit
      → 失败任务可单独重试，不影响其他任务

Phase 6: 代码审核 ──────────────────────────────────────────────────────
  └── 审核员 Agent 聚合所有分支，运行全量测试，检查代码质量
      → 产出：state/review/review-report.json
      → 有返工任务 → 回到 Phase 5

Phase 7: 最终验收 ──────────────────────────────────────────────────────
  └── 验证员 Agent 对照确认的验收标准逐项检查
      → 产出：state/verify/verify-report.json
      → canShip=true → 完成
```

## 状态持久化

所有状态存在 `state/` 目录中，工作流可在任何时候中断和恢复：

```
state/
├── workflow.json              # 当前阶段、状态、调度器摘要
├── requirements/              # 需求分析产出
│   ├── qa-history.json
│   └── confirmed.json
├── architect/                # 架构设计产出
│   ├── architecture.md
│   └── interfaces/
├── planner/
│   └── task-board.json        # 任务 DAG
├── acceptance-criteria/
│   └── confirmed.json         # 锁定的验收标准
├── dev/                      # 每个任务独立的 TDD 日志
│   └── {task-id}/
├── review/
│   └── review-report.json
├── verify/
│   └── verify-report.json
└── checkpoints/               # 各阶段快照（git tag）
```

中断后恢复：
```bash
/resume-workflow   # 读取 state/workflow.json，重建上下文，继续
```

## 任务并行与冲突检测

任务规划阶段会为每个任务声明文件读写范围：

```json
{
  "files": {
    "create": ["src/api/auth.ts"],
    "modify": [],
    "read": ["state/architect/interfaces/auth-api.md"]
  }
}
```

调度器在同一批次并行任务时检测：
- 两个任务的 `create` 集合不能相交
- 任务的 `create` 与其他任务的 `modify` 不能相交

冲突的任务自动降级为串行执行，不会并行派发。

## TDD 约束

每个开发任务严格遵循：
1. 基于任务级验收标准（AC-T）先写测试
2. 测试失败后实现最小代码
3. 每轮失败写入 `dev-log.json`，携带失败上下文进入下一轮
4. 最多 `tddMaxRounds` 轮重试
5. 通过后 git commit 才算完成

## 错误恢复策略

| 层级 | 条件 | 策略 |
|------|------|------|
| L1 | 单任务 TDD 测试失败 | 同任务重试，最多 N 轮 |
| L2 | 超过最大轮次 | 标记 `failed`，阻塞下游依赖 |
| L3 | 审核不通过 | 回到 Phase 5，单独返工 |
| L4 | 验证轻微问题 | 回到 Phase 5 |
| L5 | 验证严重偏差 | 回到 Phase 3 重新规划 |
| L6 | 环境异常 / 大面积失败 | 暂停，请求人工介入 |

## MCP 工具

插件暴露 13 个 MCP 工具（通过 `workflow-cli` 实现）：

```
workflow.init           初始化工作流目录和 workflow.json
workflow.load          读取当前工作流状态
workflow.advance_phase  推进阶段并创建 checkpoint
tasks.list_ready        返回所有就绪任务（依赖完成 + 无冲突）
tasks.update_status     更新任务状态
tasks.detect_conflicts 检测任务间的文件冲突
handoff.build          为任务构建上下文交接对象
state.append_log       追加 dev-log 或 qa-history
git.create_branch      创建任务分支
git.commit             创建 git commit
git.merge_integration  合并到集成分支
git.tag_checkpoint      创建阶段 checkpoint tag
verify.record_result   写入验证结果
```

工具可通过 MCP 协议调用，或在 Claude Code 对话中通过 Agent 调用。

## 项目结构

```
roon_devwork/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据
├── agents/                      # 7 个角色 Agent 定义
│   ├── workflow-lead.md
│   ├── requirement-analyst.md
│   ├── architect.md
│   ├── task-planner.md
│   ├── developer.md
│   ├── reviewer.md
│   └── verifier.md
├── skills/                      # 用户入口（5 个技能）
│   ├── start-workflow/
│   ├── resume-workflow/
│   ├── approve-gate/
│   ├── workflow-status/
│   └── retry-failed-tasks/
├── hooks/
│   ├── hooks.json               # PreToolUse + Stop 钩子
│   └── scripts/                 # 钩子实现脚本
├── schemas/                     # JSON Schema 验证
├── templates/                   # 文档模板
├── bin/
│   └── workflow-cli             # Python MCP stdio 服务器
└── mcp/
    └── workflow-server.json     # MCP 服务声明
```

## 配置

工作流初始化后，在工作区根目录创建 `workflow.config.json`：

```json
{
  "maxConcurrency": 3,
  "tddMaxRounds": 5,
  "workflowMaxRetries": 3,
  "failureThreshold": 2,
  "requireUserApproval": {
    "afterRequirements": true,
    "afterArchitect": true,
    "afterTaskPlanning": true,
    "afterAcceptanceCriteria": true,
    "afterDevelopment": false,
    "afterReview": false
  },
  "git": {
    "branchPrefix": "workflow",
    "autoCommit": true,
    "isolationMode": "branch"
  }
}
```

## 注意事项

- 本插件不自带 Claude 子进程池——多 Agent 调度使用 Claude Code 原生的 sub-agents / agent teams 机制
- `state/` 是唯一可信的状态来源，不依赖 Claude 内部运行时状态
- 模型层级（low/medium/high）在配置中指定，不在代码中写死具体模型名
- Phase 1–4 每个阶段都需要你明确确认才能推进，Phase 5 之后由 Agent 自动驱动
