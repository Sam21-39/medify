import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medify/app/data/models/user_model.dart';
import 'package:medify/app/services/firebase_service.dart';
import 'package:medify/app/routes/app_routes.dart';
import 'package:medify/core/utils/constants.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.put(FirebaseService());
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onReady() {
    super.onReady();
    _firebaseUser.bindStream(_firebaseService.authStateChanges);
    ever(_firebaseUser, _setInitialScreen);
  }

  Future<void> _setInitialScreen(User? user) async {
    if (user == null) {
      // Check if onboarding is complete
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

      if (onboardingComplete) {
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }
    } else {
      // User is logged in, fetch user data
      await _fetchUserData(user.uid);
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _fetchUserData(String userId) async {
    try {
      final user = await _firebaseService.getUser(userId);
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      // Error fetching user data
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final credential = await _firebaseService.signUp(email, password);

      // Create new user model
      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        emailVerified: false,
        preferences: UserPreferences(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firebaseService.saveUser(newUser);
      currentUser.value = newUser;

      // Send verification email
      // await credential.user!.sendEmailVerification();

      // Get.offAllNamed(AppRoutes.emailVerification);
      Get.offAllNamed(AppRoutes.permissionRequest);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Registration failed');
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _firebaseService.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Login failed');
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
    currentUser.value = null;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
  }
}
