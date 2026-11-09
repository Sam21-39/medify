import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/achievement_service.dart';
import '../../domain/entities/achievement.dart';

/// Page to display user achievements and progress
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ConfettiController _confettiController;

  final AchievementService _achievementService = getIt<AchievementService>();

  List<Achievement> _allAchievements = [];
  AchievementStats? _stats;
  bool _isLoading = true;

  AchievementCategory _selectedCategory = AchievementCategory.streak;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    final achievements = await _achievementService.getAllAchievements();
    final stats = await _achievementService.getAchievementStats();

    setState(() {
      _allAchievements = achievements;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unlocked', icon: Icon(Icons.emoji_events)),
            Tab(text: 'All', icon: Icon(Icons.grid_view)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stats card
              if (_stats != null) _buildStatsCard(theme),

              // Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildUnlockedTab(), _buildAllTab()],
                ),
              ),
            ],
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stats summary card
  Widget _buildStatsCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(AppSizes.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 Achievement Progress',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM,
                      vertical: AppSizes.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    ),
                    child: Text(
                      '${_stats!.completionPercentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            LinearProgressIndicator(
              value: _stats!.completionPercentage / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              children: [
                _buildStatPill(
                  theme,
                  '${_stats!.unlockedAchievements}',
                  'Unlocked',
                  AppColors.success,
                ),
                const SizedBox(width: AppSizes.paddingS),
                _buildStatPill(
                  theme,
                  '${_stats!.totalAchievements - _stats!.unlockedAchievements}',
                  'Locked',
                  AppColors.textDisabledLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(ThemeData theme, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  /// Build unlocked achievements tab
  Widget _buildUnlockedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final unlocked = _allAchievements.where((a) => a.isUnlocked).toList();

    if (unlocked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text('No achievements yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              'Start taking your medicines to unlock achievements!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort by unlock date (most recent first)
    unlocked.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: unlocked.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(unlocked[index], isUnlocked: true);
      },
    );
  }

  /// Build all achievements tab with category filters
  Widget _buildAllTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Category selector
        _buildCategorySelector(),

        // Achievement grid
        Expanded(child: _buildCategoryAchievements(_selectedCategory)),
      ],
    );
  }

  /// Build category selector
  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AchievementCategory.values.length,
        itemBuilder: (context, index) {
          final category = AchievementCategory.values[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingS),
            child: FilterChip(
              label: Text(category.title),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build achievements for selected category
  Widget _buildCategoryAchievements(AchievementCategory category) {
    final categoryAchievements = _allAchievements
        .where((a) => a.type.category == category)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppSizes.paddingM,
        mainAxisSpacing: AppSizes.paddingM,
      ),
      itemCount: categoryAchievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(
          categoryAchievements[index],
          isUnlocked: categoryAchievements[index].isUnlocked,
        );
      },
    );
  }

  /// Build achievement card
  Widget _buildAchievementCard(Achievement achievement, {required bool isUnlocked}) {
    final theme = Theme.of(context);
    final rarity = achievement.type.rarity;

    return Card(
      elevation: isUnlocked ? 4 : 1,
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            border: Border.all(
              color: isUnlocked
                  ? Color(rarity.colorValue).withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? Color(rarity.colorValue).withValues(alpha: 0.1)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  Text(
                    achievement.type.emoji,
                    style: TextStyle(
                      fontSize: 40,
                      color: isUnlocked ? null : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  if (!isUnlocked)
                    Icon(
                      Icons.lock,
                      size: 30,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),

              // Title
              Text(
                achievement.type.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Rarity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Color(rarity.colorValue).withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  rarity.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUnlocked
                        ? Color(rarity.colorValue)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),

              // Progress bar (if not unlocked)
              if (!isUnlocked) ...[
                const SizedBox(height: AppSizes.paddingS),
                LinearProgressIndicator(
                  value: achievement.progressPercentage / 100,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(rarity.colorValue)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${achievement.progress}/${achievement.type.targetValue}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show achievement details dialog
  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final rarity = achievement.type.rarity;

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(rarity.colorValue).withValues(alpha: 0.1), theme.cardColor],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  child: Column(
                    children: [
                      // Large emoji
                      Text(achievement.type.emoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: AppSizes.paddingM),

                      // Title
                      Text(
                        achievement.type.title,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingS),

                      // Rarity
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: AppSizes.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: Color(rarity.colorValue).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Color(rarity.colorValue)),
                            const SizedBox(width: 4),
                            Text(
                              rarity.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Color(rarity.colorValue),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                    vertical: AppSizes.paddingM,
                  ),
                  child: Text(
                    achievement.type.description,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),

                // Progress or unlock date
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusL),
                      bottomRight: Radius.circular(AppSizes.radiusL),
                    ),
                  ),
                  child: achievement.isUnlocked
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success),
                            const SizedBox(width: AppSizes.paddingS),
                            Text(
                              'Unlocked on ${_formatDate(achievement.unlockedAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            LinearProgressIndicator(
                              value: achievement.progressPercentage / 100,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(rarity.colorValue)),
                            ),
                            const SizedBox(height: AppSizes.paddingS),
                            Text(
                              '${achievement.progress} / ${achievement.type.targetValue}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${achievement.progressPercentage.toStringAsFixed(0)}% Complete',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
