import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:injectable/injectable.dart';

import '../../error/failure.dart';
import '../../error/result.dart';
import '../secure_storage/secure_storage_service.dart';

/// AES-256-GCM engine for every field written to Firestore/Cloud Storage
/// (Section 6.2). Independent of the SQLCipher key used for local-at-rest
/// encryption (Section 5.2) — the two boundaries are deliberately separate.
///
/// The data encryption key (DEK) here is stored locally via
/// [SecureStorageService]. Wrapping the DEK with a server-derived key
/// (Firebase Auth UID + pepper, via a Cloud Function) is deferred — this is
/// a local-only stub until that Cloud Function exists.
abstract class EncryptionEngine {
  Future<Result<String, EncryptionFailure>> encrypt(String plaintext);
  Future<Result<String, EncryptionFailure>> decrypt(String ciphertext);
}

@LazySingleton(as: EncryptionEngine)
class AesGcmEncryptionEngine implements EncryptionEngine {
  AesGcmEncryptionEngine(this._secureStorage);

  final SecureStorageService _secureStorage;
  final _algorithm = AesGcm.with256bits();

  Future<SecretKey> _resolveKey() async {
    final existing = await _secureStorage.readDataEncryptionKey();
    if (existing != null) {
      return SecretKey(base64Decode(existing));
    }
    final generated = await _algorithm.newSecretKey();
    final bytes = await generated.extractBytes();
    await _secureStorage.writeDataEncryptionKey(base64Encode(bytes));
    return generated;
  }

  @override
  Future<Result<String, EncryptionFailure>> encrypt(String plaintext) async {
    try {
      final key = await _resolveKey();
      final nonce = _algorithm.newNonce();
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );
      return Success(base64Encode(secretBox.concatenation()));
    } catch (e) {
      return Error(EncryptionFailure(technicalMessage: e.toString()));
    }
  }

  @override
  Future<Result<String, EncryptionFailure>> decrypt(String ciphertext) async {
    try {
      final key = await _resolveKey();
      final bytes = base64Decode(ciphertext);
      final secretBox = SecretBox.fromConcatenation(
        bytes,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );
      final clear = await _algorithm.decrypt(secretBox, secretKey: key);
      return Success(utf8.decode(clear));
    } catch (e) {
      return Error(EncryptionFailure(technicalMessage: e.toString()));
    }
  }
}
