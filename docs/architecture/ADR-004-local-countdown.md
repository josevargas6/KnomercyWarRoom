# ADR-004: One deadline for explicit local execution cues

Status: Accepted, September 6, 2026

CountdownState owns a transient local timing cue, separate from Commander's
ActivePlay. An explicit leader command records ID/start/deadline against sorted
session, target, control-assignment and objective-state inputs. Refreshes only
project time; changing those inputs cancels it. Without a start, show on leader
call. GO lasts at most one second. Copied records cannot resurrect a canceled
or expired cue, and runtime reset clears it. Nothing is persisted.

This does not create a remote clock/message contract or prove battlefield
confidence. Cue identity must not be labeled canonical ActivePlay identity.
Broader OVR-05 reconciliation remains required.
