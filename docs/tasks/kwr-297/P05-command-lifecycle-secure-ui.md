# P05 — One command lifecycle, real deadlines and secure identity

Parent: [KWR-297](../KWR-297-s-tier-completion-packages.md).
Read [execution standard](execution-standard.md). OVR-05/12 and REC-07.
Lead: Terra High integration; Medium projection/clock/identity regressions.
Dependencies: P01 match/fact identity, P03 feasibility and P04 plan contract.

## What and why

A correct plan is unusable if the call changes on repaint, the countdown restarts,
an old GO cue survives cancellation, or a roster click binds a recycled unit.
Complete one authoritative command lifecycle and make every consumer obey it.

## Existing owners

`Runtime/Commander.lua` already has ActivePlay construction, terminal suppression,
replacement rules, `AttachReviewIdentity`, `AttestDelivery` and reset functions.
Extend those; do not invent a parallel command manager.

`State/CountdownState.lua`, `Core/CommandView.lua`,
`Intelligence/ExecutionCommandBuilder.lua`, `Runtime/CommandAudio.lua`,
`UI/CountdownFrame.lua`, `CombatRosterVisuals.lua`, `TeamfightCommandCard.lua`,
`LayoutCoordinator.lua`, `Features/CursorRing.lua` and secure CombatRoster owners
must share the projection. Include copied text and `Runtime/SentinelBridge.lua`.

## Implementation contract

1. Version command identity by match generation + command ID + material revision.
   Repaint alone does not issue or revise a call. A material goal/actor/target/
   deadline change does. Keep generated, presented and delivered timestamps
   separate; mode selection or clipboard activity cannot attest delivery.
2. Make active lifecycle transitions explicit: proposed/active/retired semantics
   with success, abort, cancellation, interruption and expiry reasons. Map onto
   current states; preserve existing terminal protections and history readers.
3. Countdown uses one authorized start and absolute session deadline. Display
   derives remaining time using the documented rounding rule. For synthetic
   start=100/deadline=105, the existing contract shows 5,4,1,0 at 100,101,104,105.
   Missing start/deadline shows no manufactured countdown. Repainting cannot
   create five seconds or restart an expired cue.
4. A required fact expiry, target loss, actor unavailability, objective transition
   or match end withdraws every incompatible text/audio/reticle/packet cue.
   Perform invalidation before costly replanning; P07 measures end-to-display.
   Noncritical score fluctuations follow stable commitment policy, not blind
   debounce. A genuine emergency has evidence and a recorded bypass reason.
5. Attach listeners to the same immutable command projection and revision. Any
   delayed audio/render callback validates generation/revision before emitting.
   A cancelled prior generation cannot play GO after a new call is published.
6. Secure identity belongs to the existing protected-frame layer. Out of combat,
   resolve canonical actor GUID/unit mapping before binding. In combat, do not
   change forbidden attributes; queue a latest-generation update and show stale/
   unavailable status without binding a different actor. Keep safe user-triggered
   actions only. Use permitted cancellation/visibility operations after review.
7. Pool visual holders safely. Unit/nameplate reuse, duplicate names, carrier
   changes and reload must detach stale visuals. Preserve CursorRing elapsed
   remainder logic; retry cadence cannot depend on frame count.

## Verification

Extend `tests/fixtures/explicit_countdown.lua` and existing smoke/combat fixtures.
Use a fake clock and queued callbacks to test issue/start/tick/expiry/cancel,
repaint, target loss, match end, reload and same-map rematch. Check all command
consumers against the same ID, revision and deadline at each step.

Assert generated-only, Diagnostic, Spectator, Commander-without-delivery and
explicit leader attestation stay distinct. Old delivery cannot migrate to a new
revision or be upgraded by switching context.

Simulate protected setters that throw during combat. Exercise leaver, GUID
enrichment, nameplate token recycling, identical short names and unit-token reuse.
After combat, apply the latest valid deferred update once, never a stale queue.
At 30/60/144 simulated FPS, retry counts over equal elapsed time differ by at
most one. Ten mocked lifecycle cycles leave bounded pools and no stale holders.

Required mutations: restart countdown on paint, omit revision check in audio,
allow terminal reissue on unchanged truth, bind a recycled unit by display name.
Each mutation must fail. Mock legality does not certify Blizzard permissions.

## Acceptance criteria

- [ ] Every consumer agrees on active command identity, timing and cancellation.
- [ ] Material emergency invalidation is prompt; ordinary repaint does not churn.
- [ ] Delivery semantics and KWR-280/KWR-296 regressions remain intact.
- [ ] No illegal secure mutation in mocks; no incorrect identity or pool growth.
- [ ] Actual combat/taint and secure-click proof remains explicitly FIELD.

## Rollback and handoff

Keep existing tested lifecycle contracts while migrating one consumer at a time;
do not ship mixed old/new identity semantics. A presentation feature may be
disabled; cancelled commands may never be revived as a fallback. Handoff includes
the transition table, full consumer map, fake-clock trace and protected-setter
test results. P06 uses the same IDs for decision episodes.

Offline status: IN_PROGRESS. The execution packet now carries command ID and
material revision, and delayed audio validates that exact current Store command
and packet before speaking; the fake-clock lifecycle fixture rejects a queued
superseded cue. This is one consumer migration, not closure of P05: the remaining
transition model, secure-binding matrix, all consumer audit and FIELD combat/taint
proof remain open.
