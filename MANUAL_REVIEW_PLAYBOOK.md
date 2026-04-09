# MANUAL_REVIEW_PLAYBOOK

Manual review is represented in the schema (`manual_review_cases`, `identity_conflict_records`, `audit_events`) and in orchestrator routing (`reviewRequired` flag).

## Trigger scenarios

- missing policy-required validation domains
- missing required biometric evidence
- validation result is `pending_review` or `rejected`
- field-level conflict (`mismatch`)

## Reviewer procedure

1. Inspect linked evidence artifacts.
2. Compare field-level results across domains.
3. Verify cross-document and biometric consistency.
4. Mark decision (`approve`, `reject`, `escalate`).
5. Record justification in `manual_review_cases.resolution`.
6. Emit immutable `audit_events` entry.

## Resolution outcomes

- profile can advance assurance level
- profile can remain restricted
- profile can request additional evidence
- profile can be suspended for fraud indicators
