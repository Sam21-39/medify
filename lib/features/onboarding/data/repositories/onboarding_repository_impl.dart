import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/consent_record.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../local/onboarding_local_data_source.dart';

@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._local, this._firestore);

  final OnboardingLocalDataSource _local;
  final FirebaseFirestore _firestore;

  @override
  Future<bool> hasSeenOnboarding() => _local.hasSeenOnboarding();

  @override
  Future<void> setSeenOnboarding() => _local.setSeenOnboarding();

  DocumentReference<Map<String, dynamic>> _consentDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('consent').doc('dpdp');

  @override
  Future<bool> hasAcceptedConsent(String uid) async {
    final doc = await _consentDoc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> acceptConsent(String uid, ConsentRecord record) {
    return _consentDoc(uid).set({
      'acceptedAt': record.acceptedAt.toIso8601String(),
      'version': record.version,
    });
  }
}
