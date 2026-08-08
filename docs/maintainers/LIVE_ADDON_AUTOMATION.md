# Live addon automation

This is the operating contract for all future live-addon work.

GitHub committed content is the only release source. The live WoW folder is a
deployment target, never build input. A dirty checkout is `local`.

## Automation path

1. Create a Markdown task brief before material implementation.
2. Work on a dedicated branch and keep the change bounded.
3. Run validation, security and knowledge audits, deterministic tests, soak
   tests, package audits, and checksum generation.
4. Test clean and upgraded SavedVariables, in/out of combat, and relevant
   solo, party, raid, battleground, and rated states.
5. Promote only through GitHub workflows. Production publication pauses at the
   protected `production` environment.
6. Attach provenance, audit, checksum, and field-verification evidence.
7. Keep the previous approved artifact available for rollback.

## Safety boundary

Automation may package, validate, report, and deploy isolated development
artifacts. It may not automate gameplay input, protected actions, combat-locked
UI mutation, hidden data collection, or unapproved addon-message transport.
Blizzard API changes belong behind adapters. Rendering never mutates domain
state. Production secrets are environment-scoped and never used by pull
requests or local scripts.

## Channels

`local` is dirty-checkout work, `development` is isolated testing, `beta` and
`release-candidate` are approved field stages, and `production` requires a
committed tag plus protected environment approval. A tag alone is not
authorization to publish.

## Rollback and owner setup

Rollback means redeploying the last approved GitHub artifact and recording its
checksum, reason, and field verification. Repository administrators must
configure branch protection, required checks, GitHub environments, approvals,
and external secrets; this checkout cannot prove those settings exist.
