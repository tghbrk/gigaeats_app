import 'package:flutter/material.dart';
import '../../../../user_management/application/vendor_utils.dart';
import '../../../vendors/data/models/vendor.dart';

class VendorBusinessHoursWidget extends StatelessWidget {
  final Vendor vendor;
  final bool showFullSchedule;

  const VendorBusinessHoursWidget({
    super.key,
    required this.vendor,
    this.showFullSchedule = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = VendorUtils.isVendorOpen(vendor);
    final statusText = VendorUtils.getVendorStatusText(vendor);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current status
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: isOpen ? Colors.green[600] : Colors.red[600],
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOpen ? Colors.green[600] : Colors.red[600],
                ),
              ),
              const Spacer(),
              if (!showFullSchedule)
                TextButton(
                  onPressed: () => _showFullSchedule(context),
                  child: const Text('View Hours'),
                ),
            ],
          ),
          
          // Today's hours
          if (!showFullSchedule) ...[
            const SizedBox(height: 8),
            Text(
              'Today: ${VendorUtils.getTodayHours(vendor)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          // Full schedule
          if (showFullSchedule) ...[
            const SizedBox(height: 16),
            _buildFullSchedule(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFullSchedule(BuildContext context) {
    final theme = Theme.of(context);
    final businessHours = vendor.businessHours;
    
    if (businessHours == null || businessHours.isEmpty) {
      return Text(
        'Business hours not specified',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
      );
    }

    final days = [
      {'key': 'monday', 'name': 'Monday'},
      {'key': 'tuesday', 'name': 'Tuesday'},
      {'key': 'wednesday', 'name': 'Wednesday'},
      {'key': 'thursday', 'name': 'Thursday'},
      {'key': 'friday', 'name': 'Friday'},
      {'key': 'saturday', 'name': 'Saturday'},
      {'key': 'sunday', 'name': 'Sunday'},
    ];

    final now = DateTime.now();
    final todayKey = _getDayName(now.weekday);

    return Column(
      children: days.map((day) {
        final dayKey = day['key']!;
        final dayName = day['name']!;
        final isToday = dayKey == todayKey;
        final daySchedule = businessHours[dayKey];
        
        String hoursText = 'Closed';
        if (daySchedule != null) {
          final isOpen = daySchedule['isOpen'] as bool? ?? false;
          if (isOpen) {
            final openTime = daySchedule['openTime'] as String?;
            final closeTime = daySchedule['closeTime'] as String?;
            if (openTime != null && closeTime != null) {
              hoursText = '$openTime - $closeTime';
            } else {
              hoursText = 'Open';
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isToday ? theme.primaryColor.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  dayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isToday ? theme.primaryColor : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  hoursText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isToday ? theme.primaryColor : Colors.grey[600],
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFullSchedule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Business Hours',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Full schedule
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: VendorBusinessHoursWidget(
                    vendor: vendor,
                    showFullSchedule: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to get day name
String _getDayName(int weekday) {
  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  return days[weekday - 1];
}
