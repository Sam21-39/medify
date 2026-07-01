import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../cubit/consent_cubit.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key, required this.uid});

  final String uid;

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ConsentCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Data Privacy Consent')),
        body: SafeArea(
          child: BlocConsumer<ConsentCubit, ConsentState>(
            listener: (context, state) {
              if (state is ConsentGranted) context.go('/');
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Before you continue',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medify stores health-related information (medicines, '
                      'conditions, allergies, emergency contacts) to power '
                      'your reminders and adherence tracking. This data is '
                      'encrypted and never shared without your explicit '
                      'consent, in line with India\'s DPDP Act (2023).',
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I have read and agree to Medify collecting and '
                        'processing my health data as described above.',
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _agreed
                          ? () => context.read<ConsentCubit>().acceptConsent(
                              widget.uid,
                            )
                          : null,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
