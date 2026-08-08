# KWR Release Policy

GitHub is the release source of truth. Builds must originate from committed
content and protected workflows. Local WoW folders are deployment targets only.

Tuesday at 9:00 AM America/Chicago begins compatibility monitoring; it is not
an automatic release time. Wednesday is the preferred stable-release day.
Production requires validation, tests, package audit, synchronized Commander
and Sentinel metadata, checksums, protected `production` approval, and a
rollback artifact. A tag alone is not authorization to publish.

Development and local builds cannot publish to the production channel. Dirty
working trees are local builds and are never official releases.
