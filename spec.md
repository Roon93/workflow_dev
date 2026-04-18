# Claude Code 多 Agent 软件开发工作流插件 - 项目规格说明书（插件兼容版）

## 1. 项目概述

基于 Claude Code 插件机制实现的多 Agent 协作软件开发工作流。插件通过定义专业角色 Agent、技能入口、工作流状态、Hook 和本地工具，将需求澄清、架构设计、任务拆解、并行开发、审核和验收串成一个可恢复、可追踪、可审计的开发流程。

本项目的核心目标不是自行实现一个 Claude 运行时，而是：

- 使用 Claude Code 官方插件结构作为集成方式
- 使用 Claude Code 原生 sub-agents / agent teams 作为多 Agent 执行机制
- 使用插件自带的 MCP/CLI 工具管理状态、DAG、Git 和检查点
- 将工作流事实状态持久化到仓库内，支持断点续跑和人工介入

核心特性：
- 需求阶段与用户交互式确认，不明确则反复澄清
- 架构师直接基于需求完成架构设计与接口定义
- 任务规划师基于架构产出做精细任务拆解
- 验收标准由用户确认后作为最终质量基准
- 开发 Agent 组按 DAG 依赖和文件范围约束执行 TDD
- 每个 Agent 角色可以声明推荐模型层级，但不把底层运行时细节写死到插件规范中
- 全流程状态落盘，及时 git commit，支持断点续跑与回退

## 2. 插件实现原则

### 2.1 插件边界

本项目必须按 Claude Code 当前插件机制实现，而不是按传统 Node 应用入口实现。

插件侧职责：
- 定义插件元数据
- 定义技能入口
- 定义角色 Agent
- 定义 Hook 行为
- 暴露本地 MCP/CLI 工具
- 组织工作流状态和文档产物

插件不负责的事项：
- 不直接实现 Claude 子进程池
- 不自行维护长期常驻的 Agent Runtime
- 不绕过 Claude Code 原生的 sub-agents / agent teams 能力
- 不假设所有 Agent 都拥有彼此完全隔离的权限和工具集

### 2.2 实现策略

本项目采用以下架构：

```text
用户
  │
  ▼
Claude Code
  │
  ├── 插件 skills 作为入口
  ├── workflow-lead 作为主协调 Agent
  ├── specialist agents 作为专业角色
  ├── hooks 做阶段门控与结果校验
  └── MCP/CLI 工具负责状态、DAG、Git、checkpoint
```

关键原则：
- 多 Agent 协作由 Claude Code 原生机制承担
- 工作流业务状态由插件自己的状态文件承担
- Lead Agent 通过工具读写状态，而不是直接依赖某个内部运行时会话
- 所有“断点续跑”基于 `state/` 中的业务事实重建

## 3. 核心工作流

```text
Phase 1: 需求分析（交互式）
    │  ←→ 用户确认 loop
    │  产出：结构化需求 + 功能级验收标准草案
    │  ✅ 用户确认 → 落盘 → git commit
    ▼
Phase 2: 架构设计
    │  架构师读取确认后的需求
    │  产出：架构文档、接口定义、模块边界
    │  ✅ 用户确认 → 落盘 → git commit
    ▼
Phase 3: 任务规划
    │  任务规划师基于需求 + 架构 + 接口，拆解为原子级任务 DAG
    │  产出：任务列表、依赖关系、任务级验收标准、文件范围
    │  ✅ 用户确认 → 落盘 → git commit
    ▼
Phase 4: 验收标准确认（质量门）
    │  汇总功能级 + 任务级验收标准，提交用户做最终确认
    │  ✅ 用户确认 → 落盘 → git commit
    ▼
Phase 5: 并行开发（TDD Loop）
    │  workflow-lead 按 task-board 和文件冲突约束，调用 Claude Code agent teams / sub-agents
    │  每个 Dev Agent: 写测试 → 实现 → 跑测试 → 修复 → commit
    ▼
Phase 6: 集成 & 审核
    │  合并分支 / worktree 结果 → 全量测试 → 代码审查
    │  ❌ → 标记失败任务 → 回到 Phase 5
    ▼
Phase 7: 验证验收
    │  对照用户确认的验收标准逐项验收
    │  ❌ 轻微 → 回到 Phase 5 修复
    │  ❌ 严重 → 回到 Phase 3 重新规划
    │  ✅ → Done
```

### 3.1 角色职责单一性

每个 Agent 在工作流中只承担单一职责：

| 角色 | 出现阶段 | 单一职责 |
|------|---------|---------|
| workflow-lead | 全流程 | 调用工具、维持状态、切换阶段、委派角色 |
| 需求分析师 | Phase 1 | 与用户交互，产出结构化需求 |
| 架构师 | Phase 2 | 架构设计、接口定义 |
| 任务规划师 | Phase 3 | 基于架构的精细任务拆解 |
| 开发 Agent × N | Phase 5 | TDD 模式实现单个任务 |
| 审核员 | Phase 6 | 代码审查、集成测试 |
| 验证员 | Phase 7 | 对照验收标准做最终验收 |

### 3.2 阶段门控

| 阶段 | 用户确认 | 确认内容 |
|------|---------|---------|
| Phase 1 需求 | ✅ 必须 | 需求是否完整准确 |
| Phase 2 架构 | ✅ 必须 | 架构方案是否合理 |
| Phase 3 任务 | ✅ 必须 | 任务拆解是否合理、粒度是否足够 |
| Phase 4 验收标准 | ✅ 必须 | 验收标准是否完整、可衡量 |
| Phase 5 开发 | ❌ 自动为主 | 自动循环，必要时人工介入 |
| Phase 6 审核 | ❌ 自动为主 | 自动审核，重大问题可暂停 |
| Phase 7 验证 | ❌ 自动为主 | 基于已确认的验收标准验证 |

说明：
- “自动”表示由 lead agent 结合工具和 hooks 推进
- 当失败次数超阈值、Git 冲突无法自动处理、测试环境异常时，允许暂停并请求用户介入

## 4. 验收标准体系

验收标准是整个工作流的质量锚点，贯穿全流程。

### 4.1 两级验收标准

```text
功能级验收标准（Phase 1 产出，Phase 4 确认）
  │
  ├── AC-F01: 用户可以通过邮箱密码登录
  │     ├── AC-T001: login API 接受 email+password，返回 JWT
  │     ├── AC-T002: 无效凭证返回 401 + 错误码
  │     └── AC-T003: 登录表单有输入验证和错误提示
  │
  └── AC-F02: 用户可以注册新账号
        ├── AC-T004: register API 接受用户信息，创建账号
        └── AC-T005: 邮箱重复时返回 409
```

- 功能级（AC-F）：由需求分析师在 Phase 1 草拟，描述用户可感知行为
- 任务级（AC-T）：由任务规划师在 Phase 3 细化，描述具体技术验收条件
- Phase 4 汇总并锁定，作为验证阶段的唯一判定依据

### 4.2 验收标准结构

```json
{
  "version": 1,
  "confirmedAt": "...",
  "confirmedBy": "user",
  "featureCriteria": [
    {
      "id": "AC-F01",
      "description": "用户可以通过邮箱密码登录",
      "taskCriteria": [
        {
          "id": "AC-T001",
          "taskId": "task-001",
          "description": "login API 接受 email+password，返回 JWT",
          "verifiable": true,
          "verifyMethod": "unit-test"
        }
      ]
    }
  ]
}
```

### 4.3 验收标准流转

```text
Phase 1 → 草拟功能级 AC
Phase 3 → 细化任务级 AC
Phase 4 → 汇总 + 用户确认 → 锁定
Phase 5 → 任务级 AC 驱动 TDD
Phase 7 → 功能级 AC 驱动最终验收
```

## 5. Agent 角色定义

### 5.1 workflow-lead

- 职责：推进阶段流转，选择下一步动作，调用工具，委派给专业 Agent
- 输入：用户目标 + `state/` 下所有当前工作流状态
- 输出：阶段推进、状态更新、任务派发、暂停/恢复决策
- 关键行为：
  - 读取 `workflow.json` 确定当前阶段
  - 在每个阶段调用相应 specialist agent
  - 调用工具进行落盘、checkpoint、Git 操作、DAG 查询
  - 在失败阈值触发时暂停流程并请求用户介入

### 5.2 需求分析师

- 职责：与用户交互，产出结构化需求和功能级验收标准草案
- 输入：用户原始需求
- 输出：`state/requirements/confirmed.json`
- 关键行为：
  - 识别模糊点、矛盾点、缺失项
  - 为每个功能点草拟可衡量的 AC-F
  - 记录问答历史

### 5.3 架构师

- 职责：基于确认后的需求完成架构设计和接口定义
- 输入：`state/requirements/confirmed.json`
- 输出：`state/architect/`
- 关键行为：
  - 技术选型和模块划分
  - 定义接口契约
  - 明确模块边界和依赖方向

### 5.4 任务规划师

- 职责：基于需求和架构产出，拆解为原子级任务 DAG
- 输入：`state/requirements/confirmed.json` + `state/architect/`
- 输出：`state/planner/task-board.json`
- 关键行为：
  - 生成原子任务
  - 定义依赖关系
  - 生成任务级验收标准
  - 标注文件读写范围
  - 标注并行组和冲突约束

### 5.5 开发 Agent

- 职责：以 TDD 模式完成单个任务
- 输入：TaskHandoff
- 输出：代码 + 测试 + git commits + 执行日志
- 关键行为：
  - 严格对齐任务级 AC
  - 先写测试再实现
  - 提交前运行约定测试
  - 回写 dev-log 和任务状态

### 5.6 审核员

- 职责：代码审查 + 集成测试
- 输入：已完成任务分支或集成结果 + 验收标准
- 输出：`state/review/review-report.json`
- 关键行为：
  - 聚合任务结果
  - 执行全量测试
  - 给出返工任务清单

### 5.7 验证员

- 职责：对照最终确认的验收标准做最终验收
- 输入：完整代码 + `state/acceptance-criteria/confirmed.json`
- 输出：`state/verify/verify-report.json`
- 关键行为：
  - 逐项检查 AC-F 是否满足
  - 对缺陷分级
  - 指定回流阶段

### 5.8 模型配置原则

模型配置写成“层级策略”，不在规格中绑定具体快照版本。

```json
{
  "models": {
    "workflowLead": { "tier": "high" },
    "requirementAnalyst": { "tier": "medium" },
    "architect": { "tier": "high" },
    "taskPlanner": { "tier": "high" },
    "developer": {
      "defaultTier": "medium",
      "byComplexity": {
        "low": "low",
        "medium": "medium",
        "high": "high"
      }
    },
    "reviewer": { "tier": "medium" },
    "verifier": { "tier": "medium" }
  }
}
```

说明：
- 具体模型名通过插件配置或运行环境注入
- 规格只约束能力层级，不约束供应商快照名称

## 6. 开发 Agent 组编排与调度

这是整个系统最复杂的部分，但实现方式必须遵循 Claude Code 插件边界。

### 6.1 调度架构

```text
workflow-lead
   │
   ├── 读取 task-board
   ├── 调用工具筛选 ready tasks
   ├── 调用工具做文件冲突检测
   ├── 依据 maxConcurrency 选择派发批次
   └── 通过 Claude Code 原生 sub-agents / agent teams 委派开发 Agent
          │
          ├── developer task-001
          ├── developer task-002
          └── developer task-003
```

### 6.2 调度算法（DAG 驱动）

```text
输入：task-board.json
配置：maxConcurrency

LOOP:
  1. 查询 status=todo 的任务
  2. 过滤出 dependsOn 全部完成的 ready tasks
  3. 结合 files.create / files.modify 做冲突检测
  4. 在无冲突任务中按 priority 排序
  5. 选出可并行执行的批次
  6. 为每个任务生成 TaskHandoff
  7. 由 workflow-lead 委派开发 Agent 执行
  8. 每个任务完成后回写状态
  9. 若任务失败，则写入失败上下文并触发重试或阻塞下游
 10. 持续循环直到全部完成或进入人工介入状态
```

### 6.3 生命周期

每个开发任务经历以下生命周期：

```text
Ready → Dispatched → In Progress → Review Pending → Done
                          │
                          ├── Failed
                          └── Blocked
```

任务执行时：
- lead agent 负责准备上下文
- developer agent 负责单任务 TDD
- MCP/CLI 工具负责写状态、写日志、做 Git 操作

### 6.4 并行失败处理

```text
任务失败
  │
  ├── 未超过 maxTddRounds → 同任务重试
  ├── 超过 maxTddRounds → 标记 failed
  ├── 有下游依赖 → 下游标记 blocked
  └── 无关任务继续执行
```

关键原则：
- 单任务失败不自动中断无关任务
- blocked 只影响依赖链
- 连续失败超过阈值则暂停开发阶段
- 所有失败必须带上下文回写到状态目录

### 6.5 并行冲突预防

冲突预防分两层：

规划阶段：
- 为每个任务标注 `files.create`、`files.modify`、`files.read`
- 同一并行批次内不允许 `create` 和 `modify` 存在交集
- 如果存在交集，必须改任务拆分或建立依赖

运行阶段：
- 派发前再次调用工具校验文件冲突
- 检测到冲突则降级为串行

## 7. TDD 开发循环

### 7.1 单任务流程

```text
1. 读取 TaskHandoff
2. 基于任务级 AC 编写测试
3. 运行测试，预期先失败
4. 编写实现
5. 运行测试
6. 失败则分析并重试
7. 通过则可选重构
8. 再次运行测试
9. 更新日志和状态
10. git commit
```

### 7.2 TDD 约束

- 每个任务最多 `tddMaxRounds` 轮重试
- 每轮失败信息必须写入 `dev-log.json`
- 下一轮必须携带上一轮失败上下文
- 测试用例必须覆盖任务级 AC
- 如测试环境不可用，任务状态应标记为 `environment_blocked`

## 8. 任务交接上下文设计

### 8.1 TaskHandoff 结构

```typescript
interface TaskHandoff {
  taskId: string;
  title: string;
  description: string;
  relatedRequirements: string[];
  acceptanceCriteria: {
    featureLevel: string;
    taskLevel: string[];
  };
  architectureContext: string;
  interfaceSpecs: string[];
  interfaceRef: string;
  moduleContext: string;
  files: {
    create: string[];
    modify: string[];
    read: string[];
  };
  dependencyOutputs: {
    taskId: string;
    summary: string;
    createdFiles: string[];
  }[];
  previousAttempt?: {
    round: number;
    failureReason: string;
    reviewComments: string[];
    failingTests: string[];
    errorLogs: string[];
  };
  modelTier: "low" | "medium" | "high";
}
```

### 8.2 上下文精简原则

- 只提供当前任务必需信息
- 只摘取相关架构片段
- 只附带相关接口定义
- 依赖任务只传摘要和产物
- 控制上下文体积，避免把整个仓库灌给开发 Agent

## 9. 状态管理与持久化

### 9.1 状态目录结构

```text
state/
├── workflow.json
├── requirements/
│   ├── raw-input.md
│   ├── qa-history.json
│   └── confirmed.json
├── architect/
│   ├── architecture.md
│   ├── interfaces/
│   └── module-boundaries.md
├── planner/
│   └── task-board.json
├── acceptance-criteria/
│   └── confirmed.json
├── dev/
│   └── {task-id}/
│       ├── context.json
│       ├── test-plan.md
│       └── dev-log.json
├── review/
│   └── review-report.json
├── verify/
│   └── verify-report.json
└── checkpoints/
    ├── after-requirements.json
    ├── after-architect.json
    ├── after-planner.json
    ├── after-acceptance.json
    └── after-dev.json
```

### 9.2 状态设计原则

- `state/` 只保存工作流业务事实状态
- 不把 Claude 内部运行态当作可恢复对象
- 恢复流程时，由 lead agent 根据 `state/` 重建工作流

### 9.3 workflow.json

```json
{
  "id": "workflow-uuid",
  "name": "feature-name",
  "currentPhase": "DEVELOPMENT",
  "status": "in_progress",
  "phases": {
    "REQUIREMENTS": { "status": "completed", "completedAt": "..." },
    "ARCHITECT": { "status": "completed", "completedAt": "..." },
    "TASK_PLANNING": { "status": "completed", "completedAt": "..." },
    "ACCEPTANCE_CONFIRM": { "status": "completed", "completedAt": "..." },
    "DEVELOPMENT": { "status": "in_progress", "startedAt": "..." },
    "REVIEW": { "status": "pending" },
    "VERIFY": { "status": "pending" }
  },
  "scheduler": {
    "totalTasks": 8,
    "done": 3,
    "inProgress": 2,
    "todo": 2,
    "failed": 0,
    "blocked": 1,
    "environmentBlocked": 0
  },
  "retryCount": 0,
  "maxRetries": 3,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 9.4 task-board.json

```json
{
  "tasks": [
    {
      "id": "task-001",
      "title": "实现用户登录 API",
      "description": "基于 AuthAPI.login 接口定义实现",
      "dependsOn": [],
      "status": "done",
      "priority": "high",
      "complexity": "medium",
      "modelTier": "medium",
      "assignedBranch": "feat/task-001",
      "parallelGroup": "auth-core",
      "files": {
        "create": ["src/api/auth.ts"],
        "modify": [],
        "read": ["state/architect/interfaces/api-contracts.ts"]
      },
      "acceptanceCriteria": {
        "featureRef": "AC-F01",
        "taskLevel": ["AC-T001", "AC-T002"]
      },
      "interfaceRef": "AuthAPI.login",
      "tddRounds": 2,
      "lastFailure": null
    }
  ],
  "dag": {
    "edges": [
      { "from": "task-001", "to": "task-004" },
      { "from": "task-002", "to": "task-004" }
    ]
  }
}
```

### 9.5 落盘时机

| 事件 | 落盘内容 |
|------|---------|
| 用户每轮问答 | `qa-history.json` 追加 |
| 需求确认 | `confirmed.json` + checkpoint |
| 架构设计完成 | `architect/` + checkpoint |
| 任务规划完成 | `task-board.json` + checkpoint |
| 验收标准确认 | `acceptance-criteria/confirmed.json` + checkpoint |
| 任务派发 | `context.json` |
| TDD 每轮结束 | `dev-log.json` 追加 |
| 任务完成 | Git commit + task status 更新 |
| 调度器状态变化 | `workflow.json` 更新 |
| 审核完成 | `review-report.json` |
| 验证完成 | `verify-report.json` |

## 10. Git 策略

### 10.1 分支模型

```text
main
  │
  └── workflow/{workflow-id}/base
        ├── feat/{task-id}
        ├── feat/{task-id}
        └── workflow/{workflow-id}/integration
```

说明：
- 若运行环境更适合 worktree，也允许按 `worktrees/{task-id}` 方式隔离
- 分支隔离和 worktree 隔离属于实现策略，可二选一，但必须在配置中固定

### 10.2 Commit 规范

```text
docs(requirements): 需求确认完成
docs(architect): 架构设计完成
docs(planner): 任务规划完成 - N个任务
docs(acceptance): 验收标准确认锁定

feat({task-id}): TDD round {n} - {summary}
feat({task-id}): 任务完成 - {title}

integrate: 合并 {n} 个任务结果
fix({task-id}): 修复审核问题 - {summary}
```

### 10.3 回退策略

- 每个阶段完成后创建 checkpoint
- checkpoint 由状态快照 + Git tag 组成
- 开发阶段允许任务级回退
- 验证失败可回退到最近可用 checkpoint

## 11. 错误处理与重试

| 层级 | 触发条件 | 范围 | 回退目标 |
|------|---------|------|---------|
| L1 | TDD 测试不通过 | 单任务内部 | 同任务下一轮 TDD |
| L2 | 超过最大轮次 | 单任务 | 标记 failed |
| L3 | 审核不通过 | 失败任务 | Phase 5 |
| L4 | 验证轻微问题 | 相关任务 | Phase 5 |
| L5 | 验证严重偏差 | 工作流局部 | Phase 3 |
| L6 | 环境异常或大面积失败 | 整个工作流 | 暂停并等待用户介入 |

每次重试必须携带：
- 失败原因
- 审核意见
- 失败测试
- 建议修复方向

## 12. Claude Code 插件结构

```text
claude-dev-workflow-plugin/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── workflow-lead.md
│   ├── requirement-analyst.md
│   ├── architect.md
│   ├── task-planner.md
│   ├── developer.md
│   ├── reviewer.md
│   └── verifier.md
├── skills/
│   ├── start-workflow/
│   │   └── SKILL.md
│   ├── resume-workflow/
│   │   └── SKILL.md
│   ├── approve-gate/
│   │   └── SKILL.md
│   ├── workflow-status/
│   │   └── SKILL.md
│   └── retry-failed-tasks/
│       └── SKILL.md
├── hooks/
│   ├── hooks.json
│   └── scripts/
├── bin/
│   └── workflow-cli
├── mcp/
│   └── workflow-server
├── state/
├── schemas/
├── templates/
└── spec.md
```

### 12.1 各目录职责

- `.claude-plugin/plugin.json`：插件元数据、版本、声明
- `agents/`：专业角色定义
- `skills/`：用户入口和工作流操作入口
- `hooks/`：阶段门控、提交前校验、状态同步
- `bin/`：本地命令行工具
- `mcp/`：面向 Agent 的结构化工具接口
- `state/`：工作流状态
- `schemas/`：JSON Schema 和类型约束
- `templates/`：需求、架构、任务、报告模板

## 13. 插件内工具设计

推荐将核心能力以 MCP tools 或本地 CLI 形式暴露，供 lead agent 和 specialist agents 调用。

建议工具集：

| 工具 | 作用 |
|------|------|
| `workflow.init` | 初始化工作流目录和 `workflow.json` |
| `workflow.load` | 读取当前工作流状态 |
| `workflow.advance_phase` | 切换阶段并写 checkpoint |
| `tasks.list_ready` | 返回 ready tasks |
| `tasks.update_status` | 更新任务状态 |
| `tasks.detect_conflicts` | 校验文件冲突 |
| `handoff.build` | 构建 TaskHandoff |
| `state.append_log` | 追加日志 |
| `git.create_branch` | 创建任务分支 |
| `git.commit` | 创建 commit |
| `git.merge_integration` | 合并到集成分支 |
| `git.tag_checkpoint` | 创建 checkpoint tag |
| `verify.record_result` | 写验收结果 |

实现要求：
- 工具必须幂等或可安全重试
- 所有工具返回结构化 JSON
- 工具失败时必须返回可追踪错误码

## 14. Hooks 设计

Hooks 只做轻量、确定性的校验和触发，不承担复杂业务决策。

建议 hooks：
- `on_workflow_initialized`：初始化目录与默认状态
- `before_phase_advance`：校验当前阶段产物是否完整
- `after_task_dispatched`：写入 `context.json`
- `after_tdd_round`：追加 `dev-log.json`
- `before_commit`：校验任务状态与测试结果是否满足提交条件
- `after_review_completed`：写入 review report
- `after_verify_completed`：写入 verify report

## 15. 配置项

插件配置与工作流配置分离。

### 15.1 插件配置

用于声明 Claude Code 插件元信息和少量插件级设置。

```json
{
  "name": "claude-dev-workflow",
  "version": "0.1.0"
}
```

### 15.2 工作流配置

由插件自己的配置文件承载，例如 `workflow.config.json`。

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
  "models": {
    "workflowLead": { "tier": "high" },
    "requirementAnalyst": { "tier": "medium" },
    "architect": { "tier": "high" },
    "taskPlanner": { "tier": "high" },
    "developer": {
      "defaultTier": "medium",
      "byComplexity": {
        "low": "low",
        "medium": "medium",
        "high": "high"
      }
    },
    "reviewer": { "tier": "medium" },
    "verifier": { "tier": "medium" }
  },
  "git": {
    "branchPrefix": "workflow",
    "autoCommit": true,
    "squashOnMerge": true,
    "isolationMode": "branch"
  },
  "stateDir": "./state",
  "templatesDir": "./templates"
}
```

## 16. 需求修订结论

本规格在保留原有业务目标的前提下，做了以下关键修订：

- 将“自建调度器进程池”改为“Claude Code lead agent + sub-agents / agent teams”
- 将“插件入口程序”改为“官方插件目录结构”
- 将“运行时状态恢复”改为“基于 `state/` 的业务状态恢复”
- 将“固定模型快照名”改为“能力层级 + 外部配置”
- 将“所有能力都在插件源码里实现”改为“插件定义 + MCP/CLI 工具实现”

该版本更符合 Claude Code 插件当前实现边界，也更适合作为后续落地开发的基线规格。
