# ADR-002: Preserve executable scenario contracts during regeneration

Status: Accepted, September 5, 2026

The three scenario data generators had diverged from their loaded Lua modules:
regeneration would remove compact lookup methods used by Strategist. Updating
generated Lua directly cannot be the lasting fix.

Keep each module's executable implementation in a Lua build template under
tools/templates. Each builder replaces one explicit data token with its existing
serialized data. Data modules remain the only runtime-loaded artifact. No runtime
template loading or new addon service is introduced.

Generators accept an isolated output directory. The knowledge gate regenerates
all three modules there and compares complete normalized Lua against canonical
Data modules, rejecting drift rather than repairing it implicitly. Input JSON
and generated timestamps are not rewritten by this check.

Full and compact map/phase lookups share one lazy index. Calibration and
adversarial rows use ascending scenario ID as the fallback tie break. Expert
rows retain the existing confidence/season eligibility and season-prep priority;
the index is rebuilt on activation changes. This defines deterministic lookup,
not evidence that one tied scenario is tactically superior.

Future runtime projections must preserve this tested API/data contract or record
an explicit migration. This decision does not approve the installed projections
or turn generated labels into field evidence.
