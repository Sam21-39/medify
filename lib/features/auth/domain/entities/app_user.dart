import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.uid, required this.phoneNumber});

  final String uid;
  final String? phoneNumber;

  @override
  List<Object?> get props => [uid, phoneNumber];
}
