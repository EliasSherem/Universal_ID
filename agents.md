# AGENTS.md — Universal ID MX

Scope: Entire repository (web, mobile, backend, validation, identity graph)

---

## 1. Project Overview

Universal ID MX is a Mexico-first universal identity platform.

Core idea:
- One canonical identity per person
- All identifiers, documents, claims, and validations linked into a graph
- Trust is derived from validation (not user input)

Key pillars:
- Identity Graph (source of truth)
- Government Validation Layer
- Biometric + Document Verification
- Field-level trust model

Read these first:
1. IDENTITY_GRAPH_SCHEMA.md
2. GOVERNMENT_VALIDATION_PLAN.md
3. universal-id-mx-blueprint.md

---

## 2. Architecture

### High-level layers

- Frontend:
  - Web (React + Vite)
  - Mobile (Flutter)

- Backend:
  - Node.js (TypeScript)
  - Validation orchestrator
  - Policy engine
  - Trust model

- Data:
  - Supabase (Postgres)
  - Identity graph schema

### Core principle

DO NOT treat identity as flat data.

Everything must flow through:
- claims
- validation events
- canonicalization rules

---

## 3. Core Rules (CRITICAL)

1. Never overwrite identity data directly
2. Always create events (verification, validation, audit)
3. Canonical ≠ only value (history must persist)
4. Government-validated data > document > self-claimed
5. Every trust decision must be explainable

---

## 4. Identity Graph Rules

- One `universal_identity_profile` per user
- All identifiers must be stored in `linked_identifiers`
- All facts must be stored as `identity_claims`
- Validation must create:
  - verification_events
  - government_validation_events

Never:
- store raw fields without claim context
- skip confidence levels

---

## 5. Government Validation

Use connector architecture:

- CURP
- INE
- Passport
- RFC
- NSS
- e.firma

All validations must:
- return field-level results
- include confidence
- include source type
- generate audit logs

Never fake validation.

---

## 6. Code Organization

### Backend
- src/
  - validation/
    - connectors/
    - orchestrator.ts
    - policyEngine.ts
    - trustModel.ts

### Web
- React + TypeScript
- Use functional components only

### Mobile
- Flutter
- Keep logic separated from UI

---

## 7. Coding Standards

- TypeScript strict mode
- No implicit any
- Functional patterns preferred
- One responsibility per function
- No business logic in controllers

Naming:
- camelCase for variables
- PascalCase for types
- snake_case only in DB

---

## 8. Testing Rules

- Every validation flow must be testable
- Mock government connectors
- Cover:
  - success
  - mismatch
  - conflict

---

## 9. Security Rules

- Never store raw documents unencrypted
- Never log sensitive identity data
- Always hash:
  - identifiers
  - validation payloads

Biometrics:
- store references, not raw data

---

## 10. What Agents Should Do

Before coding:
- read identity graph schema
- understand validation domain

When coding:
- follow existing patterns
- reuse connectors
- create events, not direct writes

After coding:
- ensure:
  - no trust violations
  - no data overwrites
  - audit trail exists

---

## 11. What NOT to Do

❌ Do NOT:
- create flat user models
- bypass validation layer
- hardcode identity trust
- merge profiles without events
- assume data is correct

---

## 12. Future Extensions

- Multi-country support
- Cross-border identity graph
- Verifiable credentials
- Institutional integrations

Design must remain extensible.

---

## 13. Philosophy

This is NOT a CRUD app.

This is a **trust system**.

Every line of code must answer:
👉 “Can this be trusted?”