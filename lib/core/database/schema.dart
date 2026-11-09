import 'enums.dart';

/// SQL DDL for the sqflite database. Translated from the former Drift tables.
/// Enum columns store `Enum.name`; booleans are INTEGER 0/1; dates are
/// INTEGER milliseconds since epoch (UTC for `*_utc`).

final profilesTable =
    '''
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  relation TEXT,
  date_of_birth INTEGER,
  role TEXT NOT NULL CHECK (role IN (${_names(ProfileRole.values)})),
  color_value INTEGER NOT NULL,
  avatar_emoji TEXT,
  is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

final medicinesTable =
    '''
CREATE TABLE medicines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL REFERENCES profiles (id),
  name TEXT NOT NULL,
  medicine_type TEXT NOT NULL CHECK (medicine_type IN (${_names(MedicineType.values)})),
  dose_amount REAL NOT NULL,
  dose_unit TEXT NOT NULL,
  dose_label TEXT NOT NULL,
  intake_timing TEXT NOT NULL CHECK (intake_timing IN (${_names(IntakeTiming.values)})),
  notes TEXT,
  photo_path TEXT,
  voice_note_path TEXT,
  total_quantity REAL,
  current_quantity REAL CHECK (current_quantity IS NULL OR current_quantity >= 0),
  refill_remind_days INTEGER,
  last_refill_date INTEGER,
  state TEXT NOT NULL CHECK (state IN (${_names(MedicineState.values)})),
  stop_reason TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

const schedulesTable = '''
CREATE TABLE schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicine_id INTEGER NOT NULL REFERENCES medicines (id) ON DELETE CASCADE,
  time_of_day_seconds INTEGER NOT NULL CHECK (time_of_day_seconds BETWEEN 0 AND 86399),
  weekdays_mask INTEGER NOT NULL DEFAULT 127 CHECK (weekdays_mask BETWEEN 1 AND 127),
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  notify INTEGER NOT NULL DEFAULT 1 CHECK (notify IN (0, 1)),
  missed_window_minutes INTEGER NOT NULL DEFAULT 60 CHECK (missed_window_minutes > 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);
''';

final occurrencesTable =
    '''
CREATE TABLE occurrences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL REFERENCES profiles (id),
  medicine_id INTEGER NOT NULL REFERENCES medicines (id),
  schedule_id INTEGER NOT NULL REFERENCES schedules (id),
  scheduled_at_utc INTEGER NOT NULL,
  local_date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (${_names(OccurrenceStatus.values)})),
  taken_at_utc INTEGER,
  snoozed_until_utc INTEGER,
  skip_reason TEXT,
  actor_profile_id INTEGER NOT NULL REFERENCES profiles (id),
  dose_snapshot_amount REAL NOT NULL,
  dose_snapshot_unit TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (schedule_id, scheduled_at_utc),
  CHECK ((status = 'taken') = (taken_at_utc IS NOT NULL))
);
''';

final achievementsTable =
    '''
CREATE TABLE achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL REFERENCES profiles (id),
  type TEXT NOT NULL CHECK (type IN (${_names(AchievementType.values)})),
  progress INTEGER NOT NULL DEFAULT 0,
  unlocked_at_utc INTEGER,
  UNIQUE (profile_id, type)
);
''';

final settingsTable =
    '''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  value_type TEXT NOT NULL CHECK (value_type IN (${_names(SettingType.values)}))
);
''';

final installationMetadataTable =
    '''
CREATE TABLE installation_metadata (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  installation_id TEXT NOT NULL,
  lifecycle TEXT NOT NULL CHECK (lifecycle IN (${_names(LifecycleState.values)})),
  created_at_utc INTEGER NOT NULL
);
''';

/// Occurrence guards: a row's profile and schedule must match its medicine
/// and schedule. Same behavior as the former Drift triggers.
const _occurrenceGuardWhen = '''
WHEN NEW.profile_id IS NOT (SELECT profile_id FROM medicines WHERE id = NEW.medicine_id)
  OR NEW.medicine_id IS NOT (SELECT medicine_id FROM schedules WHERE id = NEW.schedule_id)
''';

const occurrencesGuardInsertTrigger =
    '''
CREATE TRIGGER occurrences_guard_insert
BEFORE INSERT ON occurrences
$_occurrenceGuardWhen
BEGIN
  SELECT RAISE(ABORT, 'occurrence profile or schedule does not match medicine');
END;
''';

const occurrencesGuardUpdateTrigger =
    '''
CREATE TRIGGER occurrences_guard_update
BEFORE UPDATE OF profile_id, medicine_id, schedule_id ON occurrences
$_occurrenceGuardWhen
BEGIN
  SELECT RAISE(ABORT, 'occurrence profile or schedule does not match medicine');
END;
''';

/// Statements executed in order on first create.
final schemaStatements = [
  profilesTable,
  medicinesTable,
  schedulesTable,
  occurrencesTable,
  achievementsTable,
  settingsTable,
  installationMetadataTable,
  occurrencesGuardInsertTrigger,
  occurrencesGuardUpdateTrigger,
];

String _names(List<Enum> values) => values.map((v) => "'${v.name}'").join(', ');
