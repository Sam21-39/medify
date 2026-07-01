import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/medify_logo.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingCarouselPage extends StatelessWidget {
  const OnboardingCarouselPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const MedifyLogo(size: 120),
              const SizedBox(height: 24),
              Text(
                'Never miss a dose.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Medify keeps you and your loved ones on track with smart '
                'reminders and secure health tracking.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await getIt<OnboardingRepository>().setSeenOnboarding();
                    if (context.mounted) context.go('/auth/phone');
                  },
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await getIt<OnboardingRepository>().setSeenOnboarding();
                  if (context.mounted) context.go('/auth/phone');
                },
                child: const Text('Already using Medify? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
