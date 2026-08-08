# KWR Icon System Import

Date: 2026-07-30  
Authority: implementation record

## Summary

The supplied `KWR_Design_System_v1.0` package was evaluated and partially adopted
into production addon paths.

Adopted runtime assets:

- brand marks under `Assets/Brand`;
- semantic and objective icon PNGs under `Assets/Icons`;
- a repo-owned registry module at `UI/IconRegistry.lua`.

Rejected from runtime packaging:

- mockups;
- source SVGs;
- design-package docs and Codex scaffolding files;
- the raw extracted package tree.

## Runtime Standard

KWR now owns a semantic icon registry with stable paths for:

- roles: tank, healer, damage;
- tactical states: kill, control, defend, hold, rotate, threat, ready, blocked;
- objective states: flag, orb, node, and cart variants;
- product branding: minimap icon, sigil, compact mark, and primary logo.

## First-Wave Surface Adoption

This import intentionally wires the icon system into the surfaces where text-only
markers were most brittle:

- minimap/launcher branding;
- combat-roster role badges;
- tactical-map markers for objectives, carriers, and combat contacts.

## Follow-On Work

Future UI work should migrate additional surfaces to the icon registry through the
existing component boundaries instead of inventing local texture paths.

Next likely candidates:

- launcher menu rows;
- main-window shell/header accents;
- badges and command-card rails;
- assignment and review surfaces.
