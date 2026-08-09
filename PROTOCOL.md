# KWR Protocol Policy

This is the sole authority for addon communication restrictions.

KWR authorizes only the reviewed `KWRSync1` Commander/Sentinel addon-message
transport. It is limited to `Runtime/CommanderComm.lua` and
`KWRSentinel/Comm.lua`, the `INSTANCE_CHAT`, `RAID`, and test `PARTY`
distributions, and the versioned envelope defined in
`SENTINEL_TRANSPORT_SPEC.md`.

No other prefix, payload schema, communication API owner, visible-chat
fallback, or protected action may be introduced. The validator enforces this
boundary; malformed input, sender/session validation, rate limits, expiry,
and live safety proof remain mandatory.
