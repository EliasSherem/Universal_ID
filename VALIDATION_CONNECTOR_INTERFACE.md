# VALIDATION_CONNECTOR_INTERFACE

This document codifies the connector contract implemented in `backend/src/types/validation.ts` and `backend/src/validation/connectors/*`.

## Connector contract

```ts
export interface GovernmentValidationConnector {
  name: string;
  domain: ValidationDomain;
  countryCode: string;
  supports(input: ValidationRequest): boolean;
  validate(input: ValidationRequest): Promise<ValidationResult>;
  healthCheck(): Promise<boolean>;
}
```

## Normalized request and result

- `ValidationRequest` provides profile context, claimed data, optional linked documents, and biometric evidence.
- `ValidationResult` enforces field-level outcomes, evidence references, source typing, and freshness timestamps.

## Current Mexico mock connectors

- `CurpConnector`
- `RfcConnector`
- `BiometricDocumentConnector` for `INE`
- `BiometricDocumentConnector` for `PASSPORT`

## Orchestration behavior

The orchestrator:
1. Resolves connector by `domain`.
2. Executes connector validation.
3. Evaluates field-level trust.
4. Applies policy checks and review routing.
