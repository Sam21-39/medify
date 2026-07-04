import '../entities/consent_record.dart';

abstract class OnboardingRepository {
  Future<bool> hasSeenOnboarding();
  Future<void> setSeenOnboarding();

  Future<bool> hasAcceptedConsent(String uid);
  Future<void> acceptConsent(String uid, ConsentRecord record);
}
