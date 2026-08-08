---
id: KWR-046
title: Build full offline foundation-depth corpus
owner: Codex
priority: high
risk: medium
dependencies: [KWR-043, KWR-044, KWR-045]
affected_modules: [tools/build-foundation-depth-corpus.ps1, tests/replays, tests/golden, tests/replay-results, tests/outcomes, tests/adversarial, knowledge/corpus-manifest.json]
---

# Objective

Expand the all-map starter corpus into a full offline foundation-depth corpus:
five reviewed cases per defined scenario and one adversarial case per scenario.

# User outcome

The repository contains a complete offline foundation layer that covers all ten
maps, all five common scenarios per map, and enough detailed structured cases to
support broad offline decision work before live expert review is added.

# Current behavior

The repository has one starter case per scenario and one adversarial case total.

# Required behavior

- Generate four additional reviewed cases per scenario.
- Generate one adversarial case per scenario.
- Rebuild the corpus manifest from actual files.
- Preserve benchmark/audit compatibility.

# Non-goals

- Claiming these synthetic cases are equal to field-reviewed expert evidence.
- Replacing later expert review, real replay intake, or live battleground proof.

# Technical constraints

- Use deterministic, schema-valid JSON.
- Keep labels, run results, and outcomes internally consistent.
- Keep uncertainty explicit in adversarial cases.

# Acceptance criteria

- [x] Fifty scenario definitions have five reviewed cases each.
- [x] Fifty scenario definitions have one adversarial case each.
- [x] Corpus manifest reflects the actual generated file counts.
- [x] Corpus audit, benchmark, and outcome report all pass after generation.

# Verification

1. Run `./tools/build-foundation-depth-corpus.ps1`.
2. Run `./tools/corpus-audit.ps1`.
3. Run `./tools/decision-benchmark.ps1`.
4. Run `./tools/outcome-report.ps1`.

# Rollback

Remove the generated variant files and restore the previous corpus manifest.
