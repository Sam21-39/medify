import 'package:medify/features/medicines/domain/entities/medicine.dart';

/// Medicine fields heard in a voice transcript. Null means not stated.
class MedicineDraft {
  const MedicineDraft({
    this.name,
    this.dosageAmount,
    this.unit,
    this.medicineType,
    this.reminderTimes,
    this.intakeTiming,
    this.durationDays,
    this.notes,
  });

  final String? name;
  final double? dosageAmount;
  final String? unit;
  final MedicineType? medicineType;

  /// Seconds since midnight. Default spread of [timesPerDay] over 08:00-20:00.
  final List<int>? reminderTimes;
  final MedicineIntakeTiming? intakeTiming;
  final int? durationDays;

  /// Full transcript, kept so nothing spoken is lost.
  final String? notes;
}

/// Pure, on-device, English-only parser. Never guesses: anything not stated is null.
abstract final class MedicineDraftParser {
  MedicineDraftParser._();

  // Leading "I need to take", "take", "add" before the medicine name.
  static final _lead = RegExp(
    r'^\s*(?:i\s+)?(?:(?:need|take|add)\s+)?(?:to\s+)?(?:take\s+)?',
    caseSensitive: false,
  );

  // Leading run of letter-words: the candidate medicine name.
  static final _nameRun = RegExp(
    r"^\s*([\p{L}][\p{L}\p{N}'\-]*(?:\s+[\p{L}][\p{L}\p{N}'\-]*)*)",
    unicode: true,
  );

  // Name run followed by a number: "Paracetamol 500 mg", "Paracetamol, 500mg".
  // The number must be preceded by whitespace or a comma, so "Vitamin D3" never yields dose 3.
  static final _dosage = RegExp(
    r"^\s*([\p{L}][\p{L}\p{N}'\-]*(?:\s+[\p{L}][\p{L}\p{N}'\-]*)*)(?:\s*,\s*|\s+)(\d+(?:\.\d+)?)(?:\s*(mgs?|milligrams?|mcgs?|micrograms?|grams?|g|mls?|millilit(?:re|er)s?|iu)\b)?",
    unicode: true,
    caseSensitive: false,
  );

  // "twice a day", "3 times a day", "once daily", "every day", "daily".
  static final _frequency = RegExp(
    r'\b(?:(once|twice|thrice|one|two|three|four|five|six|\d+)\s+(?:times?\s+)?(?:a\s+day|per\s+day|daily)|(daily|every\s+day))\b',
    caseSensitive: false,
  );

  // "for 5 days", "for two weeks".
  static final _duration = RegExp(
    r'\bfor\s+(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s+(days?|weeks?)\b',
    caseSensitive: false,
  );

  static const _counts = {
    'once': 1,
    'one': 1,
    'twice': 2,
    'two': 2,
    'thrice': 3,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };

  // Words that end a medicine name: grammar, frequency, timing, duration.
  static const _stopWords = {
    'a',
    'an',
    'the',
    'it',
    'my',
    'to',
    'at',
    'as',
    'if',
    'of',
    'on',
    'in',
    'and',
    'or',
    'per',
    'day',
    'days',
    'daily',
    'every',
    'for',
    'times',
    'time',
    'after',
    'before',
    'with',
    'without',
    'when',
    'needed',
    'take',
    'need',
    'add',
    'week',
    'weeks',
  };

  static final _types = <(RegExp, MedicineType)>[
    (_Kw.capsule, MedicineType.capsule),
    (_Kw.tablet, MedicineType.tablet),
    (_Kw.syrup, MedicineType.syrup),
    (_Kw.drops, MedicineType.drops),
    (_Kw.injection, MedicineType.injection),
    (_Kw.inhaler, MedicineType.inhaler),
    (_Kw.ointment, MedicineType.ointment),
    (_Kw.patch, MedicineType.patch),
  ];

  static final _timings = <(RegExp, MedicineIntakeTiming)>[
    (_Kw.beforeSleep, MedicineIntakeTiming.beforeSleep),
    (_Kw.beforeFood, MedicineIntakeTiming.beforeFood),
    (_Kw.afterFood, MedicineIntakeTiming.afterFood),
    (_Kw.withFood, MedicineIntakeTiming.withFood),
    (_Kw.empty, MedicineIntakeTiming.empty),
  ];

  static MedicineDraft parse(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) return const MedicineDraft();

    final body = text.replaceFirst(_lead, '');
    // A dose only counts when its number directly follows a clean name,
    // so "Paracetamol twice a day for 5 days" never yields dosage 5.
    final dose = _dosage.firstMatch(body);
    final namedDose = dose != null && _nameFrom(dose.group(1)!) != null
        ? dose
        : null;
    final frequency = _frequency.firstMatch(text);
    final duration = _duration.firstMatch(text);

    return MedicineDraft(
      name: _name(body),
      dosageAmount: namedDose == null
          ? null
          : double.parse(namedDose.group(2)!),
      unit: namedDose?.group(3) == null ? null : _unitOf(namedDose!.group(3)!),
      medicineType: _firstWhereMatch(text, _types),
      reminderTimes: frequency == null
          ? null
          : _defaultTimes(_count(frequency.group(1) ?? 'once')),
      intakeTiming: _timing(text),
      durationDays: duration == null ? null : _durationDays(duration),
      notes: text,
    );
  }

  /// Leading words up to the first stopword, e.g. "Paracetamol twice" -> "Paracetamol".
  static String? _name(String body) {
    final run = _nameRun.firstMatch(body)?.group(1);
    if (run == null) return null;
    final words = run.split(RegExp(r'\s+')).takeWhile((w) => !_isStopWord(w));
    return _nameFrom(words.join(' '));
  }

  /// 1-3 words, none a stopword, form word stripped. Null when unsure.
  static String? _nameFrom(String words) {
    final name = words.replaceFirst(_trailingFormWord, '').trim();
    final parts = name.split(RegExp(r'\s+'));
    if (name.isEmpty || parts.length > 3 || parts.any(_isStopWord)) return null;
    return _capitalize(name);
  }

  static bool _isStopWord(String word) {
    final lower = word.toLowerCase();
    return _stopWords.contains(lower) || _counts.containsKey(lower);
  }

  static T? _firstWhereMatch<T>(String text, List<(RegExp, T)> rules) {
    for (final (pattern, value) in rules) {
      if (pattern.hasMatch(text)) return value;
    }
    return null;
  }

  /// Null when none or several timings match: "after food at bedtime" is ambiguous.
  static MedicineIntakeTiming? _timing(String text) {
    final matches = _timings.where((rule) => rule.$1.hasMatch(text)).toList();
    return matches.length == 1 ? matches.single.$2 : null;
  }

  static int? _durationDays(RegExpMatch match) {
    final count = _count(match.group(1)!);
    if (count == null || count < 1) return null;
    return count * (match.group(2)!.toLowerCase().startsWith('week') ? 7 : 1);
  }

  static int? _count(String token) =>
      int.tryParse(token) ?? _counts[token.toLowerCase()];

  /// Evenly spread [count] doses between 08:00 and 20:00. Null when unknown
  /// or outside 1-6 doses a day.
  static List<int>? _defaultTimes(int? count) {
    if (count == null || count < 1 || count > 6) return null;
    if (count == 1) return const [8 * 3600];
    return [
      for (var i = 0; i < count; i++)
        ((8 + i * 12 / (count - 1)) * 3600).round(),
    ];
  }

  /// Canonical unit: "milligrams" -> "mg", "mls" -> "ml".
  static String _unitOf(String raw) {
    final unit = raw.toLowerCase();
    if (unit.startsWith('mg') || unit.startsWith('milligram')) return 'mg';
    if (unit.startsWith('mcg') || unit.startsWith('microgram')) return 'mcg';
    if (unit.startsWith('ml') || unit.startsWith('millilit')) return 'ml';
    if (unit.startsWith('gram') || unit == 'g') return 'g';
    return unit;
  }

  // "Amoxicillin capsule 250 mg": the form word belongs to the type, not the name.
  static final _trailingFormWord = RegExp(
    r'(?:^|\s+)(capsules?|tablets?|pills?|syrups?|suspensions?|drops?|injections?|inhalers?|ointments?|creams?|gels?|patch(es)?)$',
    caseSensitive: false,
  );

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// Keyword patterns, shared by the rule tables above.
abstract final class _Kw {
  static final capsule = RegExp(r'\bcapsules?\b', caseSensitive: false);
  static final tablet = RegExp(r'\b(tablets?|pills?)\b', caseSensitive: false);
  static final syrup = RegExp(
    r'\b(syrups?|suspensions?)\b',
    caseSensitive: false,
  );
  static final drops = RegExp(r'\bdrops?\b', caseSensitive: false);
  static final injection = RegExp(
    r'\b(injections?|shots?)\b',
    caseSensitive: false,
  );
  static final inhaler = RegExp(
    r'\b(inhalers?|puffs?)\b',
    caseSensitive: false,
  );
  static final ointment = RegExp(
    r'\b(ointments?|creams?|gels?)\b',
    caseSensitive: false,
  );
  static final patch = RegExp(r'\bpatch(es)?\b', caseSensitive: false);
  static final beforeSleep = RegExp(
    r'\b(before\s+(bed|sleep)|at\s+bedtime|bedtime)\b',
    caseSensitive: false,
  );
  static final beforeFood = RegExp(
    r'\bbefore\s+(food|meals?|eating)\b',
    caseSensitive: false,
  );
  static final afterFood = RegExp(
    r'\bafter\s+(food|meals?|eating)\b',
    caseSensitive: false,
  );
  static final withFood = RegExp(
    r'\bwith\s+(food|meals?|a\s+meal)\b',
    caseSensitive: false,
  );
  static final empty = RegExp(
    r'\b(empty\s+stomach|fasting)\b',
    caseSensitive: false,
  );
}
