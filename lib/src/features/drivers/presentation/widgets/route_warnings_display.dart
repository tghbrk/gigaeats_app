import 'package:flutter/material.dart';

/// Widget that displays route warnings and alerts with appropriate severity indicators
class RouteWarningsDisplay extends StatelessWidget {
  final List<RouteWarning> warnings;
  final bool showSeverityIcons;
  final bool isCollapsible;

  const RouteWarningsDisplay({
    super.key,
    required this.warnings,
    this.showSeverityIcons = true,
    this.isCollapsible = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _buildWarningsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final highPriorityCount = warnings.where((w) => w.severity == WarningSeverity.high).length;
    final mediumPriorityCount = warnings.where((w) => w.severity == WarningSeverity.medium).length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getHeaderColor(theme),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: _getHeaderIconColor(theme),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Alerts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${warnings.length} alert${warnings.length != 1 ? 's' : ''}'
                '${highPriorityCount > 0 ? ' • $highPriorityCount high priority' : ''}'
                '${mediumPriorityCount > 0 ? ' • $mediumPriorityCount medium priority' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningsList(ThemeData theme) {
    // Sort warnings by severity (high -> medium -> low)
    final sortedWarnings = List<RouteWarning>.from(warnings);
    sortedWarnings.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return Column(
      children: sortedWarnings.map((warning) => _buildWarningItem(theme, warning)).toList(),
    );
  }

  Widget _buildWarningItem(ThemeData theme, RouteWarning warning) {
    final severityColor = _getSeverityColor(warning.severity);
    final severityIcon = _getSeverityIcon(warning.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSeverityIcons) ...[
            Icon(
              severityIcon,
              color: severityColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
                if (warning.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    warning.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (warning.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warning.location!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeaderColor(ThemeData theme) {
    final hasHighPriority = warnings.any((w) => w.severity == WarningSeverity.high);
    if (hasHighPriority) {
      return Colors.red.withValues(alpha: 0.1);
    }
    
    final hasMediumPriority = warnings.any((w) => w.severity == WarningSeverity.medium);
    if (hasMediumPriority) {
      return Colors.orange.withValues(alpha: 0.1);
    }
    
    return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
  }

  Color _getHeaderIconColor(ThemeData theme) {
    final hasHighPriority = warnings.any((w) => w.severity == WarningSeverity.high);
    if (hasHighPriority) {
      return Colors.red;
    }
    
    final hasMediumPriority = warnings.any((w) => w.severity == WarningSeverity.medium);
    if (hasMediumPriority) {
      return Colors.orange;
    }
    
    return theme.colorScheme.primary;
  }

  IconData _getHeaderIcon() {
    final hasHighPriority = warnings.any((w) => w.severity == WarningSeverity.high);
    if (hasHighPriority) {
      return Icons.error;
    }
    
    return Icons.warning;
  }

  Color _getSeverityColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.high:
        return Colors.red;
      case WarningSeverity.medium:
        return Colors.orange;
      case WarningSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.high:
        return Icons.error;
      case WarningSeverity.medium:
        return Icons.warning;
      case WarningSeverity.low:
        return Icons.info;
    }
  }
}

/// Enum for warning severity levels
enum WarningSeverity {
  low,
  medium,
  high,
}

/// Model class for route warnings
class RouteWarning {
  final String title;
  final String description;
  final WarningSeverity severity;
  final String? location;
  final WarningType type;

  const RouteWarning({
    required this.title,
    required this.description,
    required this.severity,
    this.location,
    required this.type,
  });

  factory RouteWarning.fromString(String warningText) {
    // Parse common warning patterns
    if (warningText.toLowerCase().contains('construction')) {
      return RouteWarning(
        title: 'Road Construction',
        description: warningText,
        severity: WarningSeverity.medium,
        type: WarningType.construction,
      );
    } else if (warningText.toLowerCase().contains('accident')) {
      return RouteWarning(
        title: 'Traffic Accident',
        description: warningText,
        severity: WarningSeverity.high,
        type: WarningType.accident,
      );
    } else if (warningText.toLowerCase().contains('closure')) {
      return RouteWarning(
        title: 'Road Closure',
        description: warningText,
        severity: WarningSeverity.high,
        type: WarningType.closure,
      );
    } else if (warningText.toLowerCase().contains('weather')) {
      return RouteWarning(
        title: 'Weather Alert',
        description: warningText,
        severity: WarningSeverity.medium,
        type: WarningType.weather,
      );
    } else {
      return RouteWarning(
        title: 'Route Alert',
        description: warningText,
        severity: WarningSeverity.low,
        type: WarningType.general,
      );
    }
  }
}

/// Enum for warning types
enum WarningType {
  construction,
  accident,
  closure,
  weather,
  traffic,
  general,
}
