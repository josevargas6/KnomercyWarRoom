# ADR-007: Known friendly availability is required for support proof

Status: Accepted, September 7, 2026

Local support is evidence used to open a team kill window. Group membership or
an absent `dead` field does not prove that a player is alive, connected and able
to contribute. A nearby friendly counts only with explicit public `dead=false`
and `connected=true`. A nearby unknown, dead or disconnected friendly makes the
support count unknown, so it cannot establish a numerical advantage.

Direct observed low-health and trinket evidence have their existing independent
rules. The change only withdraws support-derived commits; it preserves a local
pressure/watch target. Full location coverage, spell range and control readiness
remain separate OVR-04 work.
