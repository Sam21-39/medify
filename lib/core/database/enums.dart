// Stored by name via Drift textEnum. Never reorder-sensitive: rename = data change.

enum ProfileRole { patient, caregiver }

enum MedicineType {
  tablet,
  capsule,
  syrup,
  drops,
  injection,
  inhaler,
  ointment,
  patch,
  other,
}

enum IntakeTiming {
  beforeFood,
  afterFood,
  withFood,
  empty,
  anytime,
  beforeSleep,
}

enum MedicineState { active, paused, finished }

enum OccurrenceStatus { scheduled, taken, skipped, missed }

enum AchievementType {
  firstWeek,
  twoWeeks,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  perfectWeek,
  perfectMonth,
  century,
  fiveHundred,
  thousand,
  earlyBird,
  superEarly,
  neverMiss,
  organized,
  firstDose,
  weekendWarrior,
  nightOwl,
  morningPerson,
}

enum SettingType { bool, int, string, enumName }

enum LifecycleState { fresh, v2Created, complete }
