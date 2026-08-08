import 'package:equatable/equatable.dart';

/// Referenced by `medicine`, `adherence`, `appointments`, and others — lives
/// here (not in `features/profile/domain`) specifically to avoid circular
/// feature dependencies, per the Section 4 folder-structure rule.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.relation,
    this.avatarRef,
    this.isPrimary = false,
  });

  final String id;
  final String name;
  final String relation;
  final String? avatarRef;
  final bool isPrimary;

  @override
  List<Object?> get props => [id, name, relation, avatarRef, isPrimary];
}
