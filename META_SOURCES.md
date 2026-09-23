# RBG Meta Data Provenance

Audit update, 2026-09-07: the
[official hotfix ledger](https://worldofwarcraft.blizzard.com/en-us/news/24296142)
was reviewed through September 4. September 1 PvP tuning (healer trinket primary
stat, Devourer, Havoc and Innervate) and September 2 PvP fixes (Balance Faerie
Swarm presentation and Preservation Rewind) are recorded as advisory observation
work only. No target weight, cooldown, capability rating, strategy or snapshot is
inferred from those notes. OVR-16 owns a fresh delta review immediately before a
clean candidate build; OVR-07 checks those bundled assumptions against the actual
client build. Prior provenance below remains the shipped-data record.

KWR 6.1.1-alpha.10 contains a static Rated Battleground specialization snapshot
captured on 2026-06-27 for Retail patch 12.0.7, Midnight Season 1.

Source pages:

- https://murlok.io/meta/healer/rbg
- https://murlok.io/meta/tank/rbg
- https://murlok.io/meta/dps/rbg

Murlok reports that its rankings and specialization guides are derived from
active top-rated characters and refreshed every eight hours. KWR ships only the
captured role, rank, and displayed rating values in `Data/MetaSnapshot.lua`.

This snapshot is advisory. It is never treated as live battlefield truth, does
not identify an individual player's talents or equipment, and contributes only
a small tie-breaking weight after local range, role, health, observed trinket
use, observed defenses, and manual priority. Because it is not a reviewed
Retail 12.1 snapshot, `KnowledgeManifest` excludes it from Season 2 meta
influence even though the active patch compatibility review is current.

World of Warcraft addons cannot make arbitrary web requests during play. A new
release must therefore refresh and review this snapshot during development.

Patch-relative capability ratings are maintained separately in
`Data/PatchData.lua`. The Retail 12.1 pack was reviewed on 2026-08-30 against
Blizzard's official Season 2 schedule and official hotfix ledger through
2026-09-04. The review records the August 13 PvP fixes, August 18 PvP tuning,
August 19 tier-shoulder PvP-item-level correction, August 17-20 class mechanics
fixes, August 25 direct PvP tuning (including Warlock), the August 26 Training
Grounds Arena lifecycle correction, the August 27 Vicious Saddle and Blur scope
repairs, September 1 PvP tuning, and the September 2 PvP presentation/ability
fixes as an advisory field watch.
Directional tuning and training-mode lifecycle fixes were not converted into
invented numerical ratings or capability overrides: KWR remains fail-closed
until reviewed Retail evidence supports a bounded update. Capability data
describes relative strategic tendencies, not individual-player talents,
equipment, or guaranteed spell availability.
