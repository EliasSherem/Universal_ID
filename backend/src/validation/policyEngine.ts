import { ValidationDomain, ValidationPolicy, ValidationRequest } from '../types/validation';

const onboardingPolicy: ValidationPolicy = {
  name: 'mexico_onboarding_policy',
  requiredDomains: ['CURP'],
  requiresBiometrics: true,
  minimumLevelForValidated: 'government_validated',
};

const highAssurancePolicy: ValidationPolicy = {
  name: 'mexico_high_assurance_policy',
  requiredDomains: ['CURP', 'RFC', 'INE'],
  requiresBiometrics: true,
  minimumLevelForValidated: 'high_assurance_government_linked',
};

export function getPolicy(policyName?: string): ValidationPolicy {
  if (policyName === 'high_assurance') {
    return highAssurancePolicy;
  }

  return onboardingPolicy;
}

export function policyRequiresManualReview(
  request: ValidationRequest,
  validatedDomains: ValidationDomain[],
  policyName?: string,
): boolean {
  const policy = getPolicy(policyName);

  const requiredMissing = policy.requiredDomains.some((domain) => !validatedDomains.includes(domain));
  const missingBiometric = policy.requiresBiometrics && !request.biometricEvidence?.livenessRef;

  return requiredMissing || missingBiometric;
}
