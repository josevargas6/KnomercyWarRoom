---
id: KWR-282
title: Reject malformed sync input and restore cast and marker sampling
owner: Codex
priority: critical
risk: medium
status: completed
dependencies: [KWR-281]
affected_modules: [CommanderComm, KWRSentinel, CursorRing, tests]
authority_references: [AGENTS.md, PRODUCT_ROADMAP.md, RELEASE_READINESS.md]
---

# Objective

Fix the reproduced parser, cast tuple and frame-rate defects from OVR-08/12.
This bounded change can proceed while OVR-01 source reconciliation remains open.

# User outcome

Malformed sync messages cannot interrupt the addon. Public target casts carry
the real spell ID, and marker retries follow elapsed time at normal frame rates.

# Current behavior

An eight-field Commander envelope with an unknown key replacing `seq` throws
before sender validation. Both parsers permit malformed percent escapes and
empty separators. Sentinel reads casting return eight (interruptibility) as the
spell ID. CursorRing discards throttled frame time before updating retry timers.

# Required behavior

- Validate the complete eight-field envelope, numeric bounds and percent escapes
  before using decoded values. Reject unknown/duplicate keys, empty segments,
  control characters and invalid UTF-8, including encoded forms.
  Keep sender, session, epoch and transport opt-in checks.
- Read casting spell ID at return nine and channel spell ID at return eight.
  Missing, throwing or secret cast APIs produce no cast observation; later public
  observations can recover. Keep API handling inside the existing Observer.
- Pass accumulated frame time to pulse/retry timers, retain fractional retry
  time, and do at most one refresh per marker family per processed frame.

# Non-goals

No new transport families, combat automation, default transport enablement,
full Sentinel certification or tactical feature expansion.

# Technical constraints

Keep KWRSync1 version 2 and the 240-byte envelope. Commander and standalone
Sentinel retain independent packaging; test identical parser vectors at both
ends. Reject sequence/timestamp integers beyond exact Lua numeric precision.
Never inspect a protected cast value before its secret check.

API reference reviewed September 5, 2026: Blizzard's generated
[Unit documentation](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
(published UI-source mirror). Client-build-specific restrictions still need
physical-client verification.

# Acceptance criteria

- [x] Both decoders reject malformed/missing/duplicate fields without throwing.
- [x] Valid round trips and existing handshake/relay regressions still pass.
- [x] Cast/channel, nil, exception, secret and later recovery cases pass.
- [x] Ten-second 30/60/144 FPS marker runs differ by at most one refresh per family.
- [x] Stalls do not cause catch-up loops; invalid elapsed values do not poison timers.
- [x] Source validation and appropriate Lua tests pass, with evidence recorded.
- [x] Verify this change in the next extracted package before task closure.

# Verification

Add deterministic regressions to existing smoke and Sentinel suites, which also
run against extracted packages. Preserve original audit probes as failure
evidence. Mock timing validates scheduling only, not real CPU/FPS performance.
Actual PvP cast visibility, combat marker movement and multi-client transport
remain OVR-07/08/12/21 field gates.

September 5 source results: `tools/test-lua.ps1 -Suite All`, `tools/validate.ps1`
and `git diff --check` passed. The shared parser fixture exercises over 300
rejections per implementation, numeric boundaries, controls and invalid/valid
UTF-8. The actual Observer is tested for public casts/channels, missing/throwing
APIs, protected values and recovery. Marker probes require 49–50 reticle retries
and 39–40 orb retries over ten seconds at each frame rate. The source hash receipt
is `artifacts/runtime-boundaries-20260905/source-checks.json`. The default replay
passed via its allowed fallback; this is not the complete OVR-20 benchmark.

Package closure: `artifacts/audited-regressions-20260905-02/` passed extracted
player/developer smoke and soak, Sentinel transport, DevTools lifecycle and four
ZIP checksums. The package-audit JSON records PASS; source manifest/provenance
bind its content. Clean reproducibility was skipped for this dirty interim build.
This closes the bounded regression task, not OVR-08/12 field or release gates.

# Rollback

Revert this bounded parser/Observer/cadence change with its tests. Keep KWR-281
plain marker holders, source recovery and all pre-existing field fixes intact.
