# Development environments

Use `tools/kwr.ps1 status` to inspect branch, commit, working-tree state,
channel, versions, and deployment targets.

The default safe target is `KWR_Commander_Dev` and `KWR_Sentinel_Dev` under the
WoW `Interface\AddOns` directory. Production deployment is intentionally not
provided as a default command. Local dirty builds are never publishable.

Channels are `production`, `release-candidate`, `beta`, `development`, and
`local`. A build is local whenever its working tree is dirty.

This checkout currently uses the established addon identities and SavedVariables
(`KWR_DB` and `KWR_SENTINEL_DB`). Before producing a separately loadable DEV
addon, a dedicated addon identity migration must add distinct TOCs and
SavedVariables; this policy does not silently rename live user data.
