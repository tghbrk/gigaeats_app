import 'package:flutter/material.dart';

/// Reusable feature chip widget for displaying dietary and product features
/// Used for Halal, Vegetarian, Spicy, and other product attributes
class FeatureChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double? fontSize;
  final EdgeInsets? padding;

  const FeatureChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize ?? 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Predefined feature chips for common dietary attributes
  static FeatureChip halal() => const FeatureChip(
        label: 'Halal',
        color: Colors.green,
        icon: Icons.verified,
      );

  static FeatureChip vegetarian() => const FeatureChip(
        label: 'Vegetarian',
        color: Colors.orange,
        icon: Icons.eco,
      );

  static FeatureChip spicy() => const FeatureChip(
        label: 'Spicy',
        color: Colors.red,
        icon: Icons.local_fire_department,
      );

  static FeatureChip unavailable() => const FeatureChip(
        label: 'Unavailable',
        color: Colors.grey,
        icon: Icons.block,
      );

  static FeatureChip popular() => const FeatureChip(
        label: 'Popular',
        color: Colors.purple,
        icon: Icons.trending_up,
      );

  static FeatureChip newItem() => const FeatureChip(
        label: 'New',
        color: Colors.blue,
        icon: Icons.fiber_new,
      );
}
