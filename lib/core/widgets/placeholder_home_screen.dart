import 'package:flutter/material.dart';

/// Boots the app shell during initial architecture setup, before the
/// `medicine`/`reminders` feature screens exist. Replace with the real home
/// screen once those features land.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medify')),
      body: const Center(
        child: Text('Architecture scaffold — feature screens land next.'),
      ),
    );
  }
}
