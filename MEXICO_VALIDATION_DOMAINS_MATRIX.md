# MEXICO_VALIDATION_DOMAINS_MATRIX

| Domain | Inputs | Current Implementation | Result Strength |
|---|---|---|---|
| CURP | CURP string + claimed data | Mock connector with format parsing and deterministic checks | Authorized partner (IAL2 eligible when corroborated) |
| INE | Document refs + selfie + liveness | Mock document+biometric connector | Document plus biometrics (IAL1 eligible) |
| PASSPORT | Document refs + selfie + liveness | Mock document+biometric connector | Document plus biometrics (IAL1 eligible) |
| RFC | RFC string + claimed data | Mock connector with structural validation | Authorized partner partial match |
| NSS | Claimed NSS + profile data | Planned via connector pattern | Pending |
| EFIRMA | Certificate refs + profile data | Planned via connector pattern | Pending |
| BIRTH_CERTIFICATE | Acta inputs + document evidence | Planned via connector pattern | Pending |
| MIGRATION_STATUS | Residence doc + passport linkage | Planned via connector pattern | Pending |

## Notes

- The orchestration interface already supports all planned domains.
- Additional domains are implemented by adding connectors that satisfy `GovernmentValidationConnector`.
