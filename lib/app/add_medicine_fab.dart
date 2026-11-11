import 'package:flutter/material.dart';

import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/design/tokens/motion_tokens.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/widgets/medify_icon.dart';
import 'package:medify/features/medicines/domain/voice/medicine_draft_parser.dart';
import 'package:medify/gen/assets.gen.dart';
import 'package:medify/l10n/app_localizations.dart';

/// The only add-medicine entry point. Plus button expands to Manual entry and Voice input.
/// Overlays the tab shell; pushed routes cover it, so it is hidden on /settings, /medicine/*, /alarm.
class AddMedicineFab extends StatefulWidget {
  const AddMedicineFab({super.key, required this.tabIndex});

  /// Current tab. Changing tab closes an open menu.
  final int tabIndex;

  @override
  State<AddMedicineFab> createState() => _AddMedicineFabState();
}

class _AddMedicineFabState extends State<AddMedicineFab> {
  bool _open = false;
  bool _navigating = false;

  @override
  void didUpdateWidget(AddMedicineFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) _open = false;
  }

  void _toggle() => setState(() => _open = !_open);

  void _close() {
    if (_open) setState(() => _open = false);
  }

  /// One navigation at a time, so a double tap cannot push two routes.
  Future<void> _go(Future<void> Function() navigate) async {
    if (_navigating) return;
    _navigating = true;
    _close();
    try {
      await navigate();
    } finally {
      _navigating = false;
    }
  }

  Future<void> _openManual() => _go(() async {
    await getIt<AppMessenger>().push<bool>('/medicine/add');
  });

  Future<void> _openVoice() => _go(() async {
    final messenger = getIt<AppMessenger>();
    final draft = await messenger.push<MedicineDraft>('/medicine/add/voice');
    if (draft == null) return;
    await messenger.push<bool>('/medicine/add', extra: draft);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : MotionTokens.standard;
    // Clears the 64pt tab bar and the home indicator.
    final bottom =
        MediaQuery.paddingOf(context).bottom + AppSizes.bottomNavHeight;

    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scrim closes the menu on tap. Ignored while closed so tabs stay tappable.
          ExcludeSemantics(
            excluding: !_open,
            child: IgnorePointer(
              ignoring: !_open,
              child: AnimatedOpacity(
                opacity: _open ? 1 : 0,
                duration: duration,
                child: Semantics(
                  button: true,
                  label: l10n.close,
                  onTap: _close,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: ColoredBox(
                      color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSizes.paddingM,
            bottom: bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ExcludeSemantics(
                  excluding: !_open,
                  child: IgnorePointer(
                    ignoring: !_open,
                    child: AnimatedOpacity(
                      opacity: _open ? 1 : 0,
                      duration: duration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MenuAction(
                            label: l10n.addMenuManual,
                            icon: Assets.icons.medicine,
                            onTap: _openManual,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _MenuAction(
                            label: l10n.addMenuVoice,
                            icon: Assets.icons.voiceNote,
                            onTap: _openVoice,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                        ],
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  expanded: _open,
                  label: l10n.addMedicine,
                  excludeSemantics: true,
                  onTap: _toggle,
                  child: Material(
                    color: theme.colorScheme.primary,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggle,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: AnimatedRotation(
                            turns: _open ? 0.125 : 0,
                            duration: duration,
                            child: MedifyIcon(
                              Assets.icons.add,
                              size: AppSizes.iconM,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled pill with a 48dp icon button. Whole pill is the tap target.
class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final SvgGenImage icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSizes.paddingM,
                right: AppSizes.paddingS,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  const SizedBox(width: AppSizes.paddingM),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: MedifyIcon(
                        icon,
                        size: AppSizes.iconM,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
