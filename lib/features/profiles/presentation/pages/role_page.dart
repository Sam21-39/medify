import 'package:flutter/material.dart';
import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/features/profiles/data/repositories/care_link_repository.dart';
import 'package:medify/features/profiles/data/services/profile_service.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  Future<void> _choose(BuildContext context, int role) async {
    final profiles = getIt<ProfileService>();
    final active = profiles.active;
    if (active == null) return;
    await profiles.updateProfile(active.copyWith(role: role));
    await getIt<PreferencesService>().setRoleChosen();
    if (!context.mounted) return;
    if (role == 1) await _pickPatient(context, active.copyWith(role: role));
    getIt<AppMessenger>().go('/today');
  }

  Future<void> _pickPatient(BuildContext context, UserProfile caregiver) async {
    final patients = (await getIt<ProfileService>().getAllProfiles())
        .where((profile) => profile.role == 0 && profile.id != caregiver.id)
        .toList();
    if (patients.isEmpty || caregiver.id == null || !context.mounted) return;
    final picked = await showDialog<UserProfile>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Who are you helping?'),
        children: [
          for (final patient in patients)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, patient),
              child: Text(patient.name),
            ),
        ],
      ),
    );
    if (picked?.id == null) return;
    getIt<CareLinkRepository>().link(
      caregiverId: caregiver.id!,
      patientId: picked!.id!,
    );
    await getIt<PreferencesService>().setActingPatientId(picked.id!);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MedifyTokens.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Who is this phone for?', style: tokens.title1),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'Patient',
                subtitle: 'Track my own doses',
                onTap: () => _choose(context, 0),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Caregiver',
                subtitle: 'Help someone else take their medicine',
                onTap: () => _choose(context, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MedifyTokens.of(context).colors.bgSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MedifyTokens.of(context).title2),
              const SizedBox(height: 4),
              Text(subtitle, style: MedifyTokens.of(context).body),
            ],
          ),
        ),
      ),
    );
  }
}
