# KWR Visual Direction Package

Date: 2026-07-14  
Evidence state: out-of-combat baseline complete; live-combat baseline pending  
Reference environment: 2560x1440, WoW UI scale 65%, KWR 6.1.0-alpha.25

## Purpose

This package is the implementation authority for the final KWR visualization,
readability, brand, and visual-verification pass. It converts the supplied town,
formation, launcher, options, target-assist, and Command Center screenshots into
one development specification.

The package does not authorize a visual rewrite. It preserves KWR's command-center
identity and defines a staged migration through the existing `UI/Theme.lua`,
`UI/MainWindowShell.lua`, and current surface modules.

## Current Decision

`HOLD FOR COMBAT EVIDENCE`

The out-of-combat assessment is complete. Do not finalize combat-facing density,
opacity, scale, urgency, target-assist, ReporterMap, CombatRoster, or compact-HUD
behavior until the matching live-combat screenshots are added. Foundation work may
be estimated from this package, but implementation should begin only when the owner
releases the hold.

## Documents

1. `OUT_OF_COMBAT_VISUAL_ASSESSMENT.md`
   - evidence inventory;
   - visual scorecard;
   - brand and marketing assessment;
   - surface-by-surface findings;
   - current release risks.

2. `VISUAL_SYSTEM_SPEC.md`
   - target brand direction;
   - typography, spacing, color, opacity, and component tokens;
   - responsive layout and overflow contracts;
   - exact surface rules;
   - performance and future-proofing constraints.

3. `IMPLEMENTATION_BACKLOG.md`
   - ordered work packages;
   - affected modules;
   - dependencies and effort;
   - exact acceptance criteria;
   - rollback boundaries.

4. `VISUAL_VALIDATION_PROTOCOL.md`
   - screenshot matrix;
   - readability and interaction gates;
   - state, scale, resolution, and combat checks;
   - evidence naming and pass/fail rules.

## Authority Order

If guidance conflicts, use this order:

1. safety and battleground visibility policy;
2. live truth and command correctness;
3. this visual-system specification;
4. surface-specific implementation backlog;
5. legacy visual behavior.

The prior `LIVE_VISUAL_SCRUB_WORKSHEET_2026-07-12.md` remains the tester worksheet.
This package supplies the professional design direction and implementation contract
that the worksheet did not define.

## Non-Negotiable Outcome

KWR must look like a premium battlefield command instrument, not a spreadsheet,
debug console, or collection of unrelated PvP widgets. The final UI must:

- expose one clear decision per glance;
- preserve real battleground terminology;
- reserve color for meaning rather than decoration;
- remain readable over bright and dark game scenes;
- separate setup, live command, and technical verification modes;
- remain stable at every supported scale without per-surface patch geometry;
- add no material frame-time cost, ticker, polling loop, or layout churn.

