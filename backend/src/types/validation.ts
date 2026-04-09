export type ValidationDomain =
  | 'CURP'
  | 'BIRTH_CERTIFICATE'
  | 'INE'
  | 'PASSPORT'
  | 'RFC'
  | 'NSS'
  | 'EFIRMA'
  | 'MIGRATION_STATUS';

export type ValidationOverallResult =
  | 'verified'
  | 'partial_match'
  | 'pending_review'
  | 'rejected'
  | 'unavailable';

export type FieldResultStatus = 'verified' | 'mismatch' | 'not_found' | 'not_checked';
export type ConfidenceLevel = 'low' | 'medium' | 'high';

export type ValidationMethodTier =
  | 'self_claimed'
  | 'document_observed'
  | 'document_plus_biometrics'
  | 'authorized_partner'
  | 'direct_government'
  | 'high_assurance_government_linked';

export type SourceType = 'direct_government' | 'authorized_partner' | 'document_plus_biometrics';

export interface ValidationRequest {
  profileId: string;
  domain: ValidationDomain;
  claimedData: Record<string, unknown>;
  linkedDocuments?: Array<{
    documentType: string;
    fileRef: string;
  }>;
  biometricEvidence?: {
    selfieRef?: string;
    livenessRef?: string;
  };
}

export interface FieldResult {
  field: string;
  result: FieldResultStatus;
  confidence: ConfidenceLevel;
}

export interface ValidationResult {
  domain: ValidationDomain;
  overallResult: ValidationOverallResult;
  fieldResults: FieldResult[];
  sourceType: SourceType;
  sourceName: string;
  evidenceRefs: string[];
  validatedAt: string;
  expiresAt?: string;
}

export interface GovernmentValidationConnector {
  name: string;
  domain: ValidationDomain;
  countryCode: string;
  supports(input: ValidationRequest): boolean;
  validate(input: ValidationRequest): Promise<ValidationResult>;
  healthCheck(): Promise<boolean>;
}

export interface ValidationPolicy {
  name: string;
  requiredDomains: ValidationDomain[];
  requiresBiometrics: boolean;
  minimumLevelForValidated: ValidationMethodTier;
}

export interface TrustDecision {
  methodTier: ValidationMethodTier;
  confidenceLevel: ConfidenceLevel;
  status: 'self_claimed' | 'observed' | 'verified' | 'derived_verified' | 'conflicted' | 'rejected';
}

export interface OrchestratedValidationResponse {
  request: ValidationRequest;
  result: ValidationResult;
  trust: {
    overall: TrustDecision;
    fieldTrust: Array<TrustDecision & { field: string }>;
  };
  assuranceOutcome: 'IAL0' | 'IAL1' | 'IAL2' | 'IAL3' | 'high_assurance_custom';
  reviewRequired: boolean;
}
