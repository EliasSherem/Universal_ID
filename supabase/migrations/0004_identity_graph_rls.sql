-- 0004_identity_graph_rls.sql
-- RLS expansion aligned to the full identity graph model.

-- Enable RLS on all user-owned tables
ALTER TABLE public.identity_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.government_validation_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometric_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometric_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recovery_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digital_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sharing_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_review_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.identity_conflict_records ENABLE ROW LEVEL SECURITY;

-- Core helper expression reused in policies:
-- profile belongs to auth.uid() through universal_identity_profiles.user_id

CREATE POLICY "Users can view own claims"
  ON public.identity_claims
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own verification events"
  ON public.verification_events
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own government validation events"
  ON public.government_validation_events
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own biometric profile"
  ON public.biometric_profiles
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own biometric checks"
  ON public.biometric_checks
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own auth methods"
  ON public.auth_methods
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own trusted devices"
  ON public.trusted_devices
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can manage own trusted devices"
  ON public.trusted_devices
  FOR INSERT
  WITH CHECK (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own sessions"
  ON public.sessions
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own recovery events"
  ON public.recovery_events
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own credentials"
  ON public.digital_credentials
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own consents"
  ON public.consents
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can revoke own consents"
  ON public.consents
  FOR UPDATE
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own sharing events"
  ON public.sharing_events
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own manual review cases"
  ON public.manual_review_cases
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can view own identity conflicts"
  ON public.identity_conflict_records
  FOR SELECT
  USING (universal_identity_profile_id IN (
    SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
  ));

-- Institution / governance tables are managed by backend service role.
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institution_access_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credential_presentations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.identity_merge_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_artifacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read institutions"
  ON public.institutions
  FOR SELECT
  TO authenticated
  USING (status = 'active');
