# KWR Data Governance

This is the sole authority for runtime and gameplay-data ownership.

Reviewed gameplay data lives under `Data/` and is loaded by the existing TOC.
`Core/Store.lua` owns persisted runtime state. Do not duplicate definitions in
Commander, Sentinel, bot, or documentation. Any future generated artifact must
declare its source and generator and be checked in CI. Schema changes require a
backward-compatible migration or an explicit read-only compatibility mode.

Development and local builds must never migrate production SavedVariables in
place. A future isolated addon identity must use distinct database names.
