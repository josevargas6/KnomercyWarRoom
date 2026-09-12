# ADR-001: Separate developer tools and retain the production truth gate

Status: accepted for implementation, 2026-09-05. Work: KWR-281 / OVR-01.

## Context

The installed Alpha 12 separates optional diagnostics, but the canonical checkout
could not reproduce that package. Verification also owns a truth contract used
by live strategy. Moving that entire module would remove the production gate.

## Decision

Runtime/TruthContract.lua owns Verification:Contract and loads in Commander.
Runtime/Verification.lua extends the same object with reports and a bounded
subscriber ledger. Preview, Verification reports and Season2Readiness retain
their canonical source in Runtime; no second implementation is maintained.

The release-manifest helper stages those three modules into load-on-demand
KWR_DevTools. The only module transform changes their namespace header to the
existing Commander global. Bootstrap and activation code live in KWR_DevTools/.
Generated TOC and bootstrap versions come from Commander's TOC. Player archives
exclude the three developer modules. The companion ZIP and its checksum are
developer CI artifacts, outside the public player-asset allowlist.

BuildInfo validates version and load completion, contains loader errors, and
requires explicit opt-in. Activation initializes once, subscribes on enable,
unsubscribes on disable, and cleans up partial failures. Disabling capture does
not unload Lua; fully releasing loaded code requires UI reload. Core lifecycle
flags allow already initialized source modules to share this contract.

## Verification and limits

The lifecycle test loads actual staged Lua and exercises absent, throwing,
mismatched and incomplete packages, repeated activation, reactivation, failure
cleanup, and preservation of the production truth function. Source tests
explicitly exercise bundled tools. Player tests require their absence and retain
the truth gate. Package audit compares the extracted companion with a fresh
canonical transform and tests it with extracted Commander. Clean reproducibility
and Retail loading remain release gates; mocks do not prove live combat safety.

## Consequences and rollback

SavedVariables gains an optional normalized developmentMode boolean, default
false. Existing data remains intact. Corpus projections and AAR retention are
separate unfinished reconciliation work. Roll back the source/build changes
together; restore preserved runtime packages if a later deployment needs rollback.
