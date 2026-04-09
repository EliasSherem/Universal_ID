import {
  GovernmentValidationConnector,
  ValidationDomain,
  ValidationRequest,
  ValidationResult,
} from '../../types/validation';

export abstract class BaseConnector implements GovernmentValidationConnector {
  public readonly name: string;
  public readonly domain: ValidationDomain;
  public readonly countryCode: string;

  protected constructor(name: string, domain: ValidationDomain, countryCode = 'MX') {
    this.name = name;
    this.domain = domain;
    this.countryCode = countryCode;
  }

  supports(input: ValidationRequest): boolean {
    return input.domain === this.domain;
  }

  abstract validate(input: ValidationRequest): Promise<ValidationResult>;

  async healthCheck(): Promise<boolean> {
    return true;
  }

  protected nowIso(): string {
    return new Date().toISOString();
  }
}
