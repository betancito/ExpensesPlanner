---
status: ready-for-mvp-planning
active_feature: none
updated: 2026-11-21
---

# Current handoff

## Where we are

[[features/BP-002-xcode-project|BP-002]] is complete and planner-accepted. The native SwiftUI project builds on the iPhone 17 iOS 26.5 simulator; both unit and UI smoke tests pass, and independent review found no issues.

## Active feature

None. The Xcode project contains only the provisional launch screen and test foundation.

## Next action

Continue [[backlog|BP-001]] by asking the user about the finance problem, required workflow, currency, privacy, and backup behavior before implementing BP-003.

## Environment confirmed

- Repository branch: `main`; GitHub remote: `origin`.
- Xcode 27.2 (27B52) and the iPhone 17 iOS 26.5 simulator successfully built and tested the app.
- Physical iPhone signing, deployment, and device testing have not been verified and are out of BP-002 scope.

## Open product questions

- Which finance problem should the first version solve?
- What information must be entered, calculated, and shown?
- Which currency, date, privacy, and backup behavior is required?
