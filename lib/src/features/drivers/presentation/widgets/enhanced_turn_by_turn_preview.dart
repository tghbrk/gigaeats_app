import 'package:flutter/material.dart';

import '../../data/services/enhanced_route_service.dart';

/// Enhanced turn-by-turn preview with detailed road information and visual indicators
class EnhancedTurnByTurnPreview extends StatefulWidget {
  final List<RouteStep> steps;
  final int maxStepsToShow;
  final bool showRoadNames;
  final bool showDistances;
  final bool isExpandable;

  const EnhancedTurnByTurnPreview({
    super.key,
    required this.steps,
    this.maxStepsToShow = 5,
    this.showRoadNames = true,
    this.showDistances = true,
    this.isExpandable = true,
  });

  @override
  State<EnhancedTurnByTurnPreview> createState() => _EnhancedTurnByTurnPreviewState();
}

class _EnhancedTurnByTurnPreviewState extends State<EnhancedTurnByTurnPreview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final stepsToShow = _isExpanded 
        ? widget.steps 
        : widget.steps.take(widget.maxStepsToShow).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildStepsList(theme, stepsToShow),
            if (widget.isExpandable && widget.steps.length > widget.maxStepsToShow)
              _buildExpandButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.alt_route,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Turn-by-Turn Directions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.steps.length} steps total',
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

  Widget _buildStepsList(ThemeData theme, List<RouteStep> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        
        return _buildStepItem(theme, step, index + 1, isLast);
      }).toList(),
    );
  }

  Widget _buildStepItem(ThemeData theme, RouteStep step, int stepNumber, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(theme, step, stepNumber, isLast),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStepContent(theme, step),
          ),
          if (widget.showDistances)
            _buildDistanceIndicator(theme, step),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, RouteStep step, int stepNumber, bool isLast) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: Icon(
            _getManeuverIcon(step.maneuver),
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 20,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
      ],
    );
  }

  Widget _buildStepContent(ThemeData theme, RouteStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.instruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.showRoadNames && step.roadName != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.roadName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (step.duration > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${step.duration} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDistanceIndicator(ThemeData theme, RouteStep step) {
    final distance = step.distance;
    final distanceText = distance < 1 
        ? '${(distance * 1000).round()}m'
        : '${distance.toStringAsFixed(1)}km';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        distanceText,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildExpandButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          label: Text(
            _isExpanded 
                ? 'Show Less' 
                : 'Show ${widget.steps.length - widget.maxStepsToShow} More Steps',
          ),
        ),
      ),
    );
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_left;
      case 'keep-left':
        return Icons.arrow_forward;
      case 'keep-right':
        return Icons.arrow_forward;
      case 'continue':
      case 'straight':
        return Icons.straight;
      case 'destination':
        return Icons.location_on;
      default:
        return Icons.navigation;
    }
  }
}
