import {
  GovernmentValidationConnector,
  OrchestratedValidationResponse,
  ValidationRequest,
} from '../types/validation';
import { policyRequiresManualReview } from './policyEngine';
import { calculateTrust } from './trustModel';

export class GovernmentValidationOrchestrator {
  constructor(private readonly connectors: GovernmentValidationConnector[]) {}

  async health() {
    const results = await Promise.all(
      this.connectors.map(async (connector) => ({
        name: connector.name,
        domain: connector.domain,
        healthy: await connector.healthCheck(),
      })),
    );

    return {
      healthy: results.every((item) => item.healthy),
      connectors: results,
    };
  }

  async validate(request: ValidationRequest, policyName?: string): Promise<OrchestratedValidationResponse> {
    const connector = this.connectors.find((candidate) => candidate.supports(request));

    if (!connector) {
      throw new Error(`No connector found for domain: ${request.domain}`);
    }

    const result = await connector.validate(request);
    const trust = calculateTrust(result);

    const reviewRequired =
      policyRequiresManualReview(request, [request.domain], policyName) ||
      result.overallResult === 'pending_review' ||
      result.overallResult === 'rejected';

    return {
      request,
      result,
      trust: {
        overall: trust.overall,
        fieldTrust: trust.fieldTrust,
      },
      assuranceOutcome: trust.assuranceOutcome,
      reviewRequired,
    };
  }
}
