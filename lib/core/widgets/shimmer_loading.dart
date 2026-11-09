import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_sizes.dart';

/// Shimmer loading widget for skeleton screens
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusS),
        ),
      ),
    );
  }
}

/// Shimmer loading for medicine card
class ShimmerMedicineCard extends StatelessWidget {
  const ShimmerMedicineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerLoading(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                const SizedBox(width: AppSizes.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                        width: double.infinity,
                        height: 20,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      const SizedBox(height: AppSizes.spacing8),
                      ShimmerLoading(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),
            ShimmerLoading(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for medicine log card
class ShimmerMedicineLogCard extends StatelessWidget {
  const ShimmerMedicineLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerLoading(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                const SizedBox(width: AppSizes.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                        width: double.infinity,
                        height: 20,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      const SizedBox(height: AppSizes.spacing8),
                      ShimmerLoading(
                        width: 160,
                        height: 16,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ],
                  ),
                ),
                ShimmerLoading(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: 36,
                    borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: 36,
                    borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for statistics card
class ShimmerStatisticsCard extends StatelessWidget {
  const ShimmerStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoading(
              width: 120,
              height: 24,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            const SizedBox(height: AppSizes.spacing16),
            ShimmerLoading(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ShimmerLoading(
                  width: 60,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                ShimmerLoading(
                  width: 60,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                ShimmerLoading(
                  width: 60,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading list
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final Widget shimmerWidget;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 3,
    required this.shimmerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      itemCount: itemCount,
      itemBuilder: (context, index) => shimmerWidget,
    );
  }
}

