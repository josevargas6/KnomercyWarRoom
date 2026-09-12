# Local diagnostic field test — alpha12-kwr297-source-20260910-1

This is the current installed diagnostic candidate, version 6.1.1-alpha.12.
Its authoritative package is `artifacts/release-offline-candidate-20260912-r4`:
Commander SHA-256 `249A2FBD2C5AE21A5016B1C8664CE9A7CA26943D8718CE5BBD76452CE04378A4`,
Sentinel SHA-256 `92FAC40EB7AF1ADB91A4337CCB46E38C66BF41A384C96E461016BCC517FABCC7`,
and DevTools SHA-256 `5689AA5E0AFECD69C5A43DEC66EFCEA10F1DA94F9EC291B0CD32DBB1154839C4`.
`artifacts/release-offline-install-20260912-r4/DEPLOYMENT.json` confirms
zero install drift and a passed rollback rehearsal. This is diagnostic field
testing only; it does not grant offline-complete, stable-release, or publication status.

## Before queueing

1. Restart WoW after installation. Enable KnomercyWarRoom, KWRSentinel and
   KWR_DevTools. The companion loads on demand.
2. Outside combat run `/kwr field`, then `/kwr verify`. Check that the report
   says `Candidate: alpha12-kwr297-source-20260910-1`. If it does not, stop and reload.
3. If actually leading, run `/kwr commander` before entering the match. Otherwise
   retain Diagnostic context or use `/kwr spectator`.
4. `/kwr field` opts into Sentinel transport. Disable it in Commander and
   Sentinel options if conducting a Commander-only test.
5. Keep the final `DEPLOYMENT.json` receipt beside every screenshot/export.
   Its candidate ID maps to exact ZIP hashes and the verified installed files.

## During and after a match

- Check unknown scores stay UNKNOWN until the score widget and assigned side
  are available. An observed 0-0 must remain a real tie. Observe transitions.
- Exercise `/kwr override help`, team/enemy rows, native Shift-M and fixed Quick
  Calls. Watch for clipping, incorrect identities and blocked-action errors.
- After actually communicating a current call to your team, use `/kwr delivered`
  to see its token, then `/kwr delivered <token>` to attest that delivery.
  Do not confirm a call that was not communicated. Attestation is not execution
  or outcome proof.
- Capture `/kwr perf` during combat and `/kwr bug` if anything fails. Host-mock
  timings cannot substitute for this client evidence.
- After completion, save `/kwr aar copy`. Its candidate ID must match the
  deployment receipt; old AARs without a candidate ID are correctly UNBOUND.

Stop the session and preserve the bug report on any fabricated fact, wrong
secure target, Lua error, taint/blocked action or repeated stall.

## Rollback

The deployment receipt names a complete three-addon backup and records an
isolated restoration rehearsal. Exit WoW, then use `tools/restore-field-candidate.ps1`
with that exact `-BackupDirectory`. It verifies hashes before restoring files and
retains displaced extras. It does not erase new match data. Backups of KWR
SavedVariables are in the same backup directory; restore those only when needed
for data recovery, keeping the current files so tonight's evidence is not lost.
