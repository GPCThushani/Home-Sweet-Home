-- 1. USERS TABLE (Global Identity)
-- A person exists in the system before they join a family.
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. FAMILIES TABLE (The Digital Home)
-- The shared space that members will connect to.
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL, -- e.g., "The Perera Family"
    timezone VARCHAR(50) DEFAULT 'Asia/Colombo',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. FAMILY_MEMBERS TABLE (The Bridge)
-- This links a User to a Family and defines their specific role/permissions.
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- e.g., 'PARENT', 'GRANDPARENT', 'CHILD'
    nickname VARCHAR(100),     -- e.g., 'Amma', 'Dad'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, family_id) -- A user can only join the same family once
);

-- 4. GLOBAL_TASKS TABLE (Cross-Module Sync)
-- Whether it's a pet bath, a bill, or a plant to water, it lives here.
CREATE TABLE global_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    origin_module VARCHAR(50) NOT NULL, -- e.g., 'PETS', 'FINANCE', 'HEALTH'
    status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'COMPLETED'
    assigned_to UUID REFERENCES family_members(id) ON DELETE SET NULL,
    created_by UUID REFERENCES family_members(id) ON DELETE SET NULL,
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);