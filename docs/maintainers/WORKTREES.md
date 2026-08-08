# Worktrees

Keep production maintenance and experiments physically separate when Git
metadata is available:

```powershell
git worktree add ..\kwr-production main
git worktree add ..\kwr-development develop
git worktree add ..\kwr-experiment experiment\short-name
```

Deploy development and sandbox artifacts to distinct AddOns directories. Do
not point an experimental deployment at `KnomercyWarRoom` or `KWRSentinel`.
