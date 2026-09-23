# Candidate Field Capture Matrix

Current diagnostic candidate: `alpha12-kwr297-source-20260910-1`
(`6.1.1-alpha.12`), Commander SHA-256
`249A2FBD2C5AE21A5016B1C8664CE9A7CA26943D8718CE5BBD76452CE04378A4`.
It is installed and hash-verified by
`artifacts/release-offline-install-20260912-r4/DEPLOYMENT.json`.

Before beginning any session, record the Commander and Sentinel SHA-256 values
from the current deployment receipt in the field log. Do not reuse historical
Alpha hashes or mix evidence from another candidate.

Evidence captured against this installed dirty-source candidate may clear its
diagnostic live blockers. It cannot certify a clean/tagged release; that later
candidate requires its own exact package binding and fresh field evidence.

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
