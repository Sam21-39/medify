import 'package:injectable/injectable.dart';

/// Minimal DI-resolvable auth signal `AuthGuard` reads from. The `auth/`
/// feature's `AuthCubit` updates this on sign-in/sign-out; kept here
/// (rather than importing `features/auth`) so `core/router` never depends
/// on a feature's presentation layer (Section 4 rule).
@lazySingleton
class AuthSessionStatus {
  bool isAuthenticated = false;
}
