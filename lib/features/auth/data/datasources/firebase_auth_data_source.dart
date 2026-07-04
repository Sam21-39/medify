import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_user.dart';

@lazySingleton
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth);

  final fb.FirebaseAuth _auth;

  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  AppUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(uid: user.uid, phoneNumber: user.phoneNumber);
  }

  /// Kicks off Firebase's phone-auth flow and resolves once a
  /// verificationId is available to check the user-entered OTP against.
  /// On platforms/devices that support instant (SMS-less) verification,
  /// `onAutoVerified` fires with the signed-in user instead.
  Future<String> sendOtp(
    String phoneNumber, {
    required void Function(AppUser user) onAutoVerified,
  }) {
    final completer = Completer<String>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        final result = await _auth.signInWithCredential(credential);
        final user = _mapUser(result.user);
        if (user != null) onAutoVerified(user);
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e.message ?? 'Phone verification failed');
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = _mapUser(result.user);
    if (user == null) {
      throw StateError('Sign-in succeeded but no user was returned');
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
