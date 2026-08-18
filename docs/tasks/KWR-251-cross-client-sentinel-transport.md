---
id: KWR-251
title: Enable bounded cross-client Sentinel transport
owner: unassigned
priority: critical
risk: high
status: in_progress
authority_references: [PROTOCOL.md, SENTINEL_TRANSPORT_SPEC.md, SECURITY.md, RELEASE_READINESS.md]
dependencies: [KWR-250]
affected_modules:
  - Runtime/CommanderComm.lua
  - Runtime/SentinelIngress.lua
  - Runtime/SentinelMerge.lua
  - Runtime/SentinelRelay.lua
  - KWRSentinel/Comm.lua
  - KWRSentinel/Observer.lua
  - KWRSentinel/Relay.lua
  - tests/smoke.lua
---

# Objective

Implement the reviewed `KWRSync1` addon-message protocol so Sentinel clients on
other computers can send bounded observations to Commander and receive
player-specific execution relays.

# User outcome

Team members running Sentinel receive their own Commander assignment, control,
and action updates while their legal local observations can improve Commander
truth without creating another strategist or unsafe gameplay automation.

# Required behavior

- Use only `KWRSync1` over `INSTANCE_CHAT`, `RAID`, or explicit test `PARTY`.
- Validate protocol version, session, roster sender, sequence, limits, and
  packet shape before ingress.
- Keep Commander as the only Store, strategist, assignment, and command owner.
- Expire remote evidence and relay state to unknown rather than retaining it.
- Prohibit visible-chat fallback and all protected actions from comm paths.

# Non-goals

- No Sentinel-to-Sentinel mesh.
- No automatic targeting, focus, casting, movement, macros, or chat output.
- No stable promotion without live ten-client Retail evidence.

# Acceptance criteria

- [x] Commander and Sentinel register only the reviewed `KWRSync1` prefix.
- [x] Every message family is bounded, encoded, parsed, session-bound, and rate-limited.
- [x] Commander rejects malformed, foreign, stale, duplicate, and out-of-order packets.
- [x] Sentinel receives assigned relay state and safely expires it.
- [x] Remote observations merge below stronger local/widget truth.
- [x] Deterministic protocol, malformed-input, dedupe, expiry, and ten-sender soak tests pass.
- [x] Validator confines communication APIs to reviewed transport owners.
- [x] A clean Commander/Sentinel install keeps relay transport disabled until
  the player explicitly enables Field mode; existing player choices are
  preserved.
- [ ] Retail multi-client, taint, and product-value sessions pass.

# Verification

1. Run validation, deterministic Lua tests, and the ten-sender transport soak.
2. Build and extracted-runtime audit both packages.
3. Test a complete 10-player Retail battleground: handshake, gate, objective,
   casts, carrier updates, relay expiry, match-end teardown, and taint scan.

# Rollback

Disable the `transport.enabled` profile flag and revert the KWR-251 transport
modules. Commander and standalone Sentinel remain functional without traffic.
