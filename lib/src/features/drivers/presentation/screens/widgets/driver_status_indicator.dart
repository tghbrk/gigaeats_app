import 'package:flutter/material.dart';
import '../../../user_management/domain/driver.dart';

/// Widget to display driver status with visual indicator
class DriverStatusIndicator extends StatelessWidget {
  final DriverStatus status;
  final bool showLabel;
  final double size;

  const DriverStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: statusInfo.color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            status.displayName,
            style: TextStyle(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (status) {
      case DriverStatus.online:
        return _StatusInfo(Colors.green, 'Online');
      case DriverStatus.busy:
        return _StatusInfo(Colors.orange, 'Busy');
      case DriverStatus.offline:
        return _StatusInfo(Colors.grey, 'Offline');
      case DriverStatus.unavailable:
        return _StatusInfo(Colors.red, 'Unavailable');
    }
  }
}

class _StatusInfo {
  final Color color;
  final String label;

  _StatusInfo(this.color, this.label);
}
