import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:medify/core/constants/app_colors.dart';
import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/design/adaptive.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/widgets/empty_state.dart';
import 'package:medify/core/widgets/shimmer_loading.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/l10n/app_localizations.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_state.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_state.dart';
import 'package:medify/features/medicines/presentation/widgets/medicine_card.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../widgets/profile_switcher.dart';
import 'package:medify/features/schedule/presentation/widgets/todays_summary_card.dart';
import 'package:medify/features/medicines/presentation/pages/add_edit_medicine_page.dart';
import 'package:medify/features/settings/presentation/pages/settings_page.dart';

/// Page to display list of all medicines
class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _loadMedicines() => getIt<MedicineCubit>().loadMedicines();

  Future<void> _loadTodaysLogs() {
    final today = DateTime.now();
    return getIt<MedicineLogCubit>().loadLogsByDate(today);
  }

  Future<void> _refresh() => Future.wait([_loadMedicines(), _loadTodaysLogs()]);

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'Medify',
        useNativeToolbar: true,
        actions: [
          MedifyAdaptive.action(
            iosSymbol: 'arrow.clockwise',
            icon: Icons.refresh,
            label: 'Refresh',
            onPressed: _refresh,
          ),
          MedifyAdaptive.action(
            iosSymbol: 'gearshape',
            icon: Icons.settings,
            label: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        bloc: getIt<MedicineCubit>(),
        listenWhen: (previous, current) {
          return (current is MedicineOperationSuccess ||
                  current is MedicineError) &&
              previous != current;
        },
        listener: (context, state) {
          // Cubit already reloads after success — snackbar only
          ScaffoldMessenger.of(context).clearSnackBars();

          if (state is MedicineOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state is MedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: AppLocalizations.of(context)!.retry,
                  textColor: Colors.white,
                  onPressed: _loadMedicines,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicineLoading) {
            return MedifyAdaptive.body(
              tabShell: true,
              child: const ShimmerLoadingList(
                itemCount: 4,
                shimmerWidget: ShimmerMedicineCard(),
              ),
            );
          }

          if (state is MedicineLoaded) {
            if (state.medicines.isEmpty) {
              return MedifyAdaptive.body(
                tabShell: true,
                child: EmptyState(
                  icon: Icons.medication,
                  title: AppLocalizations.of(context)!.noMedicines,
                  message: AppLocalizations.of(context)!.addYourFirstMedicine,
                  actionText: AppLocalizations.of(context)!.addMedicine,
                  onAction: () => _navigateToAddMedicine(),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        // Today's Summary Card at top
                        SliverToBoxAdapter(
                          child: BlocBuilder<MedicineLogCubit, MedicineLogState>(
                            bloc:
                                getIt<
                                  MedicineLogCubit
                                >(), // Explicitly use singleton instance
                            builder: (context, logState) {
                              final logs = logState is MedicineLogLoaded
                                  ? logState.logs
                                  : <MedicineLog>[];
                              return TodaysSummaryCard(
                                todaysLogs: logs,
                                onTap: () {
                                  // Tapping takes user to Schedule page (index 0)
                                  // This is handled by the main navigation page
                                },
                              );
                            },
                          ),
                        ),

                        // Medicines header
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppSizes.spacing16,
                            AppSizes.spacing8,
                            AppSizes.spacing16,
                            AppSizes.spacing8,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'My Medicines',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Medicine List with Staggered Animation
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing16,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final medicine = state.medicines[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSizes.spacing8,
                                      ),
                                      child: Dismissible(
                                        key: Key(medicine.id.toString()),
                                        direction: DismissDirection.endToStart,
                                        confirmDismiss: (direction) async {
                                          return await _showDeleteConfirmation(
                                            context,
                                            medicine.name,
                                          );
                                        },
                                        onDismissed: (direction) {
                                          getIt<MedicineCubit>().deleteMedicine(
                                            medicine.id!,
                                          );
                                        },
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                            right: AppSizes.paddingL,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius: BorderRadius.circular(
                                              AppSizes.radiusCard,
                                            ),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                                size: AppSizes.iconL,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: MedicineCard(
                                          medicine: medicine,
                                          onTap: () => _navigateToEditMedicine(
                                            medicine.id!,
                                          ),
                                          onToggleActive: () {
                                            context
                                                .read<MedicineCubit>()
                                                .toggleMedicineStatus(
                                                  medicine.id!,
                                                );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: state.medicines.length),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab overlay clearance (shell bottom bar)
                  const SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MedifyAdaptive.tabOverlayClearance,
                    ),
                  ),
                ],
              ),
            );
          }

          return MedifyAdaptive.body(
            tabShell: true,
            child: EmptyState(
              icon: Icons.medication,
              title: AppLocalizations.of(context)!.noMedicines,
              message: AppLocalizations.of(context)!.addYourFirstMedicine,
              actionText: AppLocalizations.of(context)!.addMedicine,
              onAction: () => _navigateToAddMedicine(),
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<MedicineCubit, MedicineState>(
        bloc: getIt<MedicineCubit>(), // Explicitly use singleton instance
        builder: (context, state) {
          // Hide FAB when list is empty (empty state has its own button)
          if (state is MedicineLoaded && state.medicines.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            tooltip: AppLocalizations.of(context)!.addMedicine,
            onPressed: _navigateToAddMedicine,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String medicineName,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteConfirmation),
          content: Text('Are you sure you want to delete "$medicineName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to add medicine page
  Future<void> _navigateToAddMedicine() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddEditMedicinePage()),
    );

    // Reload medicines if a medicine was added
    if (result == true && mounted) {
      _loadMedicines();
      _loadTodaysLogs();
    }
  }

  /// Navigate to edit medicine page
  Future<void> _navigateToEditMedicine(int medicineId) async {
    // Find the medicine
    final state = getIt<MedicineCubit>().state;
    if (state is! MedicineLoaded) return;

    final medicine = state.medicines.firstWhere((m) => m.id == medicineId);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditMedicinePage(medicine: medicine),
      ),
    );

    // Reload medicines if a medicine was updated
    if (result == true && mounted) {
      _loadMedicines();
    }
  }
}
