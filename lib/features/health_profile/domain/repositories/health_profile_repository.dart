import '../entities/health_profile.dart';

abstract class HealthProfileRepository {
  Stream<HealthProfile?> watchProfile(String uid);
  Future<HealthProfile?> getProfile(String uid);
  Future<void> saveProfile(HealthProfile profile);
}
