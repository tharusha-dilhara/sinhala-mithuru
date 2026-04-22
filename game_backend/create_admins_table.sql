-- Run this SQL in your Supabase SQL Editor to create the admins table

CREATE TABLE IF NOT EXISTS admins (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name VARCHAR(255) NOT NULL DEFAULT 'Admin',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Optional: Add RLS policy (disable for now since backend accesses directly via service key)
-- ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
