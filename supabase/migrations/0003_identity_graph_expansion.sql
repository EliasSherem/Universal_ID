-- 0003_identity_graph_expansion.sql
-- Expands the initial schema into the complete Mexico-first identity graph described in
-- IDENTITY_GRAPH_SCHEMA.md and GOVERNMENT_VALIDATION_PLAN.md.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) Claims
CREATE TABLE IF NOT EXISTS public.identity_claims (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  claim_namespace text NOT NULL,
  claim_key text NOT NULL,
  claim_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  value_type text NOT NULL,
  source_type text NOT NULL,
  source_reference text,
  claim_status text NOT NULL DEFAULT 'self_claimed',
  confidence_level text NOT NULL DEFAULT 'low',
  is_canonical boolean NOT NULL DEFAULT false,
  valid_from timestamptz,
  valid_until timestamptz,
  validated_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS identity_claims_profile_key_source_unique
  ON public.identity_claims(universal_identity_profile_id, claim_namespace, claim_key, source_type);

-- 2) Generic verification events
CREATE TABLE IF NOT EXISTS public.verification_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  verification_type text NOT NULL,
  source_system text NOT NULL,
  initiated_by_type text NOT NULL,
  initiated_by_id uuid,
  result text NOT NULL,
  confidence_outcome text,
  risk_score numeric(6,4),
  event_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 3) Evidence artifacts
CREATE TABLE IF NOT EXISTS public.evidence_artifacts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  artifact_type text NOT NULL,
  storage_path text NOT NULL,
  content_hash text,
  mime_type text,
  encryption_key_reference text,
  retention_policy_key text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 4) Biometric state + checks
CREATE TABLE IF NOT EXISTS public.biometric_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL UNIQUE REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  biometric_status text NOT NULL DEFAULT 'not_enrolled',
  face_template_reference text,
  last_strong_match_at timestamptz,
  spoof_risk_level text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.biometric_checks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  check_type text NOT NULL,
  vendor_name text,
  liveness_result text,
  face_match_score numeric(6,4),
  spoof_signals jsonb NOT NULL DEFAULT '{}'::jsonb,
  result text NOT NULL,
  evidence_artifact_id uuid REFERENCES public.evidence_artifacts(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 5) Authentication + trusted devices + sessions + recovery events
CREATE TABLE IF NOT EXISTS public.auth_methods (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  method_type text NOT NULL,
  method_reference text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  assurance_contribution text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.trusted_devices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  device_fingerprint_hash text NOT NULL,
  platform text,
  device_name text,
  attestation_level text,
  status text NOT NULL DEFAULT 'active',
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS trusted_devices_profile_fingerprint_unique
  ON public.trusted_devices(universal_identity_profile_id, device_fingerprint_hash);

CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  trusted_device_id uuid REFERENCES public.trusted_devices(id) ON DELETE SET NULL,
  auth_method_id uuid REFERENCES public.auth_methods(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  terminated_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.recovery_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  initiated_by_type text NOT NULL,
  recovery_method text NOT NULL,
  result text NOT NULL,
  risk_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 6) Institutions + clients + access policies
CREATE TABLE IF NOT EXISTS public.institutions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  institution_type text NOT NULL,
  country_code text NOT NULL DEFAULT 'MX',
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.integration_clients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  client_name text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  client_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.institution_access_policies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  policy_name text NOT NULL,
  allowed_claims jsonb NOT NULL DEFAULT '[]'::jsonb,
  allowed_assurance_levels jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_step_up_auth boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 7) Credentials + presentations + consent + sharing
CREATE TABLE IF NOT EXISTS public.digital_credentials (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  credential_type text NOT NULL,
  issuer text NOT NULL,
  format text NOT NULL,
  credential_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'active',
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.credential_presentations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  digital_credential_id uuid NOT NULL REFERENCES public.digital_credentials(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  requested_claims jsonb NOT NULL DEFAULT '[]'::jsonb,
  shared_claims jsonb NOT NULL DEFAULT '[]'::jsonb,
  presentation_status text NOT NULL DEFAULT 'completed',
  presented_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.consents (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  approved_claims jsonb NOT NULL DEFAULT '[]'::jsonb,
  consent_status text NOT NULL DEFAULT 'active',
  granted_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.sharing_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  sharing_type text NOT NULL,
  claims_shared jsonb NOT NULL DEFAULT '[]'::jsonb,
  credential_ids_shared jsonb NOT NULL DEFAULT '[]'::jsonb,
  consent_id uuid REFERENCES public.consents(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 8) Governance tables: reviews/conflicts/merge/audit
CREATE TABLE IF NOT EXISTS public.manual_review_cases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  case_type text NOT NULL,
  case_reason text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  assigned_to uuid,
  resolution text,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.identity_conflict_records (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  conflict_type text NOT NULL,
  field_name text,
  observed_values jsonb NOT NULL DEFAULT '[]'::jsonb,
  severity text NOT NULL DEFAULT 'medium',
  status text NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.identity_merge_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE RESTRICT,
  target_profile_id uuid NOT NULL REFERENCES public.universal_identity_profiles(id) ON DELETE RESTRICT,
  merge_reason text NOT NULL,
  merge_strategy text NOT NULL,
  approved_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_type text NOT NULL,
  actor_id uuid,
  entity_type text NOT NULL,
  entity_id uuid,
  event_type text NOT NULL,
  event_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_hash text,
  device_context jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 9) Defaults + schema hardening for existing tables
ALTER TABLE public.linked_documents
  ALTER COLUMN extracted_data SET DEFAULT '{}'::jsonb,
  ALTER COLUMN fraud_flags SET DEFAULT '[]'::jsonb;

ALTER TABLE public.government_validation_events
  ALTER COLUMN validated_fields SET DEFAULT '[]'::jsonb,
  ALTER COLUMN field_level_results SET DEFAULT '{}'::jsonb,
  ALTER COLUMN government_system_name SET DEFAULT 'unknown';

CREATE INDEX IF NOT EXISTS verification_events_profile_idx
  ON public.verification_events(universal_identity_profile_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS government_validation_events_profile_idx
  ON public.government_validation_events(universal_identity_profile_id, validated_at DESC);

CREATE INDEX IF NOT EXISTS audit_events_entity_idx
  ON public.audit_events(entity_type, entity_id, created_at DESC);
