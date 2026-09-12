# P10 — Optional, bounded, authority-safe Sentinel protocol

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-08.
Lead: Terra High protocol; Medium negative/flood/compatibility fixtures.
Dependencies: P01 session/identity/capability contract; P05 command revisions for
command messages. Local Commander must remain useful without remote promotion.

## What and why

Complete authority, freshness, bounded work and teardown on both sides of the
actual codecs. Preserve R02 malformed-envelope and R03 transport-OFF fixes.
Successful communication with a local stub is not proof of a ten-client session.

## Existing owners

`Runtime/CommanderComm.lua`, `Runtime/SentinelBridge.lua`, `KWRSentinel/Comm.lua`,
Observer, Relay, Core, HUD and Options; `tests/sentinel-transport.lua` exercises
the actual implementations. Extend these instead of adding a second protocol.

## In-progress implementation evidence (2026-09-11)

Ingress sender expiry now removes the sender from every retained index,
including sequence/dedup state and remote enemy/objective observations. This
prevents expired invented names from accumulating in the ledger after their
visible sender records have been evicted. The bounded-ingress fixture floods
thirty identities, verifies deterministic twenty-sender eviction, advances the
local receipt clock and verifies every ingress cache is empty. Both smoke and
the real Sentinel transport suite pass. This does not replace required
multi-client field proof or close the full protocol matrix.

On 2026-09-12 the real transport suite passed again with 10 accepted leader
handoffs and 14 rejected malformed/unauthorized/stale cases; the repository
security audit also passed. This is current CODE evidence only, not physical
ten-client or authority-policy FIELD proof.

## Correct implementation

1. Document the existing wire version, message types, byte budgets, required/
   optional fields, enum/range limits, escaping and compatibility policy. Preserve
   deployed compatibility or explicitly version breaking changes. Use current
   reviewed client transport limits, not a guessed universal byte ceiling.
2. Reject oversized/unknown/malformed messages before expensive decoding. Validate
   duplicates, illegal enums, non-finite numbers, sparse fields, encoded delimiters,
   strings and final encoded byte size. Count UTF-8 bytes, not displayed glyphs.
3. Authorize using actual platform-supplied sender/channel/group context and the
   current leader/allowed authority policy, never a sender field inside payload.
   Normalize canonical realm identity without collapsing ambiguous short names.
   Treat teammate messages as untrusted claims even after sender validation.
4. Namespace accepted data with current match and sender generation, sequence
   and expiry. Define join/reload, leader handoff, sequence reset and incompatible
   version behavior. Old buffered messages cannot regain authority after a new
   generation. Do not use raw remote uptime as the local expiration clock.
5. Bound ingress by bytes, messages, work and retained sender/cache state, with
   per-sender and global budgets. Bound unknown-sender buckets too; an attacker
   must not create unbounded entries with invented names. Distinguish intentional
   drops/throttling from parse failures in bounded diagnostic counters.
6. Preserve final outbound transport-OFF enforcement after serialization/queueing.
   Explicit off, leave, reload, authority change and match end cancel pending work
   and clear old relay authority. Default is off; deliberate field-mode opt-in
   must be explained to the user. Inbound policy must not silently turn it on.
7. HUD combines public local/remote sources with explicit provenance and expiry,
   not remote certainty. Unknown scores stay UNKNOWN and observed 0-0 stays valid.
   Conflict/stale/unsupported remote data cannot authorize a local hard commit.
8. Do not claim cryptographic authentication where the channel offers only sender
   identity. No injected executable Lua, arbitrary eval, hidden-data extraction
   or automatic gameplay/party chat execution from received messages.

## Verification

Extend both real codecs in `tests/sentinel-transport.lua`. Include malformed,
duplicate, unknown, oversized, multibyte, escaped, non-finite, reordered, expired,
wrong-session, stale leader, reload and sequence-boundary packets. Test a leader
handoff with delayed old messages and a sender that falsely names another actor.

Run deterministic floods across valid and invented sender identities; assert
bounded work/caches/counters, preserved useful fresh state where allowed, and
no exception. Test final send racing OFF, queued relays after leave, default-off,
explicit opt-in and companion absent. Capture rejected reasons, not payload PII.

Mutation examples: trust payload sender, skip final OFF gate, accept duplicate
sequence after reset, compare remote uptime to local now, retain unlimited sender
tables. Each must fail a focused assertion. P11 repeats extracted transport tests.

## Acceptance criteria

- [ ] Schema, authority and clock/reset policy are explicit and regression-tested.
- [ ] Both codecs reject invalid inputs without unbounded work or state.
- [ ] OFF/teardown cancels all outbound work; local-only experience stays usable.
- [ ] Unknown/conflict/freshness semantics agree with P01 and score regressions.
- [ ] Ten physical-client proof remains separate before remote capability promotion.

## Rollback and handoff

Use visible local-only degradation on incompatible protocol or transport failure.
Preserve the prior tested wire version where compatible; never downgrade by
relaxing authentication or decoder checks. Handoff wire schema, threat cases,
compatibility matrix, flood bounds and remote FIELD checklist.
