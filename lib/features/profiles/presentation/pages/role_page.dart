import 'package:flutter/material.dart';
import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/profiles/data/sqflite/care_link_sqflite_repository.dart';
import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:medify/features/profiles/data/services/profile_service.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';
import 'package:medify/l10n/app_localizations.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

/// Settings flag: the first-medicine offer has been shown (or was not needed).
const _keyFirstMedicineOffer = 'first_medicine_offer_shown';

class _RolePageState extends State<RolePage> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await getIt<ProfileService>().initialize();
    if (mounted) setState(() => _busy = false);
  }

  void _showError() => getIt<AppMessenger>().show(
    AppLocalizations.of(context)!.errorGeneric,
    error: true,
  );

  Future<void> _choose(int role) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final profiles = getIt<ProfileService>();
      final active = profiles.active;
      if (active == null) {
        await _retry();
        return;
      }
      if (role == 1) {
        final hasPatient = (await profiles.getAllProfiles()).any(
          (profile) => profile.role == 0 && profile.id != active.id,
        );
        if (!hasPatient) {
          if (!mounted) return;
          getIt<AppMessenger>().show(
            AppLocalizations.of(context)!.addPatientProfileFirst,
            error: true,
          );
          return;
        }
      }
      await profiles.updateProfile(active.copyWith(role: role));
      try {
        await getIt<PreferencesService>().setRoleChosen();
      } catch (e) {
        _showError();
      }
      if (!mounted) return;
      if (role == 1) {
        try {
          await _pickPatient(context, active.copyWith(role: role));
        } catch (e) {
          _showError();
        }
      }
      var addFirst = false;
      if (role == 0) {
        try {
          addFirst = await _offerFirstMedicine();
        } catch (_) {
          addFirst = false; // any failure here means no offer
        }
      }
      getIt<AppMessenger>().go('/today');
      if (addFirst) await getIt<AppMessenger>().push<bool>('/medicine/add');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shows once. Returns true when the user picked "Add a medicine".
  Future<bool> _offerFirstMedicine() async {
    final prefs = getIt<PreferencesService>();
    if (await prefs.getInt(_keyFirstMedicineOffer) != null) return false;
    final result = await getIt<MedicineRepository>().getActiveMedicines();
    // Read failed: no offer, and leave the flag unset so it can be retried.
    if (result.isLeft()) return false;
    final hasMedicine = result.getOrElse(() => const []).isNotEmpty;
    if (hasMedicine) {
      await prefs.setInt(_keyFirstMedicineOffer, 1);
      return false;
    }
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addYourFirstMedicine),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.firstMedicineLaterAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.firstMedicineAddAction),
          ),
        ],
      ),
    );
    await prefs.setInt(_keyFirstMedicineOffer, 1);
    return add ?? false;
  }

  Future<void> _pickPatient(BuildContext context, UserProfile caregiver) async {
    final patients = (await getIt<ProfileService>().getAllProfiles())
        .where((profile) => profile.role == 0 && profile.id != caregiver.id)
        .toList();
    if (patients.isEmpty || caregiver.id == null || !context.mounted) return;
    final picked = await showDialog<UserProfile>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.whoAreYouHelping),
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
    try {
      await getIt<CareLinkSqfliteRepository>().link(
        caregiverId: caregiver.id!,
        patientId: picked!.id!,
      );
    } on InvalidProfileException {
      // Care link already exists: treat as success
    }
    await getIt<PreferencesService>().setActingPatientId(picked!.id!);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MedifyTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final active = getIt<ProfileService>().active;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: active == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.noProfileYet, style: tokens.title2),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _retry,
                      child: Text(_busy ? l10n.tryingAgain : l10n.tryAgain),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.whoIsPhoneFor, style: tokens.title1),
                    const SizedBox(height: 24),
                    _RoleCard(
                      title: l10n.rolePatient,
                      subtitle: l10n.rolePatientDesc,
                      onTap: _busy ? null : () => _choose(0),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      title: l10n.roleCaregiver,
                      subtitle: l10n.roleCaregiverDesc,
                      onTap: _busy ? null : () => _choose(1),
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
  final VoidCallback? onTap;

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
