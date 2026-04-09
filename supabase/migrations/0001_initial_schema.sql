-- 0001_initial_schema.sql
-- Core Identity Graph Tables for Universal ID MX

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. universal_identity_profiles
CREATE TABLE IF NOT EXISTS public.universal_identity_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid UNIQUE NOT NULL, -- references auth.users in Supabase
  country_code text DEFAULT 'MX',
  canonical_full_name text,
  canonical_given_names text,
  canonical_paternal_surname text,
  canonical_maternal_surname text,
  canonical_date_of_birth date,
  canonical_place_of_birth text,
  canonical_nationality text,
  canonical_sex_marker text,
  primary_curp text,
  primary_rfc text,
  primary_nss text,
  assurance_level text DEFAULT 'IAL0',
  identity_status text DEFAULT 'draft',
  graph_confidence_score numeric DEFAULT 0,
  last_government_validated_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. linked_identifiers
CREATE TABLE IF NOT EXISTS public.linked_identifiers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  identifier_type text NOT NULL,
  identifier_value text NOT NULL,
  issuing_country_code text DEFAULT 'MX',
  issuing_authority text,
  source_type text,
  source_reference text,
  verification_status text DEFAULT 'unverified',
  confidence_level text DEFAULT 'low',
  is_primary boolean DEFAULT false,
  last_validated_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3. linked_documents
CREATE TABLE IF NOT EXISTS public.linked_documents (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  document_number text,
  issuing_country_code text DEFAULT 'MX',
  issuing_authority text,
  document_version text,
  raw_front_storage_path text,
  raw_back_storage_path text,
  extracted_data jsonb,
  document_hash text,
  verification_status text DEFAULT 'unverified',
  fraud_flags jsonb,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. government_validation_events
CREATE TABLE IF NOT EXISTS public.government_validation_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  universal_identity_profile_id uuid REFERENCES public.universal_identity_profiles(id) ON DELETE CASCADE,
  validation_domain text NOT NULL,
  government_system_name text,
  government_system_reference text,
  request_payload_hash text,
  response_payload_hash text,
  validated_fields jsonb,
  validation_result text,
  field_level_results jsonb,
  validated_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Note: We are creating a subset of the tables for the initial environment MVP.
