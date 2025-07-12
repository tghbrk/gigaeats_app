import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/services/enhanced_route_service.dart';

/// Widget that displays elevation profile along a route with distance markers
class ElevationProfileWidget extends StatefulWidget {
  final List<ElevationPoint> elevationProfile;
  final double height;
  final bool showGrid;
  final bool showTooltips;
  final Color? lineColor;

  const ElevationProfileWidget({
    super.key,
    required this.elevationProfile,
    this.height = 150,
    this.showGrid = true,
    this.showTooltips = true,
    this.lineColor,
  });

  @override
  State<ElevationProfileWidget> createState() => _ElevationProfileWidgetState();
}

class _ElevationProfileWidgetState extends State<ElevationProfileWidget> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.elevationProfile.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildElevationStats(theme),
            const SizedBox(height: 16),
            _buildChart(theme),
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
            Icons.terrain,
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
                'Elevation Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Route elevation changes',
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

  Widget _buildElevationStats(ThemeData theme) {
    final elevations = widget.elevationProfile.map((p) => p.elevation).toList();
    final minElevation = elevations.reduce((a, b) => a < b ? a : b);
    final maxElevation = elevations.reduce((a, b) => a > b ? a : b);
    final elevationGain = maxElevation - minElevation;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              theme,
              Icons.keyboard_arrow_up,
              'Highest',
              '${maxElevation.round()}m',
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              Icons.keyboard_arrow_down,
              'Lowest',
              '${minElevation.round()}m',
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              Icons.trending_up,
              'Gain',
              '${elevationGain.round()}m',
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(ThemeData theme) {
    final spots = widget.elevationProfile.map((point) {
      return FlSpot(point.distance, point.elevation);
    }).toList();

    final minElevation = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxElevation = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxDistance = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: widget.showGrid,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: (maxElevation - minElevation) / 4,
            verticalInterval: maxDistance / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: maxDistance / 4,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toStringAsFixed(1)}km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxElevation - minElevation) / 4,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.round()}m',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          minX: 0,
          maxX: maxDistance,
          minY: minElevation - 10,
          maxY: maxElevation + 10,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: widget.lineColor ?? theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (widget.lineColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: widget.showTooltips
              ? LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.inverseSurface,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final point = widget.elevationProfile[barSpot.spotIndex];
                        return LineTooltipItem(
                          '${point.distance.toStringAsFixed(1)}km\n${point.elevation.round()}m',
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                )
              : LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
