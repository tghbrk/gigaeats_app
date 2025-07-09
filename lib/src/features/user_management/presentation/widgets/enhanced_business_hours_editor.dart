import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vendor_profile_edit_providers.dart';

/// Enhanced business hours editor with Riverpod integration and Material Design 3 theming
class EnhancedBusinessHoursEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final bool showQuickActions;
  final bool showValidationErrors;

  const EnhancedBusinessHoursEditor({
    super.key,
    this.initialHours,
    this.onChanged,
    this.showQuickActions = true,
    this.showValidationErrors = true,
  });

  @override
  ConsumerState<EnhancedBusinessHoursEditor> createState() => _EnhancedBusinessHoursEditorState();
}

class _EnhancedBusinessHoursEditorState extends ConsumerState<EnhancedBusinessHoursEditor> {
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
    // Initialize business hours provider with current data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialHours = widget.initialHours ?? _getDefaultBusinessHours();
      ref.read(businessHoursEditProvider.notifier).initializeHours(initialHours);
    });
  }

  Map<String, dynamic> _getDefaultBusinessHours() {
    final defaultHours = <String, dynamic>{};
    for (final day in _days) {
      defaultHours[day] = {
        'is_open': day != 'sunday', // Closed on Sunday by default
        'open': '09:00',
        'close': '18:00',
      };
    }
    return defaultHours;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessHoursState = ref.watch(businessHoursEditProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            if (widget.showQuickActions) ...[
              _buildQuickActions(theme),
              const Divider(height: 24),
            ],
            _buildDaysList(theme, businessHoursState),
            if (widget.showValidationErrors && businessHoursState.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildValidationErrors(theme, businessHoursState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          'Business Hours',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showBusinessHoursHelp(context),
          icon: Icon(
            Icons.help_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          tooltip: 'Business Hours Help',
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip(
              theme,
              'Open All Days',
              Icons.check_circle_outline,
              () => _setAllDaysOpen(),
            ),
            _buildQuickActionChip(
              theme,
              'Weekdays Only',
              Icons.business,
              () => _setWeekdaysOnly(),
            ),
            _buildQuickActionChip(
              theme,
              'Copy Monday',
              Icons.content_copy,
              () => _copyMondayToAll(),
            ),
            _buildQuickActionChip(
              theme,
              'Reset',
              Icons.refresh,
              () => _resetToDefaults(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(ThemeData theme, String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDaysList(ThemeData theme, BusinessHoursEditState state) {
    return Column(
      children: _days.map((day) => _buildDayScheduleRow(theme, day, state)).toList(),
    );
  }

  Widget _buildDayScheduleRow(ThemeData theme, String day, BusinessHoursEditState state) {
    final dayData = state.hours[day] as Map<String, dynamic>?;
    final isOpen = dayData?['is_open'] ?? false;
    final openTime = dayData?['open'] ?? '09:00';
    final closeTime = dayData?['close'] ?? '18:00';
    final dayName = _dayNames[day]!;

    final hasOpenError = state.errors.containsKey('${day}_open');
    final hasCloseError = state.errors.containsKey('${day}_close');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: (hasOpenError || hasCloseError)
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
        color: isOpen
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Day name
              SizedBox(
                width: 70,
                child: Text(
                  dayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isOpen
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),

              // Open/Closed toggle
              Switch(
                value: isOpen,
                onChanged: (value) => _updateDayStatus(day, value, openTime, closeTime),
              ),

              const SizedBox(width: 12),

              // Status text
              Expanded(
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isOpen
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Copy button
              if (isOpen)
                IconButton(
                  onPressed: () => _showCopyDialog(day, openTime, closeTime),
                  icon: Icon(
                    Icons.content_copy,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  tooltip: 'Copy to other days',
                ),
            ],
          ),

          // Time pickers (only shown when open)
          if (isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 70), // Align with day name

                // Open time
                Expanded(
                  child: _buildTimeSelector(
                    theme,
                    'Open',
                    openTime,
                    hasOpenError,
                    () => _selectTime(day, true, openTime, closeTime),
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),

                // Close time
                Expanded(
                  child: _buildTimeSelector(
                    theme,
                    'Close',
                    closeTime,
                    hasCloseError,
                    () => _selectTime(day, false, openTime, closeTime),
                  ),
                ),
              ],
            ),

            // Error messages for this day
            if (hasOpenError || hasCloseError) ...[
              const SizedBox(height: 8),
              if (hasOpenError)
                _buildErrorText(theme, state.errors['${day}_open']!),
              if (hasCloseError)
                _buildErrorText(theme, state.errors['${day}_close']!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector(ThemeData theme, String label, String time, bool hasError, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError
                ? theme.colorScheme.error
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorText(ThemeData theme, String error) {
    return Row(
      children: [
        const SizedBox(width: 80),
        Expanded(
          child: Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationErrors(ThemeData theme, BusinessHoursEditState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Validation Errors',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.errors.values.map((error) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text(
                  '• $error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Helper methods
  void _updateDayStatus(String day, bool isOpen, String openTime, String closeTime) {
    ref.read(businessHoursEditProvider.notifier).updateDayHours(
      day,
      isOpen,
      isOpen ? openTime : null,
      isOpen ? closeTime : null,
    );
    _notifyChange();
  }

  Future<void> _selectTime(String day, bool isOpenTime, String currentOpenTime, String currentCloseTime) async {
    final currentTime = isOpenTime ? currentOpenTime : currentCloseTime;

    // Parse current time
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isOpenTime ? 'Select Opening Time' : 'Select Closing Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      ref.read(businessHoursEditProvider.notifier).updateDayHours(
        day,
        true,
        isOpenTime ? timeString : currentOpenTime,
        isOpenTime ? currentCloseTime : timeString,
      );
      _notifyChange();
    }
  }

  void _setAllDaysOpen() {
    ref.read(businessHoursEditProvider.notifier).applyToMultipleDays(
      _days,
      true,
      '09:00',
      '18:00',
    );
    _notifyChange();
  }

  void _setWeekdaysOnly() {
    for (final day in _days) {
      final isWeekday = day != 'saturday' && day != 'sunday';
      ref.read(businessHoursEditProvider.notifier).updateDayHours(
        day,
        isWeekday,
        isWeekday ? '09:00' : null,
        isWeekday ? '18:00' : null,
      );
    }
    _notifyChange();
  }

  void _copyMondayToAll() {
    final businessHoursState = ref.read(businessHoursEditProvider);
    final mondayData = businessHoursState.hours['monday'] as Map<String, dynamic>?;

    if (mondayData != null) {
      final isOpen = mondayData['is_open'] ?? false;
      final openTime = mondayData['open'] ?? '09:00';
      final closeTime = mondayData['close'] ?? '18:00';

      ref.read(businessHoursEditProvider.notifier).applyToMultipleDays(
        _days,
        isOpen,
        isOpen ? openTime : null,
        isOpen ? closeTime : null,
      );
      _notifyChange();
    }
  }

  void _resetToDefaults() {
    final defaultHours = _getDefaultBusinessHours();
    ref.read(businessHoursEditProvider.notifier).initializeHours(defaultHours);
    _notifyChange();
  }

  void _showCopyDialog(String sourceDay, String openTime, String closeTime) {
    final theme = Theme.of(context);
    final availableDays = _days.where((day) => day != sourceDay).toList();
    final selectedDays = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Copy ${_dayNames[sourceDay]} Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy hours ($openTime - $closeTime) to:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...availableDays.map((day) => CheckboxListTile(
                    title: Text(_dayNames[day]!),
                    value: selectedDays.contains(day),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDays.isEmpty
                  ? null
                  : () {
                      ref.read(businessHoursEditProvider.notifier).applyToMultipleDays(
                        selectedDays,
                        true,
                        openTime,
                        closeTime,
                      );
                      _notifyChange();
                      Navigator.of(context).pop();
                    },
              child: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBusinessHoursHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business Hours Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Setting Your Business Hours',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Toggle the switch to mark days as open or closed\n'
                '• Tap on time fields to set opening and closing times\n'
                '• Use quick actions for common schedules\n'
                '• Copy hours from one day to others using the copy button',
              ),
              SizedBox(height: 16),
              Text(
                'Tips',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Customers will only see your business during open hours\n'
                '• Make sure your hours reflect when you can prepare orders\n'
                '• Consider delivery time when setting closing hours\n'
                '• Update hours for holidays and special occasions',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _notifyChange() {
    final businessHoursState = ref.read(businessHoursEditProvider);
    debugPrint('🕒 [BUSINESS-HOURS-EDITOR] Notifying change');
    debugPrint('🕒 [BUSINESS-HOURS-EDITOR] Current hours: ${businessHoursState.hours}');

    if (widget.onChanged != null) {
      debugPrint('🕒 [BUSINESS-HOURS-EDITOR] Calling onChanged callback');
      widget.onChanged!(businessHoursState.hours);
    } else {
      debugPrint('🕒 [BUSINESS-HOURS-EDITOR] No onChanged callback provided');
    }
  }
}
