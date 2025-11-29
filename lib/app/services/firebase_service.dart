import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/medication_model.dart';
import '../data/models/dose_log_model.dart';
import '../data/models/user_model.dart';
import '../../core/utils/constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Auth ---

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- User Data ---

  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toJson());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // --- Medications ---

  Future<void> saveMedication(MedicationModel medication) async {
    if (currentUser == null) return;
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .collection(AppConstants.medicationsCollection)
        .doc(medication.id)
        .set(medication.toJson());
  }

  Future<void> deleteMedication(String medicationId) async {
    if (currentUser == null) return;
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .collection(AppConstants.medicationsCollection)
        .doc(medicationId)
        .delete();
  }

  Stream<List<MedicationModel>> getMedications() {
    if (currentUser == null) return Stream.value([]);
    
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .collection(AppConstants.medicationsCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicationModel.fromJson(doc.data()))
          .toList();
    });
  }

  // --- Dose Logs ---

  Future<void> saveDoseLog(DoseLogModel log) async {
    if (currentUser == null) return;
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .collection(AppConstants.doseLogsCollection)
        .doc(log.id)
        .set(log.toJson());
  }

  Stream<List<DoseLogModel>> getDoseLogs(String medicationId) {
    if (currentUser == null) return Stream.value([]);
    
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .collection(AppConstants.doseLogsCollection)
        .where('medicationId', isEqualTo: medicationId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoseLogModel.fromJson(doc.data()))
          .toList();
    });
  }
}
