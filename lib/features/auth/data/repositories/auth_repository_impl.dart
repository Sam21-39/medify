import 'package:injectable/injectable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<AppUser?> get authStateChanges => _dataSource.authStateChanges;

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Future<OtpRequest> sendOtp(String phoneNumber) async {
    // Auto-verification (instant SMS retrieval) signs the user in directly
    // via FirebaseAuth, which authStateChanges already reflects - no extra
    // plumbing needed here beyond waiting for a verificationId.
    final verificationId = await _dataSource.sendOtp(
      phoneNumber,
      onAutoVerified: (_) {},
    );
    return OtpRequest(verificationId: verificationId);
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return _dataSource.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
