import 'package:equatable/equatable.dart';

/// Mirrors the `medicines.schedule_type` / `schedule_config_json` split in
/// Drift (Section 5.1) — `configJson` shape depends on `type` and is parsed
/// by the matching `core/notifications` `ReminderStrategy`.
class Schedule extends Equatable {
  const Schedule({required this.type, required this.configJson});

  final String type;
  final String configJson;

  @override
  List<Object?> get props => [type, configJson];
}
