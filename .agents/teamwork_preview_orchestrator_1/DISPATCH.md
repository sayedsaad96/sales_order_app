## 2026-09-03T10:33:50Z

You are the Project Orchestrator for the Flutter Sales Order Application review and audit task.

Your working directory is:
d:\Sayed\Flutter\sales_order_app\.agents\teamwork_preview_orchestrator_1

The authoritative user request is recorded at:
d:\Sayed\Flutter\sales_order_app\.agents\ORIGINAL_REQUEST.md

Project Workspace:
d:\Sayed\Flutter\sales_order_app

Mission Overview:
Conduct a comprehensive code review, static analysis audit, and architecture evaluation of the Flutter sales order application, identifying all bugs, stability issues, offline storage pitfalls, and UX/performance bottlenecks, and produce a prioritized improvement roadmap.

Key Requirements to Address:
1. R1: Static Analysis and Code Quality Audit (Dart codebase diagnostic, syntax issues, analyzer warnings, unhandled asynchronous exceptions, broken state lifecycles, potential runtime crashes).
2. R2: Offline Data and Storage Architecture Review (Hive database, caching, sync mechanisms, box lifecycle management, serialization safety, offline-first reliability, data integrity, error recovery).
3. R3: UI/UX and Performance Assessment (Widget tree efficiency, unnecessary rebuilds, Provider usage, responsive layout across diverse screen dimensions, asset loading performance, blocking I/O or heavy compute on main isolate).
4. R4: Prioritized Actionable Improvement Roadmap (Categorized by severity: Critical, Major, Minor, Improvement Suggestion with exact file and line references, root cause explanations, and concrete recommendations for development and modern Flutter best practices).

Acceptance Criteria:
- Issue Precision & Verification: Every documented bug/issue must contain an exact file path and line number reference in the repository. Findings must match or expand upon analyzer output with categorized severity. No speculative or untestable claims.
- Offline & Storage Completeness: Every Hive box access pattern inspected for proper initialization, exception handling, resource disposal. Data loss, race conditions, sync failures highlighted with reproduction contexts.
- Performance & UI Rigor: State management rebuild patterns evaluated for unnecessary subtree re-renders; heavy compute or blocking calls flagged.
- Actionable Deliverable: Step-by-step remediation guidance for all Critical and Major issues. Modernization suggestions specify exact Flutter/Dart patterns or packages to adopt.

Maintain your `plan.md`, `progress.md`, and `BRIEFING.md` in your working directory. Keep `progress.md` updated with timestamps and active status.
When finished, notify Sentinel with the complete results and deliverable path.
