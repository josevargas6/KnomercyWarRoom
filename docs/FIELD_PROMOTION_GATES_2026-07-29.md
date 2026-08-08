# KWR Field Promotion Gates

These gates decide whether `6.1.0-alpha.29` can move from offline-prepared to
field-certified.

## Gate group A - package truth

- exact hashed distribution zip installed
- clean-state and upgrade-state both behave
- evidence is tied to the exact candidate hash

## Gate group B - safety truth

- zero Lua errors
- zero taint / blocked-action failures
- zero fabricated facts
- zero protected-assignment violations
- zero required reload cases

## Gate group C - lifecycle truth

- clean queue entry
- clean battleground entry
- clean combat transitions
- clean death / rez / regroup handling
- clean match-end cleanup
- clean instance exit

## Gate group D - performance truth

- live refresh stays within the defined field budgets
- memory growth remains within the defined field budgets
- no meaningful FPS drag from KWR surfaces

## Gate group E - decision truth

- current and next call remain readable
- map objective path remains coherent through state changes
- low-truth states fail closed
- reviewed and adversarial discipline stay aligned with live behavior
- AAR and visible match result agree

## Promotion rule

No promotion if any P0 or P1 field defect is open.

No promotion if any live-required gate lacks evidence.

No promotion if evidence belongs to an older package hash.
