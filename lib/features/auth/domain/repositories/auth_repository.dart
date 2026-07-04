import '../entities/app_user.dart';

/// Result of requesting an OTP: the verificationId is required to confirm
/// the code the user enters against Firebase.
class OtpRequest {
  const OtpRequest({required this.verificationId});

  final String verificationId;
}

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<OtpRequest> sendOtp(String phoneNumber);

  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}
