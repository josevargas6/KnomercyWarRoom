# KWR Deep Truth Integration Map

This note captures how the `KWR_Codex_Deep_Truth_Handoff.zip` package should
be folded into KWR without creating a second command brain.

## Core rule

Deep Truth is a doctrine and scoring enhancement package, not a rewrite.

KWR already has the correct owners:

- `Data/Maps.lua`
- `Data/Capabilities.lua`
- `Data/Compositions.lua`
- `Data/BattlePlans.lua`
- `Data/Counters.lua`
- `Data/ScenarioLibrary.lua`
- `Data/CombatSpells.lua`
- `Runtime/Strategist.lua`
- `Runtime/Assignments.lua`
- `Runtime/AAR.lua`

New knowledge should arrive as data-only layers first and then be consumed as
safe scoring modifiers or explanation detail.

## Adopt now

These layers fit the current alpha immediately and deepen live calls without
changing the architecture.

### 1. ObjectiveRules

Create:

- `Data/ObjectiveRules.lua`

Use for:

- reinforce thresholds;
- stall thresholds;
- abandon thresholds;
- overcommit punish thresholds;
- counter-cap triggers;
- mechanic-specific minimum defenders.

Runtime consumers:

- `Runtime/Strategist.lua` for plan weighting;
- `Data/ScenarioLibrary.lua` for clearer `NEXT:` and `SWITCH IF:` language;
- `Runtime/AAR.lua` for logging which threshold influenced the call.

Why it fits:

KWR already selects plans and response packages. This layer simply helps the
current brain decide when a plan should hold, reinforce, stall, or abandon.

### 2. AssignmentDoctrine

Create:

- `Data/AssignmentDoctrine.lua`

Use for:

- sitter modifiers;
- spinner modifiers;
- floater modifiers;
- harasser modifiers;
- anchor modifiers;
- kill-core / peel modifiers;
- map-and-threat-specific role fit.

Runtime consumers:

- `Runtime/Assignments.lua` primary;
- `Runtime/Strategist.lua` explanation and fallback weighting.

Why it fits:

Assignments already compute battle value from capabilities. This layer should
modify that score, not replace it.

### 3. CompThreats

Create:

- `Data/CompThreats.lua`

Use for:

- normalized threat tags for the curated tier comps and future comp rows;
- weakness tags;
- preferred enemy win paths;
- counter principles.

Runtime consumers:

- `Runtime/Strategist.lua` primary;
- `Data/Counters.lua` as richer doctrine input;
- `Runtime/AAR.lua` to record which enemy threat profile was active.

Why it fits:

KWR already understands archetypes and counters. This gives the current
strategist better enemy-shape language than broad archetype alone.

### 4. EnemyDefenseModels

Create:

- `Data/EnemyDefenseModels.lua`

Use for:

- thin defense;
- heavy home defense;
- reactive defense;
- overcommit main;
- bunker defense;
- teamfight-first defense.

Runtime consumers:

- `Runtime/Strategist.lua` for choosing trade / stall / split / contain calls;
- `Runtime/AAR.lua` to log which defense model was inferred.

Why it fits:

KWR already evaluates response packages and objective pressure. This layer
helps the strategist identify how the enemy is actually holding the map.

## Adopt next

These layers are valuable, but should follow after the four items above are
stable and field-tested.

### 5. TerrainModifiers

Create:

- `Data/TerrainModifiers.lua`

Use for:

- high-ground value;
- choke value;
- knockback value;
- line-of-sight value;
- stealth route risk;
- reinforce difficulty;
- defender / floater / harasser bias.

Runtime consumers:

- `Runtime/Assignments.lua` first;
- `Runtime/Strategist.lua` second;
- `Runtime/Reporter.lua` only for explanation, not fabricated map dots.

Why later:

This is very strong doctrine, but it requires careful review map by map and can
become noisy if introduced before assignment and objective thresholds are
stable.

### 6. CompMapMatrix

Create:

- `Data/CompMapMatrix.lua`

Use for:

- map-specific fit score per comp;
- opener shape;
- stabilization shape;
- defender plan;
- floater plan;
- harass plan;
- overcommit punish;
- abandon rule.

Runtime consumers:

- `Runtime/Strategist.lua` only.

Why later:

The matrix should remain a doctrine-weight input. It must never become a hard
script that overrides live battlefield truth.

### 7. BracketRules

Create:

- `Data/BracketRules.lua`

Use for:

- separate assumptions for `RBG_10V10`, Blitz, and random BG;
- map enable/disable by ruleset;
- different doctrine thresholds by bracket.

Runtime consumers:

- `Data/Maps.lua`;
- `Runtime/Strategist.lua`;
- `Runtime/Assignments.lua`.

Why later:

Useful and clean, but the current request is to deepen commander truth for the
active alpha. That is more constrained by objective/assignment doctrine than by
cross-bracket branching right now.

### 8. AbilityWindows

Create:

- `Data/AbilityWindows.lua`

Use for:

- offensive windows;
- defensive windows;
- healer-save windows;
- control windows;
- objective-denial windows;
- advisory-only timing policy.

Runtime consumers:

- `Data/CombatSpells.lua` as a supplement;
- `Runtime/Strategist.lua` for opportunity scoring;
- `Runtime/AAR.lua` for reviewed window logging.

Why later:

Powerful, but only if every entry has a safe tracking policy. KWR must not turn
estimated cooldown knowledge into fake certainty.

## Learn later, not now

### 9. PlayerReliability overlay

Do not hardcode this into live assignments now.

Future owner:

- `Runtime/AAR.lua`
- `Runtime/Learning.lua`

Safe use later:

- small modifier only;
- expiring and locally reviewed;
- never allowed to outrank live truth;
- never allowed to make a hidden player blacklist.

## Keep out to avoid drift

Do not do any of the following:

- create a second strategist;
- replace `BattlePlans`, `Counters`, or `ScenarioLibrary`;
- replace capability scoring with a new engine;
- hard-script matrix rows into HUD calls;
- let new layers bypass confidence or freshness handling;
- show 405-row doctrine detail in the combat HUD;
- turn likely or stale enemy state into confirmed truth.

## Recommended implementation order

1. `Data/ObjectiveRules.lua`
2. `Data/AssignmentDoctrine.lua`
3. `Data/CompThreats.lua`
4. `Data/EnemyDefenseModels.lua`
5. update `Data/KnowledgeManifest.lua`
6. wire conservative getters into:
   - `Runtime/Strategist.lua`
   - `Runtime/Assignments.lua`
   - `Runtime/AAR.lua`
7. field-test and verify fallback behavior
8. only then add:
   - `TerrainModifiers`
   - `CompMapMatrix`
   - `BracketRules`
   - `AbilityWindows`

## Working principle

KWR should keep deciding from one battlefield truth:

```text
Doctrine says what usually works.
Live truth says what is happening now.
Confidence says how hard KWR should commit.
```

That is the correct way to deepen the addon without drifting away from the
current alpha architecture.
