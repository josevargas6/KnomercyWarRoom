---
id: KWR-278
title: Close Alpha 11 live field blockers
owner: Codex
priority: critical
risk: high
status: completed
dependencies: [KWR-270, KWR-274, KWR-277]
affected_modules: [Runtime, Core, UI, tests, tools, docs]
authority_references: [AGENTS.md, QA_CHECKLIST.md, RELEASE_READINESS.md, BATTLEGROUND_VERIFICATION.md]
---

# Objective

Convert the complete Alpha 10 Seething Shore diagnostic match into release-ready
Alpha 11 fixes for lifecycle correctness, battlefield truth, command stability,
runtime cost, memory pressure, and combat presentation.

# User outcome

The next field candidate starts and retires plays coherently, gives actionable
Seething Shore calls, remains responsive under combat event load, enforces its
memory budget from one current sample, and never presents duplicate roster
identities or invented win-path certainty.

# Current behavior

The Alpha 10 victory recorded a 35.072 ms strategic P95, 50.295 ms maximum,
47,974 KB memory peak, 3 reversals, 4 pre-movement invalidations, and a 19-second
median command lifetime. A failed `Next Spawn` play remained terminal for most of
the match, the public HUD showed a known win path without authoritative score,
and secure Team rows visibly duplicated identities.

# Required behavior

1. Terminal ActivePlay state is recorded once, retired, and replaced by a fresh
   candidate; terminal match copy is internally consistent.
2. Seething Shore fissure and collection evidence drives bounded spawn-cycle
   truth and actionable calls without inventing ownership.
3. Equivalent HOLD/COVER decisions do not churn solely because presentation or
   settle refreshes select a different mover; genuine objective changes remain
   replaceable.
4. Tactical and strategic work avoids unchanged recomputation and exposes
   release-budget telemetry from representative deterministic fixtures.
5. Memory pressure and `/kwr perf` use the same fresh sample and engage the
   documented degradation threshold.
6. Team rows preserve unique identities across secure in-combat rebinding, and
   unknown score produces VERIFY/WAIT win-path copy.

# Non-goals

- No protected targeting, movement, casting, or automatic chat.
- No external publication, deployment, or stable promotion in this task.
- No inference of unavailable enemy plans, objective ownership, or score.
- No lowering of release budgets to make the field evidence pass.

# Technical constraints

- Preserve the single Store and MatchRuntime event owner.
- Preserve secure-frame combat-lockdown rules and current saved-variable schema.
- Optimize or skip work only when bounded signatures prove the relevant truth is
  unchanged.
- Keep field diagnostics explicit enough to distinguish observed truth from
  recommendation outcome.

# Acceptance criteria

- [x] Terminal plays retire once and match completion cannot say both expired and live.
- [x] Seething Shore collection/spawn-cycle evidence produces actionable bounded truth.
- [x] Deterministic command fixtures meet reversal, pre-movement, and lifetime budgets.
- [x] Strategic/tactical fixtures meet the documented P95 and routine maximum budgets.
- [x] Fresh memory samples drive both reporting and pressure/degradation state.
- [x] Team rendering cannot duplicate a canonical/GUID/unit identity during secure rebinding.
- [x] Unknown score displays VERIFY/WAIT rather than a calculated win path.
- [x] Validation, knowledge, Lua, automation, security, reproducibility, and extracted-package audits pass.

# Verification

1. Run source validation and the knowledge audit.
2. Run deterministic Lua smoke, transport, soak, and replay suites.
3. Run automation and security audits without installing dependencies.
4. Build Alpha 11 twice, prove reproducibility, and audit extracted Commander and Sentinel packages.
5. Require a later full Retail match before stable promotion.

# Rollback

Revert the bounded Alpha 11 source commit or reinstall the immutable Alpha 10
release. No persisted schema migration is introduced.
