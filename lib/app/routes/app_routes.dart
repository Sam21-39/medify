import 'package:get/get.dart';
import '../modules/auth/views/splash_screen.dart';
import '../modules/auth/views/onboarding_screen.dart';
import '../modules/auth/views/login_screen.dart';
import '../modules/auth/views/register_screen.dart';
import '../modules/auth/views/email_verification_screen.dart';
import '../modules/auth/views/forgot_password_screen.dart';
import '../modules/auth/views/permission_request_screen.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/home/views/home_screen.dart';
import '../modules/home/views/main_screen.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/medications/views/add_medication_screen.dart';
import '../modules/medications/views/medication_detail_screen.dart';
import '../modules/medications/views/edit_medication_screen.dart';
import '../modules/medications/bindings/medication_binding.dart';

class AppRoutes {
  // Private constructor
  AppRoutes._();

  // Route names
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String permissionRequest = '/permission-request';

  static const String home = '/home';
  static const String addMedication = '/add-medication';
  static const String medicationDetail = '/medication-detail';
  static const String editMedication = '/edit-medication';
  static const String allMedications = '/all-medications';

  static const String history = '/history';

  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';

  // Initial route
  static const String initial = splash;

  // Route pages
  static final List<GetPage> routes = [
    // Auth routes
    GetPage(name: splash, page: () => const SplashScreen(), binding: AuthBinding()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: emailVerification, page: () => const EmailVerificationScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: permissionRequest, page: () => const PermissionRequestScreen()),

    // Home routes
    GetPage(name: home, page: () => const MainScreen(), binding: HomeBinding()),

    // Medication routes
    GetPage(
      name: addMedication,
      page: () => const AddMedicationScreen(),
      binding: MedicationBinding(),
    ),
    GetPage(
      name: medicationDetail,
      page: () => const MedicationDetailScreen(),
      binding: MedicationBinding(),
    ),
    GetPage(
      name: editMedication,
      page: () => const EditMedicationScreen(),
      binding: MedicationBinding(),
    ),
  ];
}
