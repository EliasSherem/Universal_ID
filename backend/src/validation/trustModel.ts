import {
  FieldResult,
  TrustDecision,
  ValidationMethodTier,
  ValidationResult,
} from '../types/validation';

function sourceTypeToTier(sourceType: ValidationResult['sourceType']): ValidationMethodTier {
  if (sourceType === 'direct_government') return 'direct_government';
  if (sourceType === 'authorized_partner') return 'authorized_partner';
  return 'document_plus_biometrics';
}

function statusFromField(field: FieldResult): TrustDecision['status'] {
  if (field.result === 'verified') return 'verified';
  if (field.result === 'mismatch') return 'conflicted';
  if (field.result === 'not_found') return 'observed';
  return 'observed';
}

export function calculateTrust(result: ValidationResult): {
  overall: TrustDecision;
  fieldTrust: Array<TrustDecision & { field: string }>;
  assuranceOutcome: 'IAL0' | 'IAL1' | 'IAL2' | 'IAL3' | 'high_assurance_custom';
} {
  const methodTier = sourceTypeToTier(result.sourceType);
  const fieldTrust = result.fieldResults.map((field) => ({
    field: field.field,
    methodTier,
    confidenceLevel: field.confidence,
    status: statusFromField(field),
  }));

  const hasConflict = fieldTrust.some((item) => item.status === 'conflicted');
  const verifiedCount = fieldTrust.filter((item) => item.status === 'verified').length;

  let assuranceOutcome: 'IAL0' | 'IAL1' | 'IAL2' | 'IAL3' | 'high_assurance_custom' = 'IAL0';

  if (result.sourceType === 'direct_government' && verifiedCount >= 2 && !hasConflict) {
    assuranceOutcome = 'IAL3';
  } else if (result.sourceType === 'authorized_partner' && verifiedCount >= 2 && !hasConflict) {
    assuranceOutcome = 'IAL2';
  } else if (result.sourceType === 'document_plus_biometrics' && verifiedCount >= 2 && !hasConflict) {
    assuranceOutcome = 'IAL1';
  }

  return {
    overall: {
      methodTier,
      confidenceLevel: hasConflict ? 'medium' : 'high',
      status: hasConflict ? 'conflicted' : result.overallResult === 'verified' ? 'verified' : 'observed',
    },
    fieldTrust,
    assuranceOutcome,
  };
}
