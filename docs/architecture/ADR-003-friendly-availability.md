# ADR-003: Preserve unknown friendly availability

Status: Accepted, September 6, 2026

Group membership identifies an actor; it does not prove their connection, death
state or visibility. Sensors and BoardState preserve optional booleans for those
fields. Public false is distinct from missing, invalid or protected data.

Util:OptionalBoolean returns only a public boolean or nil. Util:Boolean retains
its existing defaulting contract for callers whose product behavior needs it.
FriendlyRoleState owns the availability derivation: known dead or offline means
unavailable; explicit alive and connected means available; otherwise unknown.
Unknown roles get no damage-role base profile and cannot score an executable
local control assignment. These are necessary conditions, not proof of range,
control capability, objective coverage or cooldown readiness.

This changes transient state only. No persisted schema changes. Roster identities
remain present during hydration; legal later observations restore eligibility.
Subsequent typed-fact work must retain these distinctions and add field age and
authority rather than reintroduce boolean defaults.
