# KWR Visual System Specification

Status: implementation specification; execution on hold pending combat evidence

## Design Principle

KWR is a battlefield command instrument. Every surface must present information in
this order:

1. what is happening;
2. what the player or team should do;
3. who owns the job;
4. when the action happens;
5. why, only when requested or when learning mode is active.

Visual decoration may reinforce that sequence. It may not compete with it.

## Brand Direction

Working visual name: `Midnight Command Table`.

Preserve:

- KWR Command Center naming;
- dark tactical surfaces;
- warm gold brand accent;
- WoW-compatible visual language;
- current restrained, professional tone.

Change:

- replace flat black with layered obsidian/midnight navy;
- reserve gold for selection and command priority;
- replace most gold panel boxes with quiet slate structure;
- create one consistent command-line/compass-notch motif in major headers;
- use state color as a small indicator, badge edge, icon, or key phrase rather than
  large blocks of colored body text.

## Token Contract

Implement tokens in `UI/Theme.lua`. Surface modules may consume tokens but must not
invent new raw colors, spacing scales, or text roles without a documented exception.

### Spacing

| Token | Value | Use |
| --- | ---: | --- |
| `space1` | 4 | Icon/text micro-gap only. |
| `space2` | 8 | Control internal padding. |
| `space3` | 12 | Card content inset and standard gap. |
| `space4` | 16 | Section separation. |
| `space5` | 24 | Major panel separation. |
| `space6` | 32 | Empty-state and page breathing room. |

Rules:

- outer shell inset: 16-18;
- panel inset: 12;
- card heading-to-content: 12;
- row gap: 4-8;
- no arbitrary 5, 7, 9, 13, or 17 padding values outside geometry that must match a
  Blizzard-owned frame.

### Typography

Use stable WoW-provided font resources. Do not add an external font dependency.
Separate roles by size, weight/outline, case, and color.

| Role | Base size | Line height | Color | Rules |
| --- | ---: | ---: | --- | --- |
| Product title | 22-24 | 28 | command gold | One per major window. |
| Page headline | 16-18 | 22 | primary text | One primary decision/title. |
| Section heading | 12 | 16 | warm gold/primary | Uppercase allowed. |
| Action text | 13-14 | 18 | primary text | Never muted. |
| Body | 11-12 | 16 | soft white | Minimum operational body role. |
| Table primary | 11 | 15 | primary/class/friendly | Stable one-line rows. |
| Table secondary | 10 | 14 | muted | Non-critical details. |
| Metadata | 9-10 | 13 | muted | Never the only expression of a command. |
| Technical verification | 10-11 | 14 | primary/monospace-like | Scrollable and selectable. |

Rules:

- do not use 8-point text for player-required information;
- do not use full uppercase for sentences;
- use uppercase only for short labels, badges, and table headers;
- no colored body paragraph longer than one line;
- important actions must remain readable without color perception.

### Surface colors

Final numeric values should be tuned in game against bright and dark scenes, but the
semantic ownership is fixed.

| Token | Intent | Starting direction |
| --- | --- | --- |
| `shell` | Full Command Center | Midnight navy-black, 94-97% opacity. |
| `surface1` | Main panel | Obsidian navy, 90-94% opacity. |
| `surface2` | Raised/selected card | Slightly lighter cool slate. |
| `surface3` | Row/field | Near-black with blue undertone. |
| `divider` | Normal structure | Muted slate-bronze, low contrast. |
| `brandGold` | Product/primary command | Current warm gold, sparingly used. |
| `focusGold` | Selected navigation/focus | Brighter gold with clear edge. |
| `textPrimary` | Decisions and values | Near white. |
| `textSecondary` | Explanations | Soft cool gray. |
| `textMuted` | Metadata | Gray meeting contrast gate. |

### Semantic colors

| Meaning | Color | Required companion |
| --- | --- | --- |
| Friendly/assigned | blue | label or friendly icon |
| Confirmed favorable/ready/success | green | state word or check |
| Attention/contested | yellow | state word or caution icon |
| Inferred/preview/limited | orange | `LIKELY`, `PREVIEW`, or source label |
| Urgent hostile/failure | red | explicit urgent/failure word |
| Learned/control context | purple | trait/control label; never general emphasis |
| Unknown/inactive | muted gray | `UNKNOWN`, `NOT LIVE`, or empty-state copy |

Red must never be used for a routine checklist. Purple must not represent a primary
action. Gold must not mean warning and selection at the same time.

### Border and depth

| Level | Treatment |
| --- | --- |
| Window shell | One 1px command-gold or state-aware edge. |
| Active tab/primary command | Focus-gold edge or 2px underline, not both everywhere. |
| Standard panel | Quiet divider or low-contrast slate edge. |
| Nested content | Surface contrast and spacing; no full border by default. |
| Urgent state | Semantic edge plus icon/label, no pulsing full-frame border. |

Maximum visible nested full borders: two levels including the window shell.

### Opacity

- planning windows: 94-97% shell opacity;
- options/verification: at least 95% behind body text;
- compact noncombat windows: 88-94%;
- combat surfaces: initial target 82-90%, subject to live evidence;
- text must never depend on the game scene being dark;
- optional world dim while a full planning window is open: 8-12%, no blur.

## Shared Components

Extend existing `Theme` methods rather than creating a parallel UI toolkit.

### `Theme:Panel`

- quiet structural surface;
- optional heading and divider;
- no gold full border by default;
- supports `standard`, `raised`, `selected`, and `urgent` variants.

### `Theme:Card`

- content grouping, not universal page geometry;
- default inset 12;
- title role 12/16;
- explicit empty, loading, unknown, and disabled states;
- overflow contract required at creation.

### `Theme:Button`

- minimum height 26 in planning windows, 24 in compact windows;
- primary, secondary, ghost, danger, and selected variants;
- hover and selected states must be visually different;
- disabled state must not look clickable;
- word-wrap false, but labels must fit without truncation at supported scales.

### `Theme:Badge`

- status only, not paragraph replacement;
- one to three words;
- fixed semantic colors;
- minimum text size 9;
- stable width only where alignment matters;
- no more than four simultaneous top-rail badges.

### `Theme:EmptyState`

Required fields:

- concise state title;
- one-sentence reason;
- next available action or activation condition;
- optional quiet icon;
- no repeated `NO DATA`, `UNKNOWN`, and `NOT LIVE` around the same field.

### `Theme:ScrollableText`

- visible scroll affordance when content exceeds region;
- optional top/bottom fade;
- mouse wheel and drag behavior;
- content never draws outside clip region;
- no thin edit-box texture behind ordinary display text;
- technical details may be selectable, player commands should not look editable.

### `Theme:Table`

- fixed header and stable row height;
- selected/hover state;
- optional selected-row detail pane;
- no row reflow during refresh;
- empty and partial-roster variants;
- overflow and maximum row count explicit.

## Responsive Shell Contract

### Main Command Center

- default design size remains 1240x760;
- minimum supported layout: 980x640;
- comfortable layout: 1180-1320 wide;
- expanded layout: up to 1440 wide without increasing text line length beyond a
  comfortable reading column;
- outer inset: 16-18;
- top brand/status rail: 82-88;
- navigation rail: 28-32;
- content begins below a single divider;
- center column is fluid;
- side rails use bounded widths, not proportional shrinking below readable limits;
- at minimum width, secondary help/detail becomes a drawer or lower panel.

### Compact surfaces

- must never inherit desktop density;
- one primary action and no more than three supporting blocks visible at once;
- minimum 12-point action text;
- no explanatory paragraphs during live play;
- combat dimensions remain provisional until live evidence.

### Options

- default 740x860 may remain;
- one column below 680 effective width;
- two columns at 680+;
- cards align to a shared row grid when side by side;
- footer utilities and policy span full width;
- scroll position is visible and persisted only if that behavior is useful.

## Surface Information Contracts

### Full Command Center

Every page keeps the shared shell, but each page gets one dominant answer:

| Page | Dominant answer |
| --- | --- |
| Tactical | What plan are we building or executing? |
| Objectives | What objective state changes the win condition? |
| Team | Who is ready, missing, or misassigned? |
| Enemies | Which enemy problem matters and what do we know? |
| Assignments | Who has each job, where, and when? |
| Review/AAR | What happened and what should change next match? |

Supporting panels that do not help answer the page question move behind selection,
help, or learning mode.

### Setup Center

Visible priority:

1. next setup action;
2. required roster roles;
3. queue readiness;
4. personal assignment;
5. explanation only on demand.

### Launcher menu

Group actions:

- Command: Command Center, Compact Center;
- Battlefield: Team Roster, Support View, Enemy Tracker;
- Review: Match Review, AAR/Export, Verification;
- Utility footer: Settings, Close.

One primary action should reflect the current context. Do not show nine equally
weighted rectangles.

### Target assist

The compact battlefield identifier is intentionally not a second nameplate. KWR owns:

- friendly role icon plus short name;
- enemy class icon plus short name;
- flag or orb carrier icon/color in place of the normal role/class icon;
- one priority ring;
- health strip only for the player's current enemy target;
- cast strip only while a visible enemy has an active priority cast.

Default identifiers have no panel background, health bar, assignment paragraph, or
technical evidence text. UNKNOWN role/class degrades to a neutral question marker; it
never fabricates DPS or class identity. KWR does not hide, restyle, or take ownership of
Blizzard or third-party nameplate frames. The user's nameplate addon remains responsible
for any base health bar it renders.

## Motion and Feedback

- use state-change fades of 120-180ms only where supported cheaply;
- no continuous ambient animation on full windows;
- no layout movement during refresh;
- urgent state may use one short entrance accent, then remain stable;
- selected navigation and button feedback are immediate;
- do not add an `OnUpdate` loop for visual polish.

## Performance Contract

- visual migration adds no polling ticker;
- no new per-frame work;
- no texture allocation during normal refresh;
- no repeated font/string creation during normal refresh;
- layout recalculates only on create, scale/size change, or explicit content mode
  change;
- existing frames, rows, badges, and textures are reused;
- hidden surfaces remain subscribed through existing filtered Store behavior;
- no full-page relayout from ordinary Store publishes.

## Accessibility and Readability Gate

- body text contrast target: 4.5:1 against the actual rendered panel;
- large text and non-text indicators: 3:1 minimum;
- test over bright white/gold, saturated purple, dark interior, and busy combat scenes;
- status never relies on color alone;
- focus/selected state is visible without hover;
- interactive areas are at least 24 high;
- text is not clipped at 1280x720, 1920x1080, or 2560x1440;
- reference 2560x1440 / 65% setup remains the primary visual sign-off environment.

## Future-Proof Rule

Future WoW visual changes must be absorbed through theme tokens and adapters, not
surface rewrites. Do not use expansion-specific art, private APIs, or Blizzard frame
internals as a required visual dependency. KWR should feel at home in Midnight while
remaining recognizably KWR in the expansion after it.
