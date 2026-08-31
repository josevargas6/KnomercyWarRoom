# Candidate Field Capture Matrix

Candidate: `6.1.1-alpha.10` (unbound until exact-head CI publishes its commit
and archive hashes)

Before beginning any session, copy the Commander and Sentinel SHA-256 values
from the exact-head CI artifact manifest into the field log. Do not reuse the
Alpha 4/5 hashes below or treat the currently installed folders as evidence.

Only evidence captured against the exact installed Alpha 9 archive hashes may
clear the sessions below. Historical Alpha 4/5/36/43 evidence remains useful
for diagnosis, but cannot certify this candidate.

This is the fastest path to useful live evidence.

## Clear current promotion blockers first

| Session | Best maps | Clears | What to capture |
| --- | --- | --- | --- |
| `TP-TEAM-TRUTH` | Twin Peaks | `LIVE-TEAM-TRUTH` | compact Team + expanded Team + Assignments for the same players, with one HIST case if possible |
| `TP-STABILITY` | Twin Peaks, Warsong Gulch | `LIVE-STABILITY` | full match, `/kwr verify`, `/kwr perf`, match-end AAR, command lifetime/stability evidence |
| `TP-CARRIER-TARGET` | Twin Peaks, Warsong Gulch | `LIVE-CARRIER-TARGET` | flag pickup/drop/return/cap state changes with tactical page and command copy visible |
| `TP-READABILITY` | Twin Peaks | `LIVE-READABILITY` | all command center tabs at supported scale with no meaningful clipping |
| `TP-SAFETY-MAP` | Twin Peaks, Warsong Gulch | secure/native-map gate | `Shift-M` before/during/after combat, no taint or blocked-action warning, `/kwr bug`, and map/command coexistence |

## After current P1 blockers are clear

| Session | Maps | Goal |
| --- | --- | --- |
| `RBG-MAP-CERT-1` | Arathi, Gilneas, Deepwind, Eye of the Storm | first node/hybrid family certification set |
| `RBG-MAP-CERT-2` | Temple, Silvershard, Deephaul, Seething Shore | first orb/cart/resource family certification set |
| `FLAG-FINAL-CERT` | Twin Peaks, Warsong Gulch | final flag-family certification after blocker closure |
| `SENTINEL-10-CLIENT` | any complete RBG | optional transport proof | explicit Field-mode enablement, handshake, malformed-packet rejection, expiry, reload, match-end teardown, taint scan, and recipient-value capture |

## Order

1. clear the four named live blockers and the native-map safety gate
2. repeat one clean flag-family session with completed AAR evidence
3. collect completed win and loss evidence across every map family
4. complete the opt-in ten-client Sentinel transport proof
5. rerun candidate-bound SavedVariables certification; only then consider
   promotion language beyond "field testing"
