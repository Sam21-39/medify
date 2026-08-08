import 'package:equatable/equatable.dart';

import 'app_user.dart';

class Session extends Equatable {
  const Session({required this.user, required this.expiresAt});

  final AppUser user;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [user, expiresAt];
}
