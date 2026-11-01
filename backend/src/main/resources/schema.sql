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

-- Pet care records. Existing pets and other application tables are untouched.
CREATE TABLE IF NOT EXISTS pet_entries (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES families(id),
    pet_id UUID NOT NULL REFERENCES pets(id),
    kind VARCHAR(32) NOT NULL,
    title VARCHAR(255) NOT NULL,
    record_type VARCHAR(32),
    record_date DATE,
    next_due_date DATE,
    appointment_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(32),
    description VARCHAR(2000),
    diagnosis_treatment VARCHAR(2000),
    veterinarian VARCHAR(255),
    clinic VARCHAR(255),
    notes VARCHAR(2000),
    dosage VARCHAR(255),
    frequency VARCHAR(255),
    start_date DATE,
    end_date DATE,
    instructions VARCHAR(2000),
    weight_kg DOUBLE PRECISION,
    assigned_member_id UUID REFERENCES family_members(id),
    reminder_task BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_pet_entries_pet_kind_date ON pet_entries(pet_id, kind, record_date DESC);
ALTER TABLE pet_entries ADD COLUMN IF NOT EXISTS record_type VARCHAR(32);

CREATE TABLE IF NOT EXISTS pet_care_schedules (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES families(id),
    pet_id UUID NOT NULL REFERENCES pets(id),
    activity_name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    frequency VARCHAR(32) NOT NULL,
    weekdays VARCHAR(32),
    scheduled_time TIME NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    assigned_member_id UUID REFERENCES family_members(id),
    created_by_member_id UUID REFERENCES family_members(id),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    auto_tasks BOOLEAN NOT NULL DEFAULT FALSE,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_pet_care_schedules_pet ON pet_care_schedules(pet_id, deleted);
CREATE INDEX IF NOT EXISTS idx_pet_care_schedules_active ON pet_care_schedules(active, auto_tasks, deleted);

CREATE TABLE IF NOT EXISTS pet_care_instructions (
    pet_id UUID PRIMARY KEY REFERENCES pets(id),
    family_id UUID NOT NULL REFERENCES families(id),
    food_type VARCHAR(255),
    food_brand VARCHAR(255),
    portion_size VARCHAR(255),
    feeding_instructions VARCHAR(2000),
    dietary_notes VARCHAR(2000),
    exercise_instructions VARCHAR(2000),
    walking_minutes INTEGER,
    grooming_instructions VARCHAR(2000),
    bathing_instructions VARCHAR(2000),
    general_instructions VARCHAR(2000),
    handling_instructions VARCHAR(2000)
);

CREATE TABLE IF NOT EXISTS pet_documents (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES families(id),
    pet_id UUID NOT NULL REFERENCES pets(id),
    title VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_pet_documents_pet_uploaded ON pet_documents(pet_id, uploaded_at DESC);

ALTER TABLE global_tasks ADD COLUMN IF NOT EXISTS source_pet_id UUID;
ALTER TABLE global_tasks ADD COLUMN IF NOT EXISTS source_care_schedule_id UUID;
ALTER TABLE global_tasks ADD COLUMN IF NOT EXISTS source_pet_entry_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_schedule_task_occurrence
    ON global_tasks(source_care_schedule_id, due_date)
    WHERE source_care_schedule_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_global_tasks_pet_completion ON global_tasks(source_pet_id, status, completed_at DESC);
