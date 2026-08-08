# Development to production

1. Commit intended work on `feature/*`, `experiment/*`, `prototype/*`, or
   `fix/*`.
2. Run `tools/kwr.ps1 validate -Channel development` and the normal test gate.
3. Regenerate and audit packages through GitHub Actions.
4. Open a pull request into `develop` and obtain required review.
5. Promote through an approved beta/release-candidate workflow.
6. Confirm compatibility, package contents, checksums, and owner approval.
7. Let the protected production workflow create the tag, then pause for the
   `production` environment approval before release and external distribution.

Never copy a local WoW AddOns folder into the repository or publish a local,
dirty, development, or beta artifact as production.
