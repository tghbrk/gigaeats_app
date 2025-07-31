import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'system_health_models.g.dart';

/// System Health Alert Types
enum AlertType {
  @JsonValue('low_health_score')
  lowHealthScore,
  @JsonValue('slow_edge_function')
  slowEdgeFunction,
  @JsonValue('slow_database')
  slowDatabase,
  @JsonValue('realtime_disconnected')
  realtimeDisconnected,
  @JsonValue('high_realtime_latency')
  highRealtimeLatency,
  @JsonValue('high_memory_usage')
  highMemoryUsage,
  @JsonValue('high_cpu_usage')
  highCpuUsage,
  @JsonValue('system_failure')
  systemFailure;

  String get displayName {
    switch (this) {
      case AlertType.lowHealthScore:
        return 'Low Health Score';
      case AlertType.slowEdgeFunction:
        return 'Slow Edge Function';
      case AlertType.slowDatabase:
        return 'Slow Database';
      case AlertType.realtimeDisconnected:
        return 'Realtime Disconnected';
      case AlertType.highRealtimeLatency:
        return 'High Realtime Latency';
      case AlertType.highMemoryUsage:
        return 'High Memory Usage';
      case AlertType.highCpuUsage:
        return 'High CPU Usage';
      case AlertType.systemFailure:
        return 'System Failure';
    }
  }
}

/// Alert Severity Levels
enum AlertSeverity {
  @JsonValue('info')
  info,
  @JsonValue('warning')
  warning,
  @JsonValue('critical')
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}

/// System Health Alert
@JsonSerializable()
class SystemHealthAlert extends Equatable {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final String component;
  final double value;
  final double threshold;
  final String? errorMessage;

  const SystemHealthAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.component,
    required this.value,
    required this.threshold,
    this.errorMessage,
  });

  factory SystemHealthAlert.fromJson(Map<String, dynamic> json) =>
      _$SystemHealthAlertFromJson(json);
  Map<String, dynamic> toJson() => _$SystemHealthAlertToJson(this);

  @override
  List<Object?> get props => [type, severity, message, timestamp, component, value, threshold, errorMessage];
}

/// Edge Function Health Result
@JsonSerializable()
class EdgeFunctionResult extends Equatable {
  final String functionName;
  final int responseTimeMs;
  final bool isHealthy;
  final int? statusCode;
  final String? errorMessage;

  const EdgeFunctionResult({
    required this.functionName,
    required this.responseTimeMs,
    required this.isHealthy,
    this.statusCode,
    this.errorMessage,
  });

  factory EdgeFunctionResult.fromJson(Map<String, dynamic> json) =>
      _$EdgeFunctionResultFromJson(json);
  Map<String, dynamic> toJson() => _$EdgeFunctionResultToJson(this);

  @override
  List<Object?> get props => [functionName, responseTimeMs, isHealthy, statusCode, errorMessage];
}

/// Edge Function Health Status
@JsonSerializable()
class EdgeFunctionHealth extends Equatable {
  final double healthScore;
  final double averageResponseTimeMs;
  final Map<String, EdgeFunctionResult> functionResults;
  final int totalFunctions;
  final int healthyFunctions;

  const EdgeFunctionHealth({
    required this.healthScore,
    required this.averageResponseTimeMs,
    required this.functionResults,
    required this.totalFunctions,
    required this.healthyFunctions,
  });

  factory EdgeFunctionHealth.fromJson(Map<String, dynamic> json) =>
      _$EdgeFunctionHealthFromJson(json);
  Map<String, dynamic> toJson() => _$EdgeFunctionHealthToJson(this);

  @override
  List<Object?> get props => [healthScore, averageResponseTimeMs, functionResults, totalFunctions, healthyFunctions];
}

/// Database Query Result
@JsonSerializable()
class DatabaseQueryResult extends Equatable {
  final String queryName;
  final int executionTimeMs;
  final bool isSuccessful;
  final String? errorMessage;

  const DatabaseQueryResult({
    required this.queryName,
    required this.executionTimeMs,
    required this.isSuccessful,
    this.errorMessage,
  });

  factory DatabaseQueryResult.fromJson(Map<String, dynamic> json) =>
      _$DatabaseQueryResultFromJson(json);
  Map<String, dynamic> toJson() => _$DatabaseQueryResultToJson(this);

  @override
  List<Object?> get props => [queryName, executionTimeMs, isSuccessful, errorMessage];
}

/// Database Health Status
@JsonSerializable()
class DatabaseHealth extends Equatable {
  final double healthScore;
  final double averageQueryTimeMs;
  final Map<String, DatabaseQueryResult> queryResults;
  final int totalQueries;
  final int successfulQueries;

  const DatabaseHealth({
    required this.healthScore,
    required this.averageQueryTimeMs,
    required this.queryResults,
    required this.totalQueries,
    required this.successfulQueries,
  });

  factory DatabaseHealth.fromJson(Map<String, dynamic> json) =>
      _$DatabaseHealthFromJson(json);
  Map<String, dynamic> toJson() => _$DatabaseHealthToJson(this);

  @override
  List<Object?> get props => [healthScore, averageQueryTimeMs, queryResults, totalQueries, successfulQueries];
}

/// Real-time Health Status
@JsonSerializable()
class RealtimeHealth extends Equatable {
  final double healthScore;
  final int connectionLatencyMs;
  final bool isConnected;
  final int activeSubscriptions;
  final String? errorMessage;

  const RealtimeHealth({
    required this.healthScore,
    required this.connectionLatencyMs,
    required this.isConnected,
    required this.activeSubscriptions,
    this.errorMessage,
  });

  factory RealtimeHealth.fromJson(Map<String, dynamic> json) =>
      _$RealtimeHealthFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeHealthToJson(this);

  @override
  List<Object?> get props => [healthScore, connectionLatencyMs, isConnected, activeSubscriptions, errorMessage];
}

/// System Resource Health Status
@JsonSerializable()
class SystemResourceHealth extends Equatable {
  final double healthScore;
  final double memoryUsageMb;
  final double cpuUsagePercent;
  final double diskUsagePercent;
  final double networkLatencyMs;
  final String? errorMessage;

  const SystemResourceHealth({
    required this.healthScore,
    required this.memoryUsageMb,
    required this.cpuUsagePercent,
    required this.diskUsagePercent,
    required this.networkLatencyMs,
    this.errorMessage,
  });

  factory SystemResourceHealth.fromJson(Map<String, dynamic> json) =>
      _$SystemResourceHealthFromJson(json);
  Map<String, dynamic> toJson() => _$SystemResourceHealthToJson(this);

  @override
  List<Object?> get props => [healthScore, memoryUsageMb, cpuUsagePercent, diskUsagePercent, networkLatencyMs, errorMessage];
}

/// Overall System Health Status
@JsonSerializable()
class SystemHealthStatus extends Equatable {
  final DateTime timestamp;
  final double overallHealthScore;
  final EdgeFunctionHealth edgeFunctionHealth;
  final DatabaseHealth databaseHealth;
  final RealtimeHealth realtimeHealth;
  final SystemResourceHealth systemResourceHealth;
  final int healthCheckDurationMs;

  const SystemHealthStatus({
    required this.timestamp,
    required this.overallHealthScore,
    required this.edgeFunctionHealth,
    required this.databaseHealth,
    required this.realtimeHealth,
    required this.systemResourceHealth,
    required this.healthCheckDurationMs,
  });

  factory SystemHealthStatus.fromJson(Map<String, dynamic> json) =>
      _$SystemHealthStatusFromJson(json);
  Map<String, dynamic> toJson() => _$SystemHealthStatusToJson(this);

  /// Get health status color based on score
  String get healthColor {
    if (overallHealthScore >= 90) return 'green';
    if (overallHealthScore >= 70) return 'yellow';
    return 'red';
  }

  /// Get health status description
  String get healthDescription {
    if (overallHealthScore >= 90) return 'Excellent';
    if (overallHealthScore >= 80) return 'Good';
    if (overallHealthScore >= 70) return 'Fair';
    if (overallHealthScore >= 50) return 'Poor';
    return 'Critical';
  }

  /// Check if system is healthy
  bool get isHealthy => overallHealthScore >= 80.0;

  @override
  List<Object?> get props => [
        timestamp,
        overallHealthScore,
        edgeFunctionHealth,
        databaseHealth,
        realtimeHealth,
        systemResourceHealth,
        healthCheckDurationMs,
      ];
}

/// System Health Summary for Dashboard
@JsonSerializable()
class SystemHealthSummary extends Equatable {
  final double currentHealthScore;
  final String healthStatus;
  final int activeAlerts;
  final int criticalAlerts;
  final DateTime lastHealthCheck;
  final List<String> topIssues;

  const SystemHealthSummary({
    required this.currentHealthScore,
    required this.healthStatus,
    required this.activeAlerts,
    required this.criticalAlerts,
    required this.lastHealthCheck,
    required this.topIssues,
  });

  factory SystemHealthSummary.fromJson(Map<String, dynamic> json) =>
      _$SystemHealthSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SystemHealthSummaryToJson(this);

  factory SystemHealthSummary.fromHealthStatus(
    SystemHealthStatus healthStatus,
    List<SystemHealthAlert> recentAlerts,
  ) {
    final activeAlerts = recentAlerts.where((alert) => 
        DateTime.now().difference(alert.timestamp).inHours < 1).length;
    final criticalAlerts = recentAlerts.where((alert) => 
        alert.severity == AlertSeverity.critical &&
        DateTime.now().difference(alert.timestamp).inHours < 1).length;

    final topIssues = recentAlerts
        .where((alert) => DateTime.now().difference(alert.timestamp).inHours < 1)
        .take(3)
        .map((alert) => alert.message)
        .toList();

    return SystemHealthSummary(
      currentHealthScore: healthStatus.overallHealthScore,
      healthStatus: healthStatus.healthDescription,
      activeAlerts: activeAlerts,
      criticalAlerts: criticalAlerts,
      lastHealthCheck: healthStatus.timestamp,
      topIssues: topIssues,
    );
  }

  @override
  List<Object?> get props => [currentHealthScore, healthStatus, activeAlerts, criticalAlerts, lastHealthCheck, topIssues];
}
