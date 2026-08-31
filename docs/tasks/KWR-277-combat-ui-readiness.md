---
id: KWR-277
title: Combat UI readiness and progressive-disclosure pass
owner: Codex
priority: critical
risk: high
status: in_progress
dependencies: [KWR-270, KWR-272, KWR-273]
affected_modules: [Core/Addon.lua, UI/HUD.lua, UI/LayoutCoordinator.lua, UI/CombatRoster.lua, UI/CombatRosterState.lua, UI/Options.lua, UI/AARWindow.lua, tests/smoke.lua, tools]
authority_references: [AGENTS.md, DESIGN_CONTRACT.md, RELEASE_POLICY.md, RELEASE_READINESS.md, BATTLEGROUND_VERIFICATION.md]
---

# Objective

Make the combat presentation compact, truthful, phase-aware, and readable while
preserving the single Store, runtime, decision-engine, and combat-safe layout
boundaries.

# Required behavior

- Combat Focus is the default active-combat preset: score/projection, one trust
  cue, named timer, NOW, MY JOB, NEXT trigger, and only a directly actionable
  local exception remain visible.
- Commander and Review/Observer remain explicit presets; manual positioning is
  retained and older anchors migrate without overwriting intentional layouts.
- Missing score data is displayed as unknown; live, aging, verify, and preview
  truth states are distinct in text and color.
- Timers select the deterministic earliest relevant objective timer and carry a
  semantic name and source rather than an ambiguous sync label.
- Automatic layout includes both roster surfaces, respects combat lockdown, and
  supplies collision-free managed defaults for 1280x720, 1366x768, 1920x1080,
  and 2560x1440.

# Non-goals

No doctrine, capability-weight, map-strategy, targeting, protected-action,
Sentinel transport, bot, publication, tag, or Retail-certification change.

# Verification

Run source validation, deterministic Lua/safety/automation checks, clean build
with Sentinel, reproducibility and extracted-package audits, guarded deployment
with rollback, and installed-tree manifest comparison. Retail proof remains
unbound until the field checklist in this task is completed.

# Rollback

Restore the guarded deployment snapshot produced for this candidate, or revert
the grouped source commits. Existing saved anchors are retained unless the user
explicitly chooses a preset or reset.
