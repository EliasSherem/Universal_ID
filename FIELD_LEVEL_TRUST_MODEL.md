# FIELD_LEVEL_TRUST_MODEL

The trust model is implemented in `backend/src/validation/trustModel.ts` and aligns to the maturity hierarchy in `GOVERNMENT_VALIDATION_PLAN.md`.

## Method tiers

1. `self_claimed`
2. `document_observed`
3. `document_plus_biometrics`
4. `authorized_partner`
5. `direct_government`
6. `high_assurance_government_linked`

## Field-level status mapping

- connector field `verified` -> trust `verified`
- connector field `mismatch` -> trust `conflicted`
- connector field `not_found` -> trust `observed`
- connector field `not_checked` -> trust `observed`

## Assurance mapping

- `IAL3`: direct government + at least 2 verified fields + no conflicts
- `IAL2`: authorized partner + at least 2 verified fields + no conflicts
- `IAL1`: document+biometric + at least 2 verified fields + no conflicts
- otherwise `IAL0`

## Output shape

Each orchestration response includes:
- overall trust decision
- field trust decisions
- assurance outcome
- manual review requirement flag
