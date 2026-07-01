import 'package:equatable/equatable.dart';

/// Current DPDP consent copy version. Bump this if the consent text
/// materially changes, so re-consent can be enforced later if needed.
const consentVersion = 1;

class ConsentRecord extends Equatable {
  const ConsentRecord({required this.acceptedAt, required this.version});

  final DateTime acceptedAt;
  final int version;

  @override
  List<Object?> get props => [acceptedAt, version];
}
