# Feature flags

Incomplete strategy behavior must default off in production and remain visible
in diagnostics. Flags do not replace branch and package isolation. Remove a
flag after its behavior becomes stable and covered by deterministic tests.
