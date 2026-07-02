# KWR Knowledge Update Workflow

Runtime strategy code is patch-independent. Patch, meta, capability, composition,
plan, counter, and community-signal changes enter through reviewed data files.

## Authority order

1. Blizzard live non-secret facts.
2. Safely observed combat events.
3. Derived calculations from live facts.
4. Reviewed patch and capability data.
5. Expiring aggregate meta.
6. Reviewed local learning.
7. Community signals.

A lower tier never overwrites a higher tier.

## Patch update

1. Copy `patch-template.json` and fill in the new patch metadata.
2. Review Blizzard API and class changes.
3. Separate API availability changes from gameplay tuning changes.
4. Add cooldown and capability overlays to `Data/PatchData.lua`.
5. Confirm every capability category still has at least three semantic signals,
   three battlefield effects, and at least one objective-plan profile.
6. Review each counter's three-step conversion sequence, success condition,
   switch condition, and stop rule.
7. Disable plans invalidated by map or class changes.
8. Refresh `Data/MetaSnapshot.lua` and its capture date.
9. Review monitor-only community signals for corroboration.
10. Run `tools/knowledge-audit.ps1`, validation, syntax, and smoke tests.
11. Field-test before marking the pack reviewed.

## Deliberate call contract

Every selected play should answer:

1. What scoring objective are we taking, holding, returning, escorting, or denying?
2. Which capability profile makes the play feasible?
3. What observable state means the play succeeded?
4. What observable reinforcement, cooldown, route, or clock change aborts it?
5. Which defender or carrier coverage must remain intact during the play?

Visible and last-seen player locations retain their observation source. A legal
unit observation without legal map coordinates remains useful evidence, but it
must never become a fabricated map dot.

## Community intake

Reddit, Twitch, forums, and comments generate hypotheses:

```text
signal -> reproduce -> corroborate -> expert review -> fixture -> shipped rule
```

Complaint volume is not evidence of balance, an exploit, or a winning strategy.
Never ship a tactic solely because it is popular or controversial.

## Historical doctrine

Historical sources are valuable for durable principles such as resurrection
advantage, defender spacing, regrouping, target coordination, and objective
priority. Patch-sensitive mechanics remain `HISTORICAL_REVALIDATE` until tested.

## Privacy

Shared match research must remove character and account identifiers. Only
composition features, state transitions, plan decisions, outcomes, and reviewed
labels belong in the learning corpus.
