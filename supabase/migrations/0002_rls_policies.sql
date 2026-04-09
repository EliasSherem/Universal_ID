-- 0002_rls_policies.sql
-- Row Level Security policies for Universal ID MX Graph

-- Enable RLS on all tables
ALTER TABLE public.universal_identity_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.linked_identifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.linked_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.government_validation_events ENABLE ROW LEVEL SECURITY;

-- 1. universal_identity_profiles policies
-- Users can only view and update their own profile
CREATE POLICY "Users can view own identity profile"
  ON public.universal_identity_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own identity profile"
  ON public.universal_identity_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Note: Updates to profile fields might be restricted to specific backend service roles, 
-- but we'll allow users to update drafts initially.
CREATE POLICY "Users can update own draft identity profile"
  ON public.universal_identity_profiles
  FOR UPDATE
  USING (auth.uid() = user_id AND identity_status = 'draft');


-- 2. linked_identifiers policies
CREATE POLICY "Users can view own identifiers"
  ON public.linked_identifiers
  FOR SELECT
  USING (
    universal_identity_profile_id IN (
      SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
    )
  );

-- Only backend service roles should be able to insert/update validated identifiers,
-- but users can insert self-claimed ones.
CREATE POLICY "Users can insert self-claimed identifiers"
  ON public.linked_identifiers
  FOR INSERT
  WITH CHECK (
    universal_identity_profile_id IN (
      SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
    )
    AND source_type = 'self_claimed'
  );


-- 3. linked_documents policies
CREATE POLICY "Users can view own documents"
  ON public.linked_documents
  FOR SELECT
  USING (
    universal_identity_profile_id IN (
      SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own documents"
  ON public.linked_documents
  FOR INSERT
  WITH CHECK (
    universal_identity_profile_id IN (
      SELECT id FROM public.universal_identity_profiles WHERE user_id = auth.uid()
    )
  );

-- Backend Service Role Policy:
-- Supabase creates a service role that bypasses RLS for the Node.js backend.
-- So we do not need explicit policies for the orchestrator to read/write records.
