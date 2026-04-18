# Architecture Document

## 1. Overview / Goals

*[What does this system do? What are the top 3-5 quality attributes (performance, security, scalability, etc.)?]*

## 2. Technology Stack

| Concern | Choice | Rationale |
|---------|--------|-----------|
| Language | *...* | *...* |
| Framework | *...* | *...* |
| Database | *...* | *...* |
| API Style | *...* | *...* |
| Auth | *...* | *...* |
| Frontend | *...* | *...* |
| Deployment | *...* | *...* |

## 3. Module Map

```
┌─────────────────────────────────────────────┐
│                 [Module A]                  │
│  Responsibility: ...                        │
│  Public API: ...                            │
│  Depends on: [Module B], [Module C]         │
└─────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────┐
│                 [Module B]                  │
│  Responsibility: ...                        │
│  Public API: ...                            │
│  Depends on: [Shared Kernel]                │
└─────────────────────────────────────────────┘
```

### Module A
- **Responsibility:** *[what this module does]*
- **Public API:** *[key interfaces it exposes]*
- **Depends on:** *[modules this module imports]*
- **Boundaries:** *[what this module does NOT do]*

## 4. Dependency Rules

*[Which module can import which. E.g., "Only domain modules can import infrastructure", or "No circular dependencies allowed"]*

## 5. Interface Contracts

Interface contracts are defined in `state/architect/interfaces/`:
- `auth-api.md` — Authentication endpoints
- `user-api.md` — User management endpoints
- `*` — *[others]*

## 6. Data Models

*[Key domain objects and their shapes. Reference interface files for details.]*

## 7. Security Considerations

*[Authentication strategy, authorization model, sensitive data handling, etc.]*

## 8. Performance Considerations

*[Expected load profiles, caching strategy, async patterns, etc.]*

## 9. Deployment Model

*[How the system is deployed (containers, serverless, etc.), environment layout, CI/CD approach]*
