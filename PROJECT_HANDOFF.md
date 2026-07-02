# KWR Alpha Project Handoff

## Stable baseline

The recoverable runtime baseline is **KWR 6.1.0-alpha.9**.

Alpha 9 is the last certified implementation. It contains one Store, one
MatchRuntime, one Strategist, one Commander, the three-line Scout HUD, unified
Command Center, compact Team/Enemy roster, Reporter, assignment integrity,
confidence budget, objective ETA, enemy intent, momentum, opportunity
evaluation, candidate simulation, and manual structured AAR export.

Do not rebuild these systems or create parallel advisor products. The next
work strengthens their inputs, calculations, arbitration, and presentation.

The current S-tier trust candidate is **KWR 6.1.0-alpha.13**. It retains
Alpha 12's target/cast clarity and complete response package while adding one
normalized battlefield truth contract, monitored assignment/coverage
contracts, route-based ETA fallback, objective-aware candidate scoring, and
map-specific counter responses. Commander, reassessment, Tactical,
Assignments, Why, Verify, and AAR still consume the same authoritative state.
Alpha 9 remains the rollback authority until the newer candidates pass live
Retail testing.

## Product test

Every proposed change must answer:

> Does this consistently improve the team's probability of winning without
> increasing cognitive load?

If it does not change a decision, it should remain silent. Detailed evidence
belongs in `/kwrwhy` and AAR.

## Agreed visual-command direction

- The combat HUD remains three lines.
- Immediate local context uses at most one temporary advisory.
- The first experimental advisory surface reuses the existing Cursor Ring.
- A player-centered screen-space ring may follow only after cursor testing.
- No scrolling combat text, floating numbers, alert wall, or stacked rings.
- Gold means command/objective, red immediate danger, amber caution, blue
  verified support, green opportunity/stability, purple uncertainty, and gray
  neutral/isolated.
- Shape must remain meaningful without color: inward teeth for kill risk,
  closing arcs for pressure, open arcs for support, outward points for
  opportunity, and a sweep for rotation/reset.
- A warning has a short lifetime, confidence threshold, hysteresis, and rearm
  delay. Disabling visuals never disables calculation.

## Alpha 10 implementation scope

Alpha 10 should be additive and delivered in small certified slices.

### Slice A - Combat clarity

1. Add an optional **Combat Clarity** section under Extras.
2. Discover supported Blizzard settings at runtime and expose only reversible
   player-click controls.
3. Preserve enemy cast bars, objective carriers, projected mechanics, and
   essential warnings.
4. Allow optional suppression of scrolling combat text and minor pet/minion
   nameplates where supported.
5. Save the player's prior values and restore those exact values.
6. Never disable or reconfigure another addon automatically.

### Slice B - Target spotlight and cast priority

1. Add one pre-created target spotlight above the enemy roster. It follows the
   fixed `target` unit and does not reorder secure rows in combat.
2. Keep the target health bar larger, class colored, and visually foremost.
3. Extend the existing reviewed `CombatSpells` catalog with:
   - `interruptPriority`;
   - `advantagePriority`;
   - defensive class (`IMMUNITY`, `MAJOR_MITIGATION`, `ABSORB`, `CHANNEL`);
   - response (`STOP`, `SWAP`, `HOLD_DAMAGE`, `LOS`, `SPREAD`);
   - reviewed duration and confidence notes.
4. Ordinary rotational casts retain the normal Blizzard cast presentation.
5. Only high-value interrupt or advantage-swing casts receive an accent.
6. A protected kill target loses its kill glow. The best safely observed
   alternative may receive the existing kill highlight, but KWR never changes
   the player's target.

### Slice C - Local advisory calculator

Build this inside the current CombatIntel -> Strategist -> Commander path.
Do not create a second command brain.

Initial advisory states:

- `KILL_RISK`;
- `PRESSURE`;
- `ISOLATED`;
- `OPPORTUNITY`;
- `SUPPORT`;
- `ROTATE_RESET`;
- `NONE`.

The arbiter emits one state with severity, confidence, evidence, expiry, and
recommended response. Combat displays one qualified state; `/kwrwhy` shows the
calculation.

### Slice D - Fortress and kill-zone counterplay

Detect an unfavorable objective engagement from converging evidence:

- reviewed enemy rot/cleave/displacement capability;
- three-healer or heavy-support structure;
- safely observed high-impact casts;
- local enemy engagement;
- friendly concentration or assignment collapse;
- repeated failure to convert a kill/capture;
- objective importance;
- reinforcement and rotation economy.

States:

1. `FORMING` - amber caution;
2. `ACTIVE` - red exit/spread advisory;
3. `RECOVERY` - neutral/blue regroup advisory.

The strategic response is **Contain and Trade**:

- calculate the minimum viable stall force;
- keep that force from feeding the lethal center;
- send a mobile strike team to the best exposed objective;
- watch for enemy peel;
- pressure the weakened fortress or finish the trade;
- abort when the stall fails or the alternative cannot convert in time.

### Slice E - Macro decision-quality upgrades

Fold these into existing modules:

- Objective Commitment -> Assignments/Strategist;
- Rotation Economy -> Reporter ETA/Strategist simulation;
- Pressure Forecast -> Reporter intent/ETA;
- Collapse and Recovery -> Strategist opportunity/momentum;
- Battlefield organization/entropy -> assignment integrity and AAR;
- Tunnel/dead-time warnings -> assignment deviation only when strongly proven;
- Objective influence -> per-objective summaries, not fabricated ground
  geometry.

## Seventeen-feature disposition

| Feature | Alpha disposition |
|---|---|
| Battlefield Influence | Build objective-level influence; defer exact spatial fields. |
| Action Opportunity | Extend the existing candidate simulator; never show a list in combat. |
| Battlefield Entropy | Internal organization score plus causes in `/kwrwhy` and AAR. |
| Kill Zone | Promote to high-priority engagement-quality calculator. |
| Pressure Forecast | Extend existing Reporter intent and ETA. |
| Rotation Economy | High-priority existing-Strategist upgrade. |
| Collapse Detection | Conservative `STALL`, `TRADE`, `RESET`, or `DISENGAGE` output. |
| Objective Commitment | Highest near-term macro priority. |
| Formation Quality | Qualitative assignment topology; no fabricated LOS/spacing. |
| Tunnel Vision | Use objective-priority change plus assignment deviation. |
| Reinforcement Prediction | Continue existing ETA with ranges and confidence. |
| Friendly Coverage | Use legal group/assignment/capability evidence; no false safe state. |
| Kill Chain | Reviewed high-value casts and sequence risk; no full combat-log solver. |
| Recovery Window | Build from secured objective, reduced pressure, and reassignment need. |
| Dead Time | Commander/AAR only unless player inactivity is strongly evidenced. |
| Command Confidence | Existing foundation; add conflict, freshness, and stealth penalties. |
| Battlefield Intent | Extend current-match patterns using `LIKELY`, `POSSIBLE`, `UNKNOWN`. |

## Evidence contract

Every calculated result declares:

- `OBSERVED` - directly sanitized public evidence;
- `DERIVED` - arithmetic from observed facts;
- `LIKELY` - multiple supporting signals;
- `POSSIBLE` - strategically relevant but incomplete;
- `UNKNOWN` - unavailable.

KWR may reason aggressively from permitted observations. It must not scrape
rendered Combat Log text, decode a secret value through visual side effects,
or present estimated cooldown readiness as an inspected live cooldown.

Observed casts may start reviewed estimated windows. Talent reductions, resets,
and incomplete coverage reduce confidence.

## Live test factors

### Safety

- No BugSack error, blocked action, forbidden action, secret-value comparison,
  or taint.
- No secure-row movement, unit-attribute mutation, or visibility mutation in
  combat.
- No automatic target, focus, chat, macro, keybinding, spell, or addon control.
- Unsupported CVars are hidden; all clarity changes restore exactly.

### Cast clarity

- Normal rotation casts receive no KWR accent.
- Reviewed must-stop casts are recognizable within 300 ms of a safe event.
- Advantage-swing casts use a distinct, non-red caution treatment.
- Interruptibility is never guessed.
- Repeated high-value completed casts create one bounded free-caster state.
- Pet/minion clutter reduction never hides player cast bars.

### Target spotlight

- Current target remains larger and on top through nameplate churn.
- Health displays directly without arithmetic on secret values.
- Immunity removes kill glow.
- Cocoon/absorb does not force a swap without a better actionable target.
- A swap recommendation highlights but never selects the alternative.
- Target/focus clicks remain correct in combat.

### Kill-zone advisory

- Composition risk alone produces at most amber `FORMING`.
- Red `ACTIVE` requires corroborating live evidence.
- One warning only; no text wall, flashing, or stacked ring.
- Warning expires when evidence expires and does not flicker.
- False positives, missed warnings, warning lead time, and player response are
  captured in AAR.

### Contain and Trade

- The stall group is the minimum viable force, not a stream of deaths.
- Strike travel plus capture time is compared with enemy peel/reinforcement.
- Enemy peel changes the recommendation.
- Stall failure triggers a complete-trade or abort decision.
- Map win condition always outranks local kill-zone coaching.

### Performance

- No new independent ticker.
- Event collection remains bounded and dirty-state driven.
- P95 strategic refresh remains below 2 ms; routine maximum remains below 4 ms.
- Thirty-minute post-GC memory growth remains below 1 MB.
- Visual rendering skips unchanged state.

## Promotion gates

No slice advances until:

1. deterministic diagnostics cover evidence, expiry, confidence, and fallback;
2. the 500-refresh soak passes;
3. package extraction and revalidation pass;
4. at least three live matches contain no protected/secret-value fault;
5. false-positive examples are reviewed through AAR;
6. the feature demonstrably changes a useful decision without persistent
   visual load.
