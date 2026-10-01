# PersonalFin — Backend Architecture

## 1. Style & Stack
Modular monolith first (FastAPI), split into services when scale demands. Clean module boundaries below make later extraction easy.

| Concern | Technology |
|---|---|
| API | Python 3.12, FastAPI, Pydantic v2 |
| DB | PostgreSQL 16 (+ `pgvector`), SQLAlchemy 2 + Alembic |
| Cache/Queue | Redis, Celery (or RQ) |
| AI | Claude API, RAG (pgvector), Plan Engine (pure Python) |
| Auth | OTP + Google OAuth → JWT (access 15 min / refresh 30 d, rotating) |
| Storage | S3-compatible (receipts, PDF exports) |
| Notifications | FCM |
| Infra | Docker, Kubernetes/ECS, Terraform, GitHub Actions |
| Observability | OpenTelemetry, Prometheus, Grafana, Sentry |

## 2. Component View

```mermaid
flowchart LR
    A[Android App] -->|REST/JSON + SSE| GW[API Gateway]
    GW --> M1[auth]
    GW --> M2[profile]
    GW --> M3[planner]
    GW --> M4[transactions]
    GW --> M5[goals]
    GW --> M6[advisor]
    GW --> M7[reports]
    M3 --> PE[Plan Engine]
    M3 --> M6
    M6 --> RAG[RAG Retriever]
    M6 --> LLM[LLM Gateway]
    M6 --> GR[Guardrails]
    PE --> DB[(PostgreSQL)]
    M1 & M2 & M4 & M5 & M7 --> DB
    M1 & M6 --> RC[(Redis)]
    W[Celery Workers] --> DB
    W --> FCM[FCM]
    SCH[Scheduler - cron] --> W
```

## 3. Modules & Responsibilities

| Module | Responsibility |
|---|---|
| **auth** | OTP issue/verify, Google login, JWT, device registry, session revocation |
| **profile** | Onboarding data, snapshots, health score, risk profile |
| **planner** | Month creation, income entry, plan generation, versions, approval |
| **plan-engine** | Deterministic allocation: constraints, templates, goal prioritisation, asset-class mapping |
| **transactions** | Expense CRUD, categories, recurring rules, sync, budget-vs-actual |
| **goals** | Goals, SIP maths, projections, net worth |
| **advisor** | Chat orchestration, context building, RAG, LLM calls, guardrails |
| **reports** | Monthly report card, trends, PDF/CSV export |
| **notifications** | Rules + scheduled reminders, FCM dispatch |
| **compliance** | Consent log, audit log, data export/erase |

## 4. Plan Engine (Core Algorithm)

```mermaid
flowchart TD
    I[Inputs: income, profile, snapshot, goals, dues, last 3-month actuals, template] --> C1[1 Reserve fixed obligations: EMI, rent, premiums]
    C1 --> C2[2 Essentials estimate: avg actuals blended with declared]
    C2 --> C3{Emergency fund < target?}
    C3 -- Yes --> C4[3 Allocate EF top-up up to cap]
    C3 -- No --> C5[3 Skip]
    C4 --> C6{High-interest debt?}
    C5 --> C6
    C6 -- Yes --> C7[4 Debt prepayment share]
    C6 -- No --> C8[4 Skip]
    C7 --> C9[5 Protection gap premiums]
    C8 --> C9
    C9 --> C10[6 Goals by priority x urgency]
    C10 --> C11[7 Investments: map by risk and horizon]
    C11 --> C12[8 Lifestyle cap per template]
    C12 --> C13[9 Buffer 3-5%]
    C13 --> V[Validate: sum = income, no negatives, constraints OK]
    V -->|fail| R[Re-balance loop, max N iterations]
    R --> V
    V -->|pass| O[Plan JSON]
    O --> L[LLM adds explanations and alternatives]
    L --> G[Guardrails check]
    G --> S[(Save plan v+1)]
```

**Plan JSON contract (excerpt)**
```json
{
  "month": "2026-10",
  "income_total": 60000,
  "template": "family_balanced",
  "rules_version": "2026.09.1",
  "allocations": [
    {"bucket": "essentials", "amount": 22000, "pct": 36.67,
     "reason": "Avg last 3 months ₹21.4k + 3% festive buffer"},
    {"bucket": "emergency_fund", "amount": 6000, "pct": 10.0,
     "reason": "You have 2.5 of 6 months covered"},
    {"bucket": "investment", "amount": 5000, "pct": 8.33,
     "breakdown": {"index_fund": 3000, "debt_fund": 1500, "gold": 500}}
  ],
  "warnings": [],
  "assumptions": ["Moderate risk", "Inflation 6%"]
}
```

**AI safety design**
- LLM receives a *structured, redacted* context (no name/phone/account no.).
- LLM output is JSON-schema constrained for explanations; amounts come only from engine.
- Guardrail checks block: guaranteed returns, specific stock/security tips, tax-evasion advice, medical/legal claims.
- Prompt templates, model version, and retrieved KB doc IDs logged for audit.

## 5. API Design (REST, `/api/v1`)

| Group | Method & Path | Description |
|---|---|---|
| Auth | `POST /auth/otp/request` · `POST /auth/otp/verify` · `POST /auth/google` · `POST /auth/refresh` · `POST /auth/logout` | Login flows |
| Profile | `GET/PUT /profile` · `POST /onboarding/sections/{name}` · `GET /onboarding/status` | Onboarding |
| Snapshot | `POST /snapshots` · `GET /snapshots/latest` · `GET /health-score` | Financial status |
| Assets/Debts | `CRUD /assets` · `CRUD /liabilities` · `CRUD /insurance` | Portfolio |
| Months | `POST /months` · `GET /months/{yyyy-mm}` · `PUT /months/{yyyy-mm}/income` | Month page |
| Plans | `POST /months/{yyyy-mm}/plans:generate` · `GET /months/{yyyy-mm}/plans` · `PATCH /plans/{id}/allocations` · `POST /plans/{id}:approve` | Planning |
| Calendar | `GET /months/{yyyy-mm}/calendar` | Heatmap + events |
| Transactions | `CRUD /transactions` · `POST /transactions:sync` · `GET /months/{yyyy-mm}/budget-status` | Tracking |
| Recurring | `CRUD /recurring` | Auto entries |
| Goals | `CRUD /goals` · `GET /goals/{id}/projection` | Goals |
| Advisor | `POST /advisor/chat` (SSE stream) · `GET /advisor/conversations` | Fin AI |
| What-if | `POST /simulations` | Scenario |
| Reports | `GET /reports/monthly/{yyyy-mm}` · `GET /reports/export?format=pdf\|csv` | Reports |
| Notifications | `GET /notifications` · `PUT /notifications/settings` | Alerts |
| Privacy | `POST /privacy/export` · `DELETE /privacy/account` | DPDP rights |

**Conventions:** JSON, ISO dates, amounts as integer **paise** or `NUMERIC(14,2)`, idempotency keys for sync/POST, cursor pagination, RFC 7807 errors, rate limits (e.g. 60 req/min/user; chat 20/min).

## 6. Sync Strategy (Offline-first)
Client generates UUIDs → queues mutations in Room → WorkManager pushes batches to `/transactions:sync` with `updated_at` + `client_id`; server resolves by *last-write-wins per field* with tombstones for deletes; client pulls deltas via `?since=<cursor>`.

## 7. Background Jobs

| Job | Schedule | Action |
|---|---|---|
| Recurring txn generator | Daily 00:05 IST | Create due recurring entries |
| Due reminders | Daily 08:00 | Push EMI/SIP/bill reminders |
| Budget breach checker | On txn + hourly | 80% / 100% alerts |
| Month-start prompt | 1st of month | "Enter income & get plan" |
| Month-end report | Last day 20:00 | Build report card |
| Net-worth snapshot | Monthly | Store snapshot |
| KB re-index | On KB update | Re-embed docs |

## 8. Security
- TLS 1.3, HSTS, cert pinning in app; WAF; per-IP & per-user rate limits.
- Passwords not used; OTP w/ attempt limits & cooldown; refresh-token rotation + reuse detection.
- Field-level encryption (AES-GCM, KMS-managed keys) for PII/financial identifiers; row-level tenancy checks (`user_id` on every query).
- Secrets in Secrets Manager; least-privilege IAM; dependency & container scanning.
- Immutable **audit_log**; consent records; PII redaction pipeline before LLM calls.
- Backups (PITR), encrypted; data residency in India (Mumbai region).
- OWASP ASVS / MASVS checklist; periodic pen-test.

## 9. Deployment

```mermaid
flowchart LR
    DEV[Git push] --> CI[GitHub Actions: lint, test, scan, build]
    CI --> REG[Container Registry]
    REG --> STG[Staging]
    STG -->|approval| PRD[Production K8s/ECS - Mumbai]
    PRD --> PG[(RDS PostgreSQL Multi-AZ)]
    PRD --> RD[(ElastiCache Redis)]
    PRD --> S3[(S3)]
    PRD --> OBS[Prometheus / Grafana / Sentry]
```

Environments: `dev`, `staging`, `prod`. Blue/green deploys; DB migrations via Alembic with backward-compatible steps.

## 10. Testing Strategy
Unit (engine rules — property-based tests: sum==income, no negatives) · API contract tests · golden-file tests for plans across personas · LLM eval set (accuracy, guardrails, tone) · load tests (k6) · Android UI tests (Compose) · security tests.

## 11. Scalability & Cost Notes
Cache health-score & report calculations in Redis; stream LLM responses (SSE); use smaller model for chat classification/routing, larger for plan explanation; cap tokens per user/day; read replicas when needed.
