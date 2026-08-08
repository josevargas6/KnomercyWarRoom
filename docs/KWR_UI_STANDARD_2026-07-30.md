# KWR UI Standard

Date: 2026-07-30  
Authority: developer-facing implementation standard

## Scope

This standard governs KWR addon windows, cards, buttons, badges, tooltips, and
shared shell behavior. It applies to new surfaces first and to existing surfaces
when they are materially touched.

## Shared Token Rule

All new KWR surfaces must source visual values from `UI/Theme.lua`.

Minimum locked tokens:

- `KWR_COLOR_BG`
- `KWR_COLOR_SHELL`
- `KWR_COLOR_SURFACE`
- `KWR_COLOR_SURFACE_RAISED`
- `KWR_COLOR_BORDER`
- `KWR_COLOR_TEXT`
- `KWR_COLOR_TEXT_MUTED`
- `KWR_COLOR_PRIMARY`
- `KWR_COLOR_WARNING`
- `KWR_COLOR_DANGER`
- `KWR_FONT_HEADER`
- `KWR_FONT_BODY`
- `KWR_RADIUS_SM`
- `KWR_RADIUS_MD`
- `KWR_SPACING_4`
- `KWR_SPACING_8`
- `KWR_SPACING_12`
- `KWR_SHADOW_SOFT`
- `KWR_ICON_SIZE_SM`
- `KWR_ICON_SIZE_MD`

Raw per-surface colors, spacing values, and ad hoc font roles are not allowed
without a documented exception.

## Window Shell

Every KWR window should share:

- the same border treatment;
- the same title-bar pattern;
- the same padding grid;
- the same move and close behavior;
- the same selected, hover, and disabled-state logic.

Default shell direction:

- shell background: `KWR_COLOR_SHELL`;
- panel background: `KWR_COLOR_SURFACE`;
- border: `KWR_COLOR_BORDER`;
- active edge emphasis: `KWR_COLOR_PRIMARY`;
- standard inset: `KWR_SPACING_12`;
- standard section gap: `KWR_SPACING_8` or `KWR_SPACING_12`.

## Card System

Use the shared card families from the brand standard. Each card must answer one
question first and avoid secondary clutter.

Card rules:

- stable height in normal state;
- bounded overflow contract;
- one dominant action or value;
- a single semantic accent, not a rainbow;
- empty, disabled, and not-live states are explicit.

## Buttons

KWR supports only three primary button classes for ordinary actions:

- Primary
- Secondary
- Danger

Button rules:

- selected, hover, and disabled states must all be distinct;
- labels should stay one line;
- height should remain at least 24 on compact surfaces and 26 on planning surfaces;
- danger styling is reserved for destructive or high-risk actions.

## Badges and Alerts

Badges communicate status, not prose.

Rules:

- one to three words maximum;
- no more than four concurrent top-rail badges in a standard window;
- every semantic badge must also carry readable text;
- threat red is reserved for actual urgency or failure;
- preview, unknown, and inferred states must be labeled explicitly.

## Tooltips and Dense Text

Tooltips and supporting text should stay quiet and secondary:

- muted text for metadata;
- primary text for the actual action or value;
- no long saturated-color paragraphs;
- no editable-looking display text unless the user is expected to copy or edit it.

## Asset Behavior

Icons, logos, and role markers must match KWR’s tactical weight:

- no novelty icon family;
- no decorative faction-color overuse;
- small-size legibility is mandatory;
- one-color fallbacks should remain recognizable.

## Rollout

Apply the standard in this order:

1. token foundation in `UI/Theme.lua`;
2. shared shell and component cleanup;
3. per-surface migration when windows are next touched;
4. visual verification against actual battleground scenes.

## Non-Negotiable Rule

No KWR interface element should be introduced without mapping to the shared brand
tokens, typography rules, and component library.
