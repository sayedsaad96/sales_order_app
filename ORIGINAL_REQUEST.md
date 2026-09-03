# Original User Request

## 2026-09-03T10:33:04Z

<USER_REQUEST>
Conduct a comprehensive code review, static analysis audit, and architecture evaluation of the Flutter sales order application, identifying all bugs, stability issues, offline storage pitfalls, and UX/performance bottlenecks, and produce a prioritized improvement roadmap.

Working directory: d:\Sayed\Flutter\sales_order_app
Integrity mode: development

## Requirements

### R1. Static Analysis and Code Quality Audit
Perform a complete diagnostic of the Dart codebase to identify syntax issues, analyzer warnings, unhandled asynchronous exceptions, broken state lifecycles, and potential runtime crashes across all feature modules.

### R2. Offline Data and Storage Architecture Review
Evaluate the local storage architecture (Hive database, data caching, synchronization mechanisms), assessing box lifecycle management, serialization safety, offline-first reliability, data integrity, and error recovery.

### R3. UI/UX and Performance Assessment
Evaluate widget tree efficiency, unnecessary widget rebuilds, responsive layout handling across diverse screen dimensions, asset loading performance, and UI responsiveness.

### R4. Prioritized Actionable Improvement Roadmap
Deliver a structured audit report categorizing all identified issues by severity (Critical, Major, Minor, Improvement Suggestion) with exact file and line references, root cause explanations, and concrete recommendations for development and modern Flutter best practices.

## Acceptance Criteria

### Issue Precision & Verification
- [ ] Every documented bug or issue contains an exact file path and line number reference in the repository.
- [ ] Static analysis findings match or expand upon `flutter analyze` output with categorized severity.
- [ ] No speculative or untestable claims are included in the findings.

### Offline & Storage Completeness
- [ ] Every Hive box access pattern is inspected for proper initialization, exception handling, and resource disposal.
- [ ] Potential data loss, race conditions, or unhandled sync failure scenarios are explicitly highlighted with reproduction contexts.

### Performance & UI Rigor
- [ ] State management rebuild patterns (e.g. `Provider` usage) are evaluated for unnecessary subtree re-renders.
- [ ] Heavy compute operations or blocking I/O calls on the main UI isolate are flagged.

### Actionable Deliverable
- [ ] The final report provides clear, step-by-step remediation guidance for all Critical and Major issues.
- [ ] Modernization suggestions specify exact Flutter/Dart patterns or packages to adopt.

</USER_REQUEST>
