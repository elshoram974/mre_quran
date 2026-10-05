import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_shimmer.dart';

/// Loading placeholder shaped like the index list.
class IndexSkeleton extends StatelessWidget {
  /// Creates the skeleton.
  const IndexSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);
    return Padding(
      padding: padding,
      child: AppShimmer(
        child: Column(
          children: [
            const SkeletonBox(height: 40, radius: 12),
            const SizedBox(height: 12),
            const SkeletonBox(height: 56),
            const SizedBox(height: 16),
            for (var i = 0; i < 7; i++) ...[
              const SkeletonBox(height: 64),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
