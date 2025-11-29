import 'package:firedart/firedart.dart'; // Ensure this path is correct relative to execution
// If package import fails in script, we might need relative path or run with proper package config
// For simplicity in a script, I'll use relative path if run from root: 'lib/app/data/models/medication_model.dart'
// But Dart imports usually require 'package:' scheme or relative.
// Let's try package import first, assuming 'dart run' from root.

const String projectId = 'medify-67e12';
const String apiKey = 'AIzaSyBwpKXC3XygqUQg6xk0ch8S1JuIVewD6xY'; // macOS API Key

Future<void> main() async {
  print('Initializing Firestore...');
  Firestore.initialize(projectId);

  print('Setting up collections...');

  // 1. Users Collection
  // We don't need to explicitly create collections, but we can add a dummy doc to ensure it shows up in console
  await setupCollection('users', {'_setup': true, 'createdAt': DateTime.now().toIso8601String()});

  // 2. Medications Collection
  await setupCollection('medications', {
    '_setup': true,
    'createdAt': DateTime.now().toIso8601String(),
  });

  // 3. Dose Logs Collection
  await setupCollection('dose_logs', {
    '_setup': true,
    'createdAt': DateTime.now().toIso8601String(),
  });

  // 4. Sync Queue (if we want to sync it, though usually local only)
  // await setupCollection('sync_queue', {'_setup': true});

  print('Firestore setup complete!');
  print('Created collections: users, medications, dose_logs');
  print('Note: Firestore collections are lazy. They only exist when they contain documents.');
  print('I have added a "_setup" document to each. You can delete them later.');
}

Future<void> setupCollection(String collectionName, Map<String, dynamic> data) async {
  try {
    final collection = Firestore.instance.collection(collectionName);
    await collection.document('_setup_script').set(data);
    print('✅ Created/Verified collection: $collectionName');
  } catch (e) {
    print('❌ Error setting up $collectionName: $e');
  }
}
