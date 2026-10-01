import 'package:flutter/material.dart';

import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';

class BookingContent extends StatelessWidget {
  const BookingContent({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: child,
    ),
  );
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.child,
    this.color = StayEasyColors.surface,
    this.border = StayEasyColors.border,
  });
  final Widget child;
  final Color color, border;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(StayEasySpacing.space16),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: border),
      borderRadius: StayEasyRadii.rounded20,
    ),
    child: child,
  );
}

class PriceLine extends StatelessWidget {
  const PriceLine(this.label, this.amount, {super.key, this.bold = false});
  final String label;
  final int amount;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold
                  ? StayEasyColors.textPrimary
                  : StayEasyColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ),
        Text(
          '₹${amount.toString()}',
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ],
    ),
  );
}
