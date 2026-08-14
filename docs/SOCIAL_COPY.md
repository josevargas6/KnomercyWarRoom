# KWR Public Communication Copy

This is approved audience-safe public copy. Keep operational details,
credentials, channel IDs, and private incident evidence in maintainer-only
runbooks. Release authorization remains solely in `RELEASE_POLICY.md`.

## Commander

Knomercy War Room is a player-controlled Rated Battleground command system for
World of Warcraft Retail. It turns verified battlefield state into one clear
next call, assignment, win condition, and abort condition for the team.

The `6.1.0-alpha.43` field-test copy applies to an active field-test candidate,
not a stable guarantee. KWR never auto-casts, changes targets, sends visible
chat, or performs protected actions. Reviewed `KWRSync1` traffic only relays
bounded Commander/Sentinel state inside the battleground group.

Official source and release history: [GitHub](https://github.com/josevargas6/KnomercyWarRoom).
Player downloads: [CurseForge](https://www.curseforge.com/wow/addons/knomercy-war-room).

## Sentinel

KWR Sentinel is the compact player execution client for Knomercy War Room. It
shows commander trust, match state, personal job, movement authority, target
responsibility, and one hold/win instruction without automating gameplay.

The `6.1.0-alpha.43` field-test copy applies to the optional Sentinel companion.
It can receive Commander `KWRSync1` relays from another team member or work as
a safe standalone fallback when no Commander relay is available.

Official source and release history: [GitHub](https://github.com/josevargas6/KnomercyWarRoom/tree/main/KWRSentinel).
Player downloads: [CurseForge](https://www.curseforge.com/wow/addons/kwr-sentinel).

## Support and testing

Use the repository issue templates for reproducible bugs, diagnostics, field
tests, and feature requests. Remove personal identifiers, account details,
tokens, webhook URLs, and private Discord content before submitting evidence.
Alpha releases require live Retail field validation before stable promotion.
