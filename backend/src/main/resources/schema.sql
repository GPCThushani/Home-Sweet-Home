-- Additive migration for general family documents. Existing health_documents are untouched.
ALTER TABLE documents ADD COLUMN IF NOT EXISTS family_profile_id UUID;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS description VARCHAR(1000);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_name VARCHAR(255);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS content_type VARCHAR(100);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size BIGINT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_by VARCHAR(255);
CREATE INDEX IF NOT EXISTS idx_documents_family_uploaded_at ON documents (family_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_family_profile ON documents (family_id, family_profile_id);
-- family_profile_id intentionally remains nullable for shared documents and legacy metadata.
-- The controller verifies a non-null value belongs to the requested family before writing.
