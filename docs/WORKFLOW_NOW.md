# KWR automation work queue

This operational queue supplies scheduled-maintenance context only. It does
not authorize releases or define version, blocker, architecture, or product
status; those decisions belong to `RELEASE_READINESS.md` and the document
authority registry.

## Current lane

1. Complete the required certification run for PR #51, then merge the final Alpha.4 provenance repair
2. Collect candidate-bound Retail evidence against the exact installed Alpha.4 Commander and Sentinel archive hashes
3. Publish the prerelease only after the field-capture matrix, final GitHub release gate, and both CurseForge upload/download checks pass

## Ready to work right now

1. Confirm PR #51 certification is green and every review thread is resolved.
2. Run `TP-TEAM-TRUTH`, `TP-STABILITY`, `TP-CARRIER-TARGET`, `TP-READABILITY`, and `TP-SAFETY-MAP` in the exact deployed candidate.
3. Export SavedVariables, rerun candidate-bound certification, and capture the map-family and ten-client Sentinel evidence before promotion.

## Recently completed

1. The Alpha.4 Commander and Sentinel packages passed reproducibility, extracted-runtime, and exact installed-file verification.
2. The 100,000-case Nexus corpus, control-surface inventory, identity replay, and retention/performance offline gates passed.
3. Field-evidence reporting now distinguishes candidate-bound proof from historical captures and never promotes the target version without proof.

## Newly discovered / still needs attention

1. PR #51 must complete its current GitHub certification run before merge.
2. No completed Alpha.4 Retail match is yet bound to the deployed package; the remaining safety, performance, roster, carrier, readability, and map-family gates require live evidence.
3. GitHub prerelease and both CurseForge uploads remain blocked until the candidate-bound field gate passes, with public download hashes verified.
