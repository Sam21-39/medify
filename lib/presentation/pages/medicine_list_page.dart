import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/medicine_log.dart';
import '../../l10n/app_localizations.dart';
import '../blocs/medicine/medicine_cubit.dart';
import '../blocs/medicine/medicine_state.dart';
import '../blocs/medicine_log/medicine_log_cubit.dart';
import '../blocs/medicine_log/medicine_log_state.dart';
import '../widgets/medicine_card.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import '../widgets/profile_switcher.dart';
import '../widgets/todays_summary_card.dart';
import 'add_edit_medicine_page.dart';
import 'settings_page.dart';

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
    // Load medicines and today's logs when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicines();
      _loadTodaysLogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when page becomes visible (e.g., after adding medicine)
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadMedicines();
      _loadTodaysLogs();
    }
  }

  void _loadMedicines() {
    getIt<MedicineCubit>().loadMedicines();
  }

  void _loadTodaysLogs() {
    final today = DateTime.now();
    getIt<MedicineLogCubit>().loadLogsByDate(today);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        // COMMENTED OUT FOR UPCOMING RELEASE
        // leading: const Padding(
        //   padding: EdgeInsets.only(left: 8.0),
        //   child: ProfileSwitcher(),
        // ),
        title: const Text('Medify'), // Per spec: "Medify" (H2)
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadMedicines();
              _loadTodaysLogs();
            },
            tooltip: 'Refresh',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        bloc: getIt<MedicineCubit>(),
        listenWhen: (previous, current) {
          // Prevent duplicate listeners from IndexedStack
          return (current is MedicineOperationSuccess ||
                  current is MedicineError) &&
              previous != current;
        },
        listener: (context, state) {
          // Clear any existing snackbars first
          ScaffoldMessenger.of(context).clearSnackBars();

          // Show snackbar on operations
          if (state is MedicineOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Reload medicines after successful operation
            _loadMedicines();
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
            // Use shimmer loading instead of circular progress
            return const ShimmerLoadingList(
              itemCount: 4,
              shimmerWidget: ShimmerMedicineCard(),
            );
          }

          if (state is MedicineLoaded) {
            if (state.medicines.isEmpty) {
              return EmptyState(
                icon: Icons.medication,
                title: AppLocalizations.of(context)!.noMedicines,
                message: AppLocalizations.of(context)!.addYourFirstMedicine,
                actionText: AppLocalizations.of(context)!.addMedicine,
                onAction: () => _navigateToAddMedicine(),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadMedicines();
                _loadTodaysLogs();
              },
              child: CustomScrollView(
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
                      delegate: SliverChildBuilderDelegate((context, index) {
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
                                    onTap: () =>
                                        _navigateToEditMedicine(medicine.id!),
                                    onToggleActive: () {
                                      context
                                          .read<MedicineCubit>()
                                          .toggleMedicineStatus(medicine.id!);
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

                  // Bottom padding
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSizes.spacing16),
                  ),
                ],
              ),
            );
          }

          // Show empty state for initial/error states
          return EmptyState(
            icon: Icons.medication,
            title: AppLocalizations.of(context)!.noMedicines,
            message: AppLocalizations.of(context)!.addYourFirstMedicine,
            actionText: AppLocalizations.of(context)!.addMedicine,
            onAction: () => _navigateToAddMedicine(),
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
