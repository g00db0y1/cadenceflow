-- ==============================================================================
-- CadenceFlow — Supabase PostgreSQL Schema & Clerk Third-Party Auth RLS
-- ==============================================================================
-- Prerequisites in Supabase Dashboard:
--   1. Go to Authentication -> Third-Party Auth -> Add Integration -> Clerk.
--   2. Enter your Clerk Domain (e.g., your-instance.clerk.accounts.dev).
--   3. Run this migration in the Supabase SQL Editor or via `supabase db push`.
-- ==============================================================================

-- 1. Automatic updated_at timestamp trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ==============================================================================
-- 2. Table: public.tasks (Eisenhower Matrix Tasks)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 240),
  notes TEXT NOT NULL DEFAULT '' CHECK (char_length(notes) <= 2000),
  quadrant TEXT NOT NULL CHECK (quadrant IN ('DO_FIRST', 'SCHEDULE', 'QUICK_HANDLE', 'DEFER')),
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  due_at_millis BIGINT,
  reminder_at_millis BIGINT,
  is_persistent_alert BOOLEAN NOT NULL DEFAULT FALSE,
  snooze_count INTEGER NOT NULL DEFAULT 0 CHECK (snooze_count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_quadrant
  ON public.tasks (user_id, is_completed, quadrant, due_at_millis);

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 3. Table: public.cadence_goals (5-Tier Recurring Cadence Goals)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.cadence_goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 240),
  notes TEXT NOT NULL DEFAULT '' CHECK (char_length(notes) <= 2000),
  cadence TEXT NOT NULL CHECK (cadence IN ('DAILY', 'BI_DAILY', 'WEEKLY', 'BI_WEEKLY', 'MONTHLY')),
  quadrant TEXT NOT NULL CHECK (quadrant IN ('DO_FIRST', 'SCHEDULE', 'QUICK_HANDLE', 'DEFER')),
  next_due_at_millis BIGINT NOT NULL,
  last_completed_at_millis BIGINT,
  streak_count INTEGER NOT NULL DEFAULT 0 CHECK (streak_count >= 0),
  reminder_hour INTEGER NOT NULL DEFAULT 9 CHECK (reminder_hour BETWEEN 0 AND 23),
  reminder_minute INTEGER NOT NULL DEFAULT 0 CHECK (reminder_minute BETWEEN 0 AND 59),
  is_persistent_alert BOOLEAN NOT NULL DEFAULT TRUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cadence_goals_user_horizon
  ON public.cadence_goals (user_id, cadence, is_active, next_due_at_millis);

DROP TRIGGER IF EXISTS trg_cadence_goals_updated_at ON public.cadence_goals;
CREATE TRIGGER trg_cadence_goals_updated_at
  BEFORE UPDATE ON public.cadence_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 4. Table: public.appointments (Persistent Social-Style Appointment Reminders)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.appointments (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 240),
  location_or_link TEXT NOT NULL DEFAULT '' CHECK (char_length(location_or_link) <= 500),
  notes TEXT NOT NULL DEFAULT '' CHECK (char_length(notes) <= 2000),
  starts_at_millis BIGINT NOT NULL,
  lead_minutes INTEGER NOT NULL DEFAULT 15 CHECK (lead_minutes >= 0 AND lead_minutes <= 10080),
  is_persistent_alert BOOLEAN NOT NULL DEFAULT TRUE,
  reping_interval_minutes INTEGER NOT NULL DEFAULT 10 CHECK (reping_interval_minutes BETWEEN 1 AND 120),
  alert_status TEXT NOT NULL DEFAULT 'SCHEDULED'
    CHECK (alert_status IN ('SCHEDULED', 'PINGING', 'SNOOZED', 'ACKNOWLEDGED', 'COMPLETED')),
  snoozed_until_millis BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appointments_user_starts
  ON public.appointments (user_id, alert_status, starts_at_millis);

DROP TRIGGER IF EXISTS trg_appointments_updated_at ON public.appointments;
CREATE TRIGGER trg_appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 5. Zero-Trust Row Level Security (RLS) Keyed by Clerk JWT `sub` Claim
-- ==============================================================================
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cadence_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Tasks Policies
DROP POLICY IF EXISTS "Users can select own tasks" ON public.tasks;
CREATE POLICY "Users can select own tasks" ON public.tasks
  FOR SELECT TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
CREATE POLICY "Users can insert own tasks" ON public.tasks
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
CREATE POLICY "Users can update own tasks" ON public.tasks
  FOR UPDATE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id)
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;
CREATE POLICY "Users can delete own tasks" ON public.tasks
  FOR DELETE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

-- Cadence Goals Policies
DROP POLICY IF EXISTS "Users can select own cadence_goals" ON public.cadence_goals;
CREATE POLICY "Users can select own cadence_goals" ON public.cadence_goals
  FOR SELECT TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can insert own cadence_goals" ON public.cadence_goals;
CREATE POLICY "Users can insert own cadence_goals" ON public.cadence_goals
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can update own cadence_goals" ON public.cadence_goals;
CREATE POLICY "Users can update own cadence_goals" ON public.cadence_goals
  FOR UPDATE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id)
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can delete own cadence_goals" ON public.cadence_goals;
CREATE POLICY "Users can delete own cadence_goals" ON public.cadence_goals
  FOR DELETE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

-- Appointments Policies
DROP POLICY IF EXISTS "Users can select own appointments" ON public.appointments;
CREATE POLICY "Users can select own appointments" ON public.appointments
  FOR SELECT TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can insert own appointments" ON public.appointments;
CREATE POLICY "Users can insert own appointments" ON public.appointments
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
CREATE POLICY "Users can update own appointments" ON public.appointments
  FOR UPDATE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id)
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') = user_id);

DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
CREATE POLICY "Users can delete own appointments" ON public.appointments
  FOR DELETE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') = user_id);

-- ==============================================================================
-- 6. Enable Supabase Realtime on All Three Tables
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.cadence_goals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
