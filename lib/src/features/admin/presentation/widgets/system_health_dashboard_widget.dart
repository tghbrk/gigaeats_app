import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/monitoring/system_health_models.dart';
import '../../../../core/monitoring/system_health_monitoring_service.dart';

/// System Health Dashboard Widget
/// Displays real-time system health metrics and alerts for administrators
class SystemHealthDashboardWidget extends ConsumerStatefulWidget {
  const SystemHealthDashboardWidget({super.key});

  @override
  ConsumerState<SystemHealthDashboardWidget> createState() => _SystemHealthDashboardWidgetState();
}

class _SystemHealthDashboardWidgetState extends ConsumerState<SystemHealthDashboardWidget> {
  final SystemHealthMonitoringService _healthService = SystemHealthMonitoringService();
  SystemHealthStatus? _currentHealthStatus;
  List<SystemHealthAlert> _recentAlerts = [];

  @override
  void initState() {
    super.initState();
    _initializeHealthMonitoring();
  }

  Future<void> _initializeHealthMonitoring() async {
    try {
      await _healthService.initializeMonitoring();
      
      // Listen to health status updates
      _healthService.healthStatusStream.listen((status) {
        if (mounted) {
          setState(() {
            _currentHealthStatus = status;
          });
        }
      });

      // Listen to alerts
      _healthService.alertStream.listen((alert) {
        if (mounted) {
          setState(() {
            _recentAlerts = _healthService.getRecentAlerts(limit: 10);
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize health monitoring: $e');
    }
  }

  @override
  void dispose() {
    _healthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_currentHealthStatus != null) ...[
              _buildOverallHealthScore(),
              const SizedBox(height: 16),
              _buildHealthMetrics(),
              const SizedBox(height: 16),
              _buildRecentAlerts(),
            ] else
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.health_and_safety, size: 24),
        const SizedBox(width: 8),
        const Text(
          'System Health Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_currentHealthStatus != null)
          Text(
            'Last updated: ${_formatTime(_currentHealthStatus!.timestamp)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildOverallHealthScore() {
    final healthStatus = _currentHealthStatus!;
    final score = healthStatus.overallHealthScore;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getHealthColor(score).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getHealthColor(score)),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getHealthColor(score)),
            strokeWidth: 8,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Health Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${score.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _getHealthColor(score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  healthStatus.healthDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getHealthColor(score),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics() {
    final healthStatus = _currentHealthStatus!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Component Health',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildHealthMetricCard(
                'Edge Functions',
                healthStatus.edgeFunctionHealth.healthScore,
                '${healthStatus.edgeFunctionHealth.averageResponseTimeMs.toStringAsFixed(0)}ms avg',
                Icons.functions,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHealthMetricCard(
                'Database',
                healthStatus.databaseHealth.healthScore,
                '${healthStatus.databaseHealth.averageQueryTimeMs.toStringAsFixed(0)}ms avg',
                Icons.storage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildHealthMetricCard(
                'Real-time',
                healthStatus.realtimeHealth.healthScore,
                healthStatus.realtimeHealth.isConnected ? 'Connected' : 'Disconnected',
                Icons.sync,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHealthMetricCard(
                'System Resources',
                healthStatus.systemResourceHealth.healthScore,
                '${healthStatus.systemResourceHealth.memoryUsageMb.toStringAsFixed(0)}MB',
                Icons.memory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthMetricCard(String title, double score, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _getHealthColor(score)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getHealthColor(score),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            if (_recentAlerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recentAlerts.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentAlerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'No recent alerts - System is healthy',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ],
            ),
          )
        else
          Column(
            children: _recentAlerts.take(5).map((alert) => _buildAlertCard(alert)).toList(),
          ),
      ],
    );
  }

  Widget _buildAlertCard(SystemHealthAlert alert) {
    final severityColor = _getAlertSeverityColor(alert.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert.severity),
            color: severityColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${alert.component} • ${_formatTime(alert.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              alert.severity.displayName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getAlertSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.critical:
        return Icons.error;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
