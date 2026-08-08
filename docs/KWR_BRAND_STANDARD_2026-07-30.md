# KWR Brand Standard

Date: 2026-07-30  
Authority: active repository standard

## Purpose

KWR is a tactical command product, not a collection of loosely related PvP
windows. Every current and future KWR surface must read as part of the same
operating system under pressure.

## Identity

KWR must feel:

- tactical;
- authoritative;
- fast to read;
- minimal under pressure;
- military-adjacent without cosplay;
- competitive without streamer-overlay excess.

Brand keywords:

- precision;
- clarity;
- command;
- threat awareness;
- restraint;
- execution.

Reject any surface that feels fantasy-cluttered, neon-overstimulated, or like a
generic esports template.

## Color System

Use a dark command-center base with restrained semantic accents.

| Role | Token | Hex | Rule |
| --- | --- | --- | --- |
| Background | `KWR_COLOR_BG` | `#0B0F14` | Main app background only. |
| Window shell | `KWR_COLOR_SHELL` | `#0B0F14` | Full Command Center shell. |
| Surface | `KWR_COLOR_SURFACE` | `#121922` | Panels, cards, grouped content. |
| Surface raised | `KWR_COLOR_SURFACE_RAISED` | `#1A2430` | Hover, active, selected surfaces. |
| Border | `KWR_COLOR_BORDER` | `#2A3644` | Quiet structural edge. |
| Primary | `KWR_COLOR_PRIMARY` | `#C9A227` | Command authority, selection, emphasis. |
| Secondary | `KWR_COLOR_SECONDARY` | `#4D7EA8` | Neutral tactical information. |
| Success | `KWR_COLOR_SUCCESS` | `#4FA36C` | Confirmed good, stable, ready. |
| Warning | `KWR_COLOR_WARNING` | `#D98E04` | Timing, caution, partial readiness. |
| Danger | `KWR_COLOR_DANGER` | `#B44343` | True threat only. |
| Primary text | `KWR_COLOR_TEXT` | `#D9E2EC` | Main values and text. |
| Muted text | `KWR_COLOR_TEXT_MUTED` | `#8A97A6` | Secondary context and metadata. |

Usage rules:

- gold means authority, command, focus, or selection;
- red means real threat or failure, never decoration;
- blue means neutral tactical information;
- green means confirmed and stable;
- amber means risk, timing, or partial readiness;
- color never stands alone without text, icon, or shape support.

Ratio rule:

- 70% dark neutrals;
- 20% steel and slate surfaces;
- 10% accent and semantic color.

## Typography

KWR uses at most two font roles:

- `KWR_FONT_HEADER`: strong tactical heading role;
- `KWR_FONT_BODY`: clean operational text role.

Current implementation standard:

- use WoW-provided font resources only;
- separate hierarchy by size, outline, case, and color;
- do not add external font dependencies without a separate decision record.

Type rules:

- uppercase is allowed for short labels, tabs, and badges only;
- never use all caps for dense paragraphs;
- numeric and timer text must remain highly legible;
- do not exceed three text sizes inside one compact combat card without a clear reason.

Reference scale:

| Role | Target size |
| --- | ---: |
| Window title | 18-22 |
| Section title | 14-16 |
| Card title | 12-14 |
| Body | 11-14 |
| Secondary/meta | 10-12 |
| Tiny label | 9-10 |

## Component Families

KWR should standardize on a short list of reusable classes:

- Command Card: one primary tactical instruction, one priority state, optional timer.
- Status Card: readiness, cooldown, availability, DR, or visibility state.
- Threat Card: enemy danger, healer risk, or incoming swing warning.
- Assignment Card: owner, fallback owner, target, and location.
- Summary Card: quick scan and match snapshot.

Card anatomy:

1. top strip for tone or icon;
2. primary line for the dominant action or title;
3. secondary line for supporting context;
4. meta row for timer, role, confidence, source, or tags.

Rules:

- one dominant action per card;
- predictable card height;
- no paragraph cards in combat contexts;
- use icon plus color plus label, not color alone.

## Asset Rules

KWR assets must support the same visual doctrine as the UI:

- angular, restrained, tactical geometry;
- desaturated support art;
- no busy fantasy paintings behind dense text;
- no loud gradients or glow-driven identity;
- all marks must remain legible at small sizes;
- icons must work in monochrome where practical.

Logo direction:

- primary lane: tactical monogram;
- supporting lane: chevron, reticle, or command-sigil geometry;
- every mark must survive minimap-button and title-bar scale.

## Enforcement Rule

No KWR interface element should be introduced without mapping to the shared brand
tokens, typography rules, and component library.
