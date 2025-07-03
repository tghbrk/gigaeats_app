import 'package:flutter/material.dart';

class BusinessHoursEditor extends StatefulWidget {
  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const BusinessHoursEditor({
    super.key,
    this.initialHours,
    required this.onChanged,
  });

  @override
  State<BusinessHoursEditor> createState() => _BusinessHoursEditorState();
}

class _BusinessHoursEditorState extends State<BusinessHoursEditor> {
  late Map<String, DaySchedule> _schedule;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }

  void _initializeSchedule() {
    _schedule = {};
    
    for (final day in _days) {
      if (widget.initialHours != null && widget.initialHours!.containsKey(day)) {
        final dayData = widget.initialHours![day] as Map<String, dynamic>?;
        _schedule[day] = DaySchedule(
          isOpen: dayData?['isOpen'] ?? false,
          openTime: dayData?['openTime'] ?? '09:00',
          closeTime: dayData?['closeTime'] ?? '18:00',
        );
      } else {
        // Default schedule
        _schedule[day] = DaySchedule(
          isOpen: day != 'sunday', // Closed on Sunday by default
          openTime: '09:00',
          closeTime: '18:00',
        );
      }
    }
  }

  void _updateSchedule() {
    final scheduleMap = <String, dynamic>{};
    for (final entry in _schedule.entries) {
      scheduleMap[entry.key] = {
        'isOpen': entry.value.isOpen,
        'openTime': entry.value.openTime,
        'closeTime': entry.value.closeTime,
      };
    }
    widget.onChanged(scheduleMap);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Business Hours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _setAllDaysOpen,
                    icon: Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Open All Days'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _setWeekdaysOnly,
                    icon: Icon(Icons.business, size: 16),
                    label: const Text('Weekdays Only'),
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Day Schedule List
            ..._days.map((day) => _buildDayScheduleRow(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayScheduleRow(String day) {
    final schedule = _schedule[day]!;
    final dayName = _dayNames[day]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Day name
              SizedBox(
                width: 80,
                child: Text(
                  dayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

              // Open/Closed toggle
              Switch(
                value: schedule.isOpen,
                onChanged: (value) {
                  setState(() {
                    _schedule[day] = schedule.copyWith(isOpen: value);
                  });
                  _updateSchedule();
                },
              ),

              const SizedBox(width: 8),

              // Status text
              Expanded(
                child: Text(
                  schedule.isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: schedule.isOpen ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Time pickers (only shown when open)
          if (schedule.isOpen) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 80), // Align with day name

                // Open time
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(day, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            schedule.openTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                const Text('to', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),

                // Close time
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(day, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            schedule.closeTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final schedule = _schedule[day]!;
    final currentTime = isOpenTime ? schedule.openTime : schedule.closeTime;
    
    // Parse current time
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isOpenTime) {
          _schedule[day] = schedule.copyWith(openTime: timeString);
        } else {
          _schedule[day] = schedule.copyWith(closeTime: timeString);
        }
      });
      _updateSchedule();
    }
  }

  void _setAllDaysOpen() {
    setState(() {
      for (final day in _days) {
        _schedule[day] = _schedule[day]!.copyWith(isOpen: true);
      }
    });
    _updateSchedule();
  }

  void _setWeekdaysOnly() {
    setState(() {
      for (final day in _days) {
        final isWeekday = day != 'saturday' && day != 'sunday';
        _schedule[day] = _schedule[day]!.copyWith(isOpen: isWeekday);
      }
    });
    _updateSchedule();
  }
}

class DaySchedule {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  DaySchedule copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}
