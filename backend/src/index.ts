import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import { getMexicoConnectors } from './validation/connectors/mockMexicoConnectors';
import { GovernmentValidationOrchestrator } from './validation/orchestrator';
import { ValidationRequest } from './types/validation';

dotenv.config();

const app = express();
const port = Number(process.env.PORT ?? 8080);
const orchestrator = new GovernmentValidationOrchestrator(getMexicoConnectors());

app.use(cors());
app.use(express.json());

app.get('/health', async (_req, res) => {
  const health = await orchestrator.health();
  res.status(200).json({
    status: health.healthy ? 'ok' : 'degraded',
    service: 'government-validation-orchestrator',
    connectors: health.connectors,
  });
});

app.get('/api/connectors/health', async (_req, res) => {
  const health = await orchestrator.health();
  res.status(200).json(health);
});

app.post('/api/validate', async (req, res) => {
  const body = req.body as Partial<ValidationRequest> & { policyName?: string };

  if (!body.profileId || !body.domain || typeof body.claimedData !== 'object') {
    return res.status(400).json({
      error: 'Missing required fields: profileId, domain, and claimedData are required.',
    });
  }

  try {
    const result = await orchestrator.validate(
      {
        profileId: body.profileId,
        domain: body.domain,
        claimedData: body.claimedData,
        linkedDocuments: body.linkedDocuments,
        biometricEvidence: body.biometricEvidence,
      },
      body.policyName,
    );

    return res.status(200).json({ success: true, ...result });
  } catch (error) {
    return res.status(400).json({
      success: false,
      error: error instanceof Error ? error.message : 'Validation failed unexpectedly',
    });
  }
});

app.post('/api/validate/curp', async (req, res) => {
  const { curp, profileId = 'anonymous-profile' } = req.body as { curp?: string; profileId?: string };

  if (!curp || typeof curp !== 'string') {
    return res.status(400).json({ error: 'Missing or invalid CURP' });
  }

  const response = await orchestrator.validate({
    profileId,
    domain: 'CURP',
    claimedData: { curp },
  });

  return res.status(200).json({ success: true, ...response });
});

app.listen(port, () => {
  console.log(`Backend Orchestrator listening on port ${port}`);
});
