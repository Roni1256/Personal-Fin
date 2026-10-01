# PersonalFin — Project Documentation Pack

AI-powered personal finance planner for Android. The AI advisor (**"Fin"**) learns a user's complete financial picture once, then builds a personalised monthly plan (spend / invest / save / protect) every time the user enters their income, and tracks actual spending against it.

| # | Document | Purpose |
|---|----------|---------|
| 1 | `01_Application_Definition_Document.md` | Vision, personas, features, AI behaviour, templates, roadmap, compliance |
| 2 | `02_Design_Document.md` | System architecture + frontend/UI design (purple & white theme) |
| 3 | `03_Backend_Architecture.md` | Services, API design, AI/plan engine, security, infra |
| 4 | `04_ER_Diagram.md` | Database schema with Mermaid ER diagram + table dictionary |
| 5 | `05_Data_Flow_Diagrams.md` | DFD Level 0, 1 and key sequence flows |

> Diagrams are written in **Mermaid**. They render natively on GitHub, GitLab, Notion, Obsidian, VS Code (Markdown Preview Mermaid Support) and https://mermaid.live.

## Important regulatory note
In India, giving *personalised investment advice for a fee* requires registration with SEBI as an Investment Adviser (RIA). An app/AI cannot itself be "SEBI certified". The docs therefore design the AI as **SEBI/RBI-guideline-aware and NISM-curriculum-informed**, with a compliance path (see Section 14 of the Application Definition Document). Please confirm the final structure with a qualified lawyer / SEBI-registered advisor before launch.
