# PersonalFin — Application Definition Document (ADD)

**Version:** 1.0 | **Platform:** Android (Kotlin / Jetpack Compose) | **Market:** India (INR) first

---

## 1. Vision & Problem Statement

Most people earn but never *plan*. Spreadsheets are tedious, finance apps only record the past, and human advisors are expensive. **PersonalFin** gives every user a personal AI finance advisor that:

1. Knows their complete financial profile (assets, debts, goals, risk appetite).
2. Creates a **month-by-month plan** the moment income is entered.
3. Tracks real spending against the plan and **adapts** it.

**Tagline:** *"Your money, planned by AI — every month."*

## 2. Goals & Non-Goals

**Goals**
- One-time deep onboarding; effortless monthly planning afterwards.
- Plans that are rule-based, explainable and personalised.
- Fast expense tracking (manual, SMS/UPI-assisted, receipt scan).
- Beautiful, calm, AI-flavoured UI in purple & white.

**Non-Goals (v1)**
- Executing trades or moving money (no broker/payment execution).
- Tax filing. (Tax *estimates & tips* only.)
- Guaranteeing returns.

## 3. Target Users / Personas

| Persona | Description | Key Need |
|---|---|---|
| **Arun, 23** – First-job salaried | ₹35k/month, no savings habit | Simple budget, emergency fund, first SIP |
| **Meera, 32** – Dual-income family | Home loan, child, insurance gaps | Debt vs invest balance, goal planning |
| **Karthik, 28** – Freelancer | Irregular income | Variable-income smoothing, tax buffer |
| **Suresh, 45** – Pre-retirement | Corpus building | Retirement planning, risk reduction |

## 4. Core User Journey

```
Sign up / Login ─► Financial Health Onboarding (one time)
        │
        ▼
 AI builds Financial Profile + Health Score
        │
        ▼
 Each month:  Enter income ─► AI generates Monthly Plan ─► User reviews/edits ─► Approves
        │
        ▼
 Month page with Calendar ─► Log expenses daily ─► AI nudges, alerts, mid-month re-balance
        │
        ▼
 Month-end: Report card ─► Learnings ─► Next month's plan is smarter
```

## 5. Feature Specification

### 5.1 Authentication & Security (MVP)
- Phone number + OTP login; Google Sign-In; optional email.
- Biometric / PIN app lock.
- Consent screens (data usage, AI disclaimer, DPDP Act 2023 compliance).

### 5.2 Smart Onboarding — "Financial Health Check" (MVP)
Conversational + form hybrid, resumable, with progress bar. Collects:

| Section | Parameters |
|---|---|
| Personal | Age, city tier, marital status, dependents, occupation type (salaried / business / freelance) |
| Income | Primary salary, side income, rental, dividends, income stability, expected annual hike |
| Expenses | Fixed (rent, EMI, utilities, school fees), variable (food, travel, shopping), discretionary |
| Assets | Bank balances, FD/RD, mutual funds, stocks, gold, PPF/EPF/NPS, real estate, crypto |
| Liabilities | Home/car/personal/education loans, credit-card dues — outstanding, rate, EMI, tenure |
| Protection | Term life cover, health insurance, vehicle insurance, employer cover |
| Goals | Emergency fund, house, car, education, marriage, travel, retirement, custom — target ₹ + date |
| Risk Profile | 8–10 question risk questionnaire → Conservative / Moderate / Aggressive |
| Tax | Regime (old/new), 80C/80D utilisation |

**Output:** Financial Health Score (0–100), net worth, savings rate, debt-to-income ratio, emergency-fund months, insurance adequacy, gap analysis.

### 5.3 Monthly Planner (MVP — the heart of the app)
1. User opens **"New Month"** → selects month → enters **expected income** (and extra income such as bonus).
2. Optional: one-off expenses expected this month (festival, fees, travel) via the **calendar**.
3. **Plan Engine + AI** produce a plan splitting income into buckets:

| Bucket | Examples |
|---|---|
| Essentials | Rent, groceries, utilities, transport, EMIs |
| Lifestyle | Eating out, shopping, entertainment |
| Savings & Safety | Emergency fund top-up, sinking funds |
| Investments | SIP (equity/index/debt), gold, PPF/NPS, stocks (as per risk) |
| Debt Prepayment | High-interest loans / credit cards first |
| Protection | Insurance premiums due |
| Goals | Per-goal monthly contribution |
| Buffer / Misc | Irregular costs |

4. Each allocation shows **₹ amount, % of income, and "Why?"** explanation.
5. User may drag sliders to adjust; AI re-validates and warns on risky edits ("Emergency fund drops below 3 months").
6. User **approves** → plan is locked as the month's budget.

### 5.4 Monthly Calendar Page (MVP)
- Calendar heatmap: daily spend intensity.
- Markers for EMI dates, SIP dates, bill due dates, salary credit, planned one-off expenses.
- Tap a day → expenses of that day + quick add.
- Month summary header: Planned vs Spent vs Remaining; daily safe-to-spend figure.

### 5.5 Expense Tracking (MVP)
- Quick-add (amount, category, note, payment mode, date) in ≤ 3 taps.
- Categories with icons; custom categories; tags; split expenses.
- Recurring transactions (rent, subscriptions).
- Budget-vs-actual per category with progress rings.
- Search, filters, edit/delete, undo.
- **Assisted capture (v1.5):** UPI/bank SMS parsing (on-device), receipt OCR, voice entry ("spent 250 on lunch").

### 5.6 AI Advisor "Fin" (MVP)
- Chat interface for questions: *"Can I afford a ₹60k phone?"*, *"Should I prepay my loan or invest?"*
- Context-aware: always grounded in user's profile, plan and spend.
- Explains *why* for every recommendation, shows assumptions.
- Responds in English, Tamil, Hindi (v1.5).
- Guardrails: no guaranteed-return claims, no stock tips ("buy X now"), always shows disclaimers.

### 5.7 Plan Templates (MVP)
User or AI picks a base strategy; engine personalises it.

| Template | Split (starting point) | Best for |
|---|---|---|
| 50/30/20 Classic | Needs 50 / Wants 30 / Save-Invest 20 | Beginners |
| Aggressive Saver | 45 / 15 / 40 | High savers, FIRE |
| Debt Crusher | Needs 50 / Wants 10 / Debt 30 / Invest 10 | Heavy debt |
| Family Balanced | Needs 55 / Wants 15 / Goals 20 / Protection 10 | Families |
| Zero-Based Budget | Every rupee assigned | Control seekers |
| Freelancer Smoothing | Base-income budget + variable buffer + tax reserve | Irregular income |
| Retirement Booster | Needs 45 / Wants 15 / Retirement 30 / Buffer 10 | 40+ |
| Goal Sprint | Heavy allocation to one goal with deadline | Short-term goals |

*The AI auto-recommends the best template from the profile; users can switch any time.*

### 5.8 Goals Module (MVP)
- Create goals with target amount, date, priority.
- Inflation-adjusted target; required monthly contribution (SIP calculator).
- Progress rings, projected completion date, "on track / behind" status.

### 5.9 Insights, Reports & Analytics (MVP → v1.5)
- Monthly report card: savings rate, plan adherence %, category overruns.
- Trends (6/12 months), net-worth timeline, spending by category/merchant.
- Financial Health Score history.
- Export to PDF / CSV.

### 5.10 Notifications & Nudges (MVP)
- "Income not entered for this month yet"
- Bill / EMI / SIP reminders.
- Budget 80% / 100% crossed alerts; daily safe-to-spend.
- Weekly digest; month-end review prompt.

## 6. Additional Best-in-Class Features (Value-Adds)

| # | Feature | Description | Phase |
|---|---|---|---|
| 1 | **What-If Simulator** | Slide salary hike, new EMI, SIP change → see impact on goals & net worth | v1.5 |
| 2 | **Emergency Fund Builder** | Auto-targets 6× essential expenses, tracks months of cover | MVP |
| 3 | **Debt Payoff Planner** | Avalanche vs Snowball comparison, interest saved, debt-free date | v1.5 |
| 4 | **Net Worth Tracker** | Assets − liabilities, monthly snapshots | MVP |
| 5 | **Subscription Detector** | Finds recurring charges, flags unused ones | v1.5 |
| 6 | **Bill & Due-Date Calendar** | All dues on the calendar with reminders | MVP |
| 7 | **Tax Optimiser (estimates)** | 80C/80D/NPS room left, regime comparison | v2 |
| 8 | **Insurance Gap Analyser** | Term cover = 10–15× income check, health cover adequacy | MVP |
| 9 | **Retirement / FIRE Planner** | Corpus needed, Monte-Carlo success probability | v2 |
| 10 | **Financial Health Score** | Gamified 0–100 score with improvement tips | MVP |
| 11 | **Streaks & Badges** | Logging streaks, savings milestones | v1.5 |
| 12 | **Smart Savings Challenges** | No-spend weekends, round-up savings | v2 |
| 13 | **Family / Partner Mode** | Shared household budget, individual privacy | v2 |
| 14 | **Voice & Natural-language Entry** | "Add 450 groceries yesterday" | v1.5 |
| 15 | **Receipt Scanner (OCR)** | Auto-fill amount, merchant, date | v1.5 |
| 16 | **Bank Aggregation (Account Aggregator)** | Consent-based RBI AA framework for balances/transactions | v2 |
| 17 | **Home-screen Widget** | Safe-to-spend today, quick-add button | v1.5 |
| 18 | **Multi-language (EN/TA/HI)** | Regional language AI | v1.5 |
| 19 | **Offline mode** | Log expenses offline; sync later | MVP |
| 20 | **Data Export & Delete** | DPDP right-to-access and erasure | MVP |
| 21 | **Festival / Seasonal Planner** | Pre-allocates for Diwali, school fees, annual premiums | v1.5 |
| 22 | **Dark Mode (deep violet)** | Full dark theme | MVP |
| 23 | **Credit Score Tips** | Utilisation and repayment guidance (no bureau pull in v1) | v2 |
| 24 | **Anomaly Alerts** | Unusual spend spikes flagged | v1.5 |

## 7. How the AI Builds the Monthly Plan (Behavioural Spec)

**Principle: the LLM explains and personalises; deterministic code does the maths.**

1. **Gather context:** profile, latest snapshot, goals, past 3 months actuals, upcoming dues, this month's income.
2. **Hard constraints (rule engine):**
   - Pay all fixed obligations (EMIs, rent, insurance premiums due).
   - Emergency fund target = 6× essentials (3× if dual income; 9× if freelancer) — fill first until reached.
   - Clear credit-card / >12% interest debt before equity investing beyond SIP minimum.
   - Ensure protection gap (term/health) is addressed before aggressive investing.
   - Savings rate floor and wants cap from the chosen template.
3. **Optimisation (rule + scoring):** Distribute the remainder across goals by priority × urgency; map investment amount to asset classes by risk profile and horizon (e.g. Moderate: 60 equity / 30 debt / 10 gold; adjust by goal horizon).
4. **LLM layer:** Writes human explanations, trade-offs, alternatives, and handles chat.
5. **Validation layer:** Totals = income; no negative values; constraints satisfied; guardrail check on language ("guaranteed", "sure-shot", specific stock calls blocked).
6. **Plan versioning:** Every plan stored with inputs and rule-version for audit.

**Example (illustrative):** Income ₹60,000 · Moderate risk · Home loan EMI ₹14,000 · Emergency fund at 2.5 of 6 months

| Bucket | ₹ | % |
|---|---|---|
| Essentials (rent/food/utilities/transport) | 22,000 | 36.7% |
| Home-loan EMI | 14,000 | 23.3% |
| Emergency fund top-up | 6,000 | 10% |
| Investments (SIP index 3,000 · debt 1,500 · gold 500) | 5,000 | 8.3% |
| Insurance premium (monthly equivalent) | 2,000 | 3.3% |
| Goal: Car down payment | 3,000 | 5% |
| Lifestyle | 6,000 | 10% |
| Buffer | 2,000 | 3.3% |
| **Total** | **60,000** | **100%** |

## 8. Functional Requirements (Summary)

| ID | Requirement |
|---|---|
| FR-01 | User can register/login with OTP or Google |
| FR-02 | App collects full financial profile in guided onboarding |
| FR-03 | System computes health score and net worth |
| FR-04 | User can create a month page and enter income |
| FR-05 | AI generates an editable, explained allocation plan |
| FR-06 | User can approve, edit and version the plan |
| FR-07 | User can add/edit/delete expenses and recurring items |
| FR-08 | Calendar shows spend heatmap and events |
| FR-09 | Dashboard shows planned vs actual in real time |
| FR-10 | AI chat answers contextual finance questions |
| FR-11 | Goals can be created and tracked |
| FR-12 | Notifications for dues, budget breaches, reviews |
| FR-13 | Reports exportable as PDF/CSV |
| FR-14 | User can export or delete all data |

## 9. Non-Functional Requirements

| Area | Target |
|---|---|
| Performance | App cold start < 2 s; plan generation < 8 s; expense add < 300 ms (local-first) |
| Availability | 99.5% backend |
| Security | AES-256 at rest, TLS 1.3, field-level encryption for PII, certificate pinning, root detection |
| Privacy | DPDP Act 2023 compliance; data minimisation; PII redaction before LLM calls |
| Offline | Expense logging works offline, syncs on reconnect |
| Accessibility | WCAG AA contrast, TalkBack support, scalable fonts |
| Scalability | 100k MAU on initial infra; horizontal scale |
| Compatibility | Android 8.0+ (API 26) |

## 10. Technology Summary

| Layer | Choice |
|---|---|
| Android | Kotlin, Jetpack Compose, MVVM + Clean Architecture, Hilt, Room, Retrofit, WorkManager |
| Backend | Python FastAPI, PostgreSQL (+ pgvector), Redis, Celery |
| AI | Claude API (LLM), RAG over curated knowledge base, deterministic Plan Engine |
| Auth | Firebase Auth / custom JWT with OTP |
| Cloud | AWS / GCP (Mumbai region), Docker, CI/CD via GitHub Actions |
| Observability | Sentry, Prometheus + Grafana, structured logs |

(Details in documents 02 and 03.)

## 11. AI Knowledge Base (RAG Sources)
SEBI investor-education material, RBI guidelines, AMFI mutual fund basics, NISM study concepts, income-tax slabs & sections, insurance norms (IRDAI), curated personal-finance playbooks. Versioned and reviewed by a finance professional.

## 12. Success Metrics (KPIs)
- Onboarding completion ≥ 70%
- Monthly plan creation rate ≥ 60% of active users
- Expense-logging weekly active ≥ 50%
- Plan adherence ≥ 70%
- Day-30 retention ≥ 35%
- AI answer helpfulness (thumbs-up) ≥ 85%

## 13. Roadmap

| Phase | Duration | Scope |
|---|---|---|
| **0 – Discovery** | 2 wks | Research, compliance consult, finance rules sign-off, UI prototype |
| **1 – MVP** | 10–12 wks | Auth, onboarding, health score, monthly planner, calendar, expenses, goals, AI chat, notifications |
| **2 – v1.5** | 8 wks | SMS/receipt/voice capture, what-if, debt planner, widgets, languages, badges |
| **3 – v2** | 10 wks | Account Aggregator, tax optimiser, FIRE planner, family mode |
| **4 – Scale** | ongoing | Personalisation models, partnerships, iOS |

## 14. Compliance, Risk & Disclaimers

| Risk | Mitigation |
|---|---|
| **SEBI regulation** — paid personalised investment advice needs SEBI Investment Adviser (RIA) registration | Launch v1 as *educational planning & budgeting tool* with disclaimer; for advisory features, register as RIA or partner with a registered adviser; consult legal counsel |
| LLM hallucination | Deterministic engine for numbers; RAG grounding; output validator; human-reviewed KB |
| Data privacy | DPDP-compliant consent, encryption, deletion on request, no selling of data |
| Over-reliance | Clear "not a guarantee" messaging; show assumptions |
| Product recommendations conflicts | Recommend asset *classes*, not commission products; no affiliate bias in v1 |

**In-app disclaimer (draft):** *"PersonalFin provides educational financial planning based on the information you enter. It does not guarantee returns. Investments are subject to market risks. Consult a SEBI-registered investment adviser for personalised advice."*

## 15. Assumptions & Open Questions
1. Is the first release a **planning/education** tool or a **registered advisory** product? (affects compliance)
2. Which regions/languages at launch?
3. Free vs subscription (suggested: free core + "Pro" for what-if, family mode, reports).
4. Will bank/AA integration be in scope for v1?
