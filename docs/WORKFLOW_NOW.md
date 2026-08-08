# KWR automation work queue

This operational queue supplies scheduled-maintenance context only. It does
not authorize releases or define version, blocker, architecture, or product
status; those decisions belong to `RELEASE_READINESS.md` and the document
authority registry.

## Current lane

1. Certify the Alpha 36 source-recovery and governance PR.
2. Compare a verified Alpha 36 package with the live AddOns installation.
3. Collect protected-release and platform deployment evidence after approval.

## Ready to work right now

1. Review the complete KWR-047 disposition report and resolve approved items.
2. Run package-manifest verification against the installed Commander tree.
3. Record field-test evidence without promoting a release automatically.

## Recently completed

1. Alpha 36 source recovery was synchronized into draft PR #30.
2. Document-authority and source-drift audits were added to repository validation.
3. The generated Alpha 36 package passed local reproducibility and extraction checks.

## Newly discovered / still needs attention

1. PR #30 must pass its new GitHub certification run before merge.
2. The live installation must match a package manifest before deployment is certified.
3. Protected workflow secrets and external platform confirmations remain external gates.
