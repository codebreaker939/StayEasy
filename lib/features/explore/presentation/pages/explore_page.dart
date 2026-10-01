import 'package:flutter/material.dart';

import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_elevation.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StayEasy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(StayEasySpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design system preview', style: StayEasyTypography.headingH1),
            const SizedBox(height: StayEasySpacing.space8),
            Text(
              'Temporary token demo; the Explore screen will follow Figma later.',
              style: StayEasyTypography.bodyMedium.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
            const SizedBox(height: StayEasySpacing.space24),
            FilledButton(onPressed: () {}, child: const Text('Primary action')),
            const SizedBox(height: StayEasySpacing.space24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(StayEasySpacing.space16),
              decoration: BoxDecoration(
                color: StayEasyColors.surface,
                border: Border.all(color: StayEasyColors.border),
                borderRadius: StayEasyRadii.rounded16,
                boxShadow: StayEasyElevation.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Surface card', style: StayEasyTypography.titleMedium),
                  const SizedBox(height: StayEasySpacing.space8),
                  Text(
                    'Primary and secondary text use semantic tokens.',
                    style: StayEasyTypography.bodyMedium.copyWith(
                      color: StayEasyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: StayEasySpacing.space16),
                  Text(
                    'AI accent',
                    style: StayEasyTypography.labelMedium.copyWith(
                      color: StayEasyColors.aiAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
