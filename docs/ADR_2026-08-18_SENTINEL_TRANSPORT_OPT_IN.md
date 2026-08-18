# ADR: Sentinel transport is opt-in on clean installs

## Status

Accepted — 2026-08-18

## Context

The Sentinel companion can transmit bounded, validated `KWRSync1` observations
and receive player-specific Commander relays. Its deterministic ten-client
protocol coverage passes, but Retail multi-client, combat-lockdown, and player
value evidence remain live-release gates. Enabling transport by default on a
clean install would send addon traffic as soon as an eligible group channel is
available, before a player has deliberately chosen the feature.

## Decision

Both Commander and `KWRSentinel` default their transport flags to `false`. The
existing explicit Field-mode action enables the complete companion profile,
including both sides of transport. Existing saved settings remain untouched.
Commander and Sentinel continue to operate locally when relay transport is
disabled.

## Consequences

- A first-time player gets the full local Commander/Sentinel experience without
  unsolicited group addon traffic.
- A player or team lead can enable the reviewed relay path deliberately through
  Field mode; the feature is implemented, not hidden or stubbed.
- Cross-client functionality remains a live-evidence requirement, rather than
  an unproven default behavior.

## Verification and rollback

The deterministic transport suite covers bounded valid/invalid relay behavior.
Retail field validation must capture a full multi-client match on the exact
released hash. To roll back the feature behavior, leave transport disabled or
disable its profile flag; no strategy, UI, or local observations depend on it.
