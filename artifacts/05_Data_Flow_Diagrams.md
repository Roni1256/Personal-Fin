# PersonalFin — Data Flow Diagrams

## 1. DFD Level 0 — Context Diagram

```mermaid
flowchart LR
    U([User])
    SMS([SMS / OTP Provider])
    FCM([Firebase Cloud Messaging])
    LLM([LLM Provider - Claude API])
    AA([Account Aggregator - v2])

    SYS((PersonalFin System))

    U -- "Credentials, financial profile, monthly income, expenses, goals, chat queries" --> SYS
    SYS -- "Health score, monthly plan, budget status, insights, AI answers, reports" --> U
    SYS -- "OTP request" --> SMS
    SMS -- "Delivery status" --> SYS
    SYS -- "Push payloads" --> FCM
    FCM -- "Push to device" --> U
    SYS -- "Redacted context + prompt" --> LLM
    LLM -- "Explanations / chat response" --> SYS
    AA -. "Consented bank data" .-> SYS
```

## 2. DFD Level 1 — Whole Application

```mermaid
flowchart TB
    U([User])

    P1[1.0 Authentication]
    P2[2.0 Onboarding & Profile Management]
    P3[3.0 Financial Analysis - Health Score & Net Worth]
    P4[4.0 Month Setup & Income Entry]
    P5[5.0 Plan Engine - Allocation]
    P6[6.0 AI Advisor Orchestrator]
    P7[7.0 Expense Tracking]
    P8[8.0 Calendar & Budget Monitor]
    P9[9.0 Goals & Projections]
    P10[10.0 Reports & Insights]
    P11[11.0 Notifications]

    D1[(D1 Users & Auth)]
    D2[(D2 Profile & Snapshots)]
    D3[(D3 Assets, Liabilities, Insurance)]
    D4[(D4 Months, Plans, Allocations)]
    D5[(D5 Transactions & Categories)]
    D6[(D6 Goals)]
    D7[(D7 Conversations & AI Logs)]
    D8[(D8 Knowledge Base - vectors)]
    D9[(D9 Notifications)]

    LLM([LLM API])
    SMS([OTP Provider])
    FCM([FCM])

    U -->|phone / OTP| P1
    P1 <--> D1
    P1 --> SMS
    P1 -->|session token| U

    U -->|personal, income, expenses, assets, debts, insurance, goals, risk answers| P2
    P2 --> D2
    P2 --> D3
    P2 --> D6
    D2 & D3 --> P3
    P3 -->|score, net worth, gaps| D2
    P3 -->|health report| U

    U -->|month, income, one-off events| P4
    P4 --> D4
    P4 -->|month context| P5
    D2 & D3 & D6 & D5 -->|profile, debts, goals, past spend| P5
    P5 -->|structured plan numbers| P6
    D8 -->|relevant knowledge| P6
    P6 <-->|redacted prompt / response| LLM
    P6 -->|explained plan| P5
    P6 --> D7
    P5 -->|proposed plan| D4
    P5 -->|plan for review| U
    U -->|edits / approval| P5

    U -->|expense entries| P7
    P7 --> D5
    D4 & D5 --> P8
    P8 -->|heatmap, planned vs actual, safe-to-spend| U
    P8 -->|threshold breach| P11

    D6 & D4 --> P9
    P9 --> D6
    P9 -->|progress, ETA| U

    U -->|chat question| P6
    D2 & D4 & D5 & D6 -->|context| P6
    P6 -->|answer| U

    D4 & D5 & D2 --> P10
    P10 -->|report card, trends, exports| U

    P11 --> D9
    P11 --> FCM
    FCM --> U
```

## 3. DFD Level 2 — Monthly Plan Generation (Process 5.0)

```mermaid
flowchart TB
    IN[Month income + events + template choice] --> A[5.1 Assemble Context]
    DB1[(Profile / Debts / Goals / Past 3-mo actuals)] --> A
    A --> B[5.2 Reserve Fixed Obligations]
    B --> C[5.3 Compute Emergency Fund Gap]
    C --> D[5.4 Debt / Protection Allocation]
    D --> E[5.5 Goal Prioritisation]
    E --> F[5.6 Investment Mapping by Risk and Horizon]
    F --> G[5.7 Lifestyle & Buffer Caps]
    G --> H{5.8 Validate constraints}
    H -- Fail --> I[5.9 Re-balance] --> H
    H -- Pass --> J[5.10 Plan JSON]
    J --> K[5.11 Redact PII]
    K --> L[6.0 LLM: explanations and alternatives]
    KB[(Knowledge Base)] --> L
    L --> M[5.12 Guardrail check]
    M -- Blocked --> N[Fallback: template explanations] --> O
    M -- OK --> O[5.13 Save plan version]
    O --> P[(D4 Plans)]
    O --> Q[Return to user for review]
```

## 4. Sequence — First Login & Onboarding

```mermaid
sequenceDiagram
    actor U as User
    participant App as Android App
    participant API as Backend API
    participant OTP as OTP Provider
    participant DB as PostgreSQL

    U->>App: Enter phone number
    App->>API: POST /auth/otp/request
    API->>OTP: Send OTP
    U->>App: Enter OTP
    App->>API: POST /auth/otp/verify
    API->>DB: Create user, consent logs
    API-->>App: JWT access + refresh
    loop Each onboarding section
        U->>App: Fill section (income, assets, debts...)
        App->>API: POST /onboarding/sections/{name}
        API->>DB: Save section
    end
    App->>API: GET /health-score
    API->>DB: Read all data, compute
    API->>DB: Store snapshot + health score
    API-->>App: Score, net worth, gap analysis
    App-->>U: Health score reveal
```

## 5. Sequence — Monthly Plan Creation

```mermaid
sequenceDiagram
    actor U as User
    participant App as Android App
    participant API as Planner API
    participant PE as Plan Engine
    participant AI as AI Orchestrator
    participant LLM as LLM
    participant DB as PostgreSQL

    U->>App: New Month + enter income
    App->>API: POST /months  (ym, income, events)
    API->>DB: Save month + incomes + events
    App->>API: POST /months/{ym}/plans:generate
    API->>DB: Load profile, debts, goals, past actuals
    API->>PE: Generate(allocation inputs)
    PE-->>API: Plan JSON (validated)
    API->>AI: Explain(plan, redacted context)
    AI->>LLM: Prompt + RAG snippets
    LLM-->>AI: Explanations
    AI->>AI: Guardrail check
    AI-->>API: Explained plan
    API->>DB: Save plan v1 (proposed)
    API-->>App: Plan
    U->>App: Adjust sliders
    App->>API: PATCH /plans/{id}/allocations
    API->>PE: Re-validate
    PE-->>API: OK / warnings
    U->>App: Approve
    App->>API: POST /plans/{id}:approve
    API->>DB: status=approved, months.active_plan_id
    API-->>App: Month page ready (calendar + budgets)
```

## 6. Sequence — Expense Logging & Alerts (offline-first)

```mermaid
sequenceDiagram
    actor U as User
    participant App as Android App
    participant Room as Room DB
    participant API as Transactions API
    participant DB as PostgreSQL
    participant N as Notification Service
    participant FCM as FCM

    U->>App: Add expense (₹450, Dining)
    App->>Room: Insert (client_id, pending)
    App-->>U: Instant UI update
    App->>API: POST /transactions:sync (when online)
    API->>DB: Upsert by client_id
    API->>DB: Compute category spend vs plan
    alt Spend >= 80% of category budget
        API->>N: Budget alert event
        N->>FCM: Push notification
        FCM-->>U: "Dining at 82% of plan"
    end
    API-->>App: Server ids + deltas
    App->>Room: Mark synced
```

## 7. Sequence — AI Chat

```mermaid
sequenceDiagram
    actor U as User
    participant App as Android App
    participant AI as AI Orchestrator
    participant DB as PostgreSQL
    participant RAG as Knowledge Base
    participant LLM as LLM
    participant G as Guardrails

    U->>App: "Can I afford a ₹60k phone?"
    App->>AI: POST /advisor/chat (SSE)
    AI->>DB: Fetch profile, active plan, spend, goals
    AI->>AI: Redact PII, run affordability calc (deterministic)
    AI->>RAG: Retrieve relevant guidance
    AI->>LLM: Prompt (context + calc results + KB)
    LLM-->>AI: Streamed answer
    AI->>G: Validate content
    G-->>AI: Pass / rewrite
    AI-->>App: Stream tokens
    AI->>DB: Save message + AI run log
    App-->>U: Answer with assumptions and "Why?"
```

## 8. Data Dictionary (Flows)

| Flow | Data items |
|---|---|
| Profile data | age, city tier, dependents, occupation, risk answers, tax regime |
| Financial status | incomes, fixed/variable expenses, assets by class, loans (outstanding, rate, EMI), insurance cover |
| Month input | ym, income entries, one-off events, template |
| Plan | buckets, amounts, %, reasons, assumptions, warnings, rules_version |
| Expense | amount, category, date, payment mode, merchant, note, source |
| Budget status | planned, spent, remaining, safe-to-spend/day |
| AI request | redacted context, calc results, retrieved KB chunks, prompt version |
| Notification | type, title, body, schedule |
