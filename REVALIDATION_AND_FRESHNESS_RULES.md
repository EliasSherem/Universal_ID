# REVALIDATION_AND_FRESHNESS_RULES

This document defines operational freshness rules to complement `government_validation_events.expires_at` and connector responses.

## Revalidation triggers

- document expiry reached
- high-risk recovery event
- suspicious device fingerprint change
- institution requires stronger assurance at presentation time
- major canonical profile update
- stale validation age threshold reached

## Suggested default windows

- liveness-only checks: 24 hours
- biometric + document checks: 30 days
- CURP / civil identity checks: 365 days
- RFC checks: 180 days
- e.firma cert checks: per transaction for high-risk signatures

## Enforcement points

- connector returns `expiresAt` when available
- orchestration layer flags review if required checks are stale
- policy engine can require freshness by domain for high-assurance policies
