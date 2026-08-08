# ADR: Unified roster presentation boundary

## Status

Accepted for the KWR-047 implementation.

## Context

KWR publishes one authoritative live Store state, but Team and Enemy
presentation evolved through separate compact panes, an independent toolbar,
an additional spotlight card, expanded tables, and UI-owned truth cleanup.
The behavior is valuable, but the surface reads as several products and wakes
more presentation code than an unchanged state requires.

CombatRoster rows are protected secure buttons. Their attributes, hierarchy,
anchors, and visibility cannot be treated like ordinary dynamic list rows
during combat. Any cleaner presentation must preserve a pre-created bounded
secure pool and keep volatile visual emphasis separate from secure identity.

## Decision

KWR will use one roster presentation boundary with these rules:

- TeamResolver owns friendly published-identity normalization.
- EnemyIntel owns exclusion of friendly identities and duplicate enemy truth.
- Store remains the only published live-state authority.
- CombatRoster owns one unified secure frame and one saved root anchor.
- RosterPresentation owns the shared friendly spec provenance and enemy action
  projection used by compact and expanded rows.
- Secure row slots remain stable during combat and for the battlefield session.
- Visual priority is expressed through row content and accents rather than
  volatile row movement.
- MainWindow Team and Enemy pages reuse the same semantic row projection but
  keep ordinary non-secure expanded rows.
- Expanded pages and secondary editors are constructed on demand.
- Renderers compare bounded semantic signatures before mutating frames.
- Opening a surface never forces the decision pipeline to recompute.

## Consequences

- Legacy pane, toolbar, and solo positions require a backward-compatible
  migration to the unified root anchor.
- Independent Team and Enemy dragging is removed.
- Compact BOTH mode becomes visually and operationally one KWR surface.
- Secure row creation remains eager at the first legal battleground
  preparation point; ordinary expanded pages become lazy.
- Runtime identity/truth behavior becomes independently testable without
  constructing UI.
- UI diagnostics can distinguish Store delivery from actual row mutation.
- Live testing must prove target/focus clicks, combat lockdown, taint safety,
  roster hydration, and upgrade positioning before release.
