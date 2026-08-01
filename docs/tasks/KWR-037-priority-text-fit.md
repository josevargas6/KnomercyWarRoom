---
id: KWR-037
title: Prevent setup strategy text from being squeezed or clipped
owner: unassigned
priority: medium
risk: low
dependencies: []
affected_modules:
  - UI/MainWindow.lua
  - UI/MainWindowPages.lua
---

# Objective

Make the Tactical Map setup board show complete strategic information when both recruitment and composition-job lists are populated.

# User outcome

Important setup instructions are readable in full; low-value fragments are not presented as if they were complete guidance.

# Current behavior

The two strategy columns leave the right-side jobs column narrow, causing longer job text to wrap or appear visually clipped.

# Required behavior

Rebalance the two columns and preserve wrapped text so both recruitment priorities and composition jobs have usable reading width.

# Non-goals

Do not change strategy content, ordering, or roster recommendations.

# Technical constraints

Keep the existing card and page geometry stable; make only the internal column allocation change.

# Acceptance criteria

- [ ] Composition-job text receives materially more horizontal space.
- [ ] Recruitment priorities remain readable and continue to wrap.
- [ ] No strategy text is truncated by the column change.

# Verification

1. Run `tools/validate.ps1`.
2. Run `tools/test-lua.ps1`.
3. Inspect setup with a partial roster and all available composition jobs.

# Rollback

Restore the formation column width and left offset values.
