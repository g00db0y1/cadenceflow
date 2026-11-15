# CadenceFlow — Eisenhower Priority, 5-Tier Cadence Goals & Persistent Reminders

**CadenceFlow** is an offline-first, cloud-synced **Flutter (Material 3)** productivity application engineered for reliable daily execution on Android phones like the **itel Power 70** (as well as Web/Desktop), backed by **Supabase (PostgreSQL + Realtime + Row Level Security)** and **Clerk Auth**.

---

## ✨ Core Features

1. **Eisenhower Matrix Prioritization (`Today & Matrix` Tab)**:
   - Organizes daily work across four semantic quadrants:
     - **Q1 • Do First** (`#E11D48` Coral Red — *Urgent & Important*)
     - **Q2 • Schedule** (`#0D9488` Deep Teal — *Not Urgent & Important*)
     - **Q3 • Quick Handle** (`#D97706` Warm Amber — *Urgent & Not Important*)
     - **Q4 • Defer** (`#64748B` Cool Slate — *Not Urgent & Not Important*)
   - Toggle instantaneously between an interactive **2×2 Matrix Grid** and a **Ranked Priority Queue** (`Q1 → Q2 → Q3 → Q4`), complete with a live **Today Completion Ring** and Undo snackbars.

2. **Hybrid 5-Tier Recurring Cadence Engine (`Cadences` Tab)**:
   - Supports five explicit horizons: **Daily (1d)**, **Bi-Daily (2d)**, **Weekly (7d)**, **Bi-Weekly (14d)**, and **Monthly**.
   - **Hybrid Rollover Logic (`CadenceCalculator`)**:
     - *Interval Cadences (`DAILY`, `BI_DAILY`)* advance relative to the **completion date** when completed late so overdue items never pile up back-to-back.
     - *Calendar Anchor Cadences (`WEEKLY`, `BI_WEEKLY`, `MONTHLY`)* preserve their exact **weekday or day-of-month anchor** (safely clamping 29th–31st across shorter months).

3. **Social-Media-Style Persistent Appointment Reminders (`Alerts` Tab)**:
   - High-priority heads-up notifications (`Importance.max` / `Priority.high`), unread badge counters, repeating follow-up escalation pings (every 5, 10, or 15 minutes until acknowledged), and inline **Done ✓ / Snooze 10m / Got It** buttons directly inside the Android notification shade.
   - **100% Offline Alarm Mirror (`LocalStorageMirror`)**: Mirrors tasks, cadence goals, and appointments locally on-device so `BOOT_COMPLETED` reboot recovery and background notification action isolates (`@pragma('vm:entry-point')`) work instantaneously without network connectivity.

---

## 🔐 Connecting Your Clerk Auth & Supabase Keys (Replacing Placeholders)

By default, [lib/config/app_config.dart](lib/config/app_config.dart) ships with safe placeholder values and boots into **Offline-First Local Mirror Mode** so you can run and test every screen immediately without external setup.

When you are ready to connect your live **Clerk** and **Supabase** projects:

### Step 1: Apply the Supabase SQL Migration & RLS Policies
1. Open your Supabase project dashboard and go to **Authentication → Third-Party Auth → Add Integration → Clerk**.
2. Paste your Clerk Frontend API domain (e.g., `your-instance.clerk.accounts.dev`).
3. Open the **SQL Editor** in Supabase and run [`supabase/migrations/001_initial_schema.sql`](supabase/migrations/001_initial_schema.sql).
   - This creates `public.tasks`, `public.cadence_goals`, and `public.appointments` with zero-trust Row Level Security (`(SELECT auth.jwt() ->> 'sub') = user_id`) and enables Supabase Realtime.

### Step 2: Run or Build with `--dart-define`
Pass your keys via `--dart-define` when running or building the APK:

```bash
flutter run \
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_YOUR_CLERK_KEY \
  --dart-define=CLERK_FRONTEND_API=https://your-instance.clerk.accounts.dev \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
```

---

## 📦 Automated GitHub Actions CI & Android APK Build

Every push to `main` triggers [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml), which:
1. Runs `flutter analyze` and `flutter test`
2. Builds a downloadable Android APK (`cadenceflow-android-debug-apk`) ready to install on your **itel Power 70** or any Android device.
