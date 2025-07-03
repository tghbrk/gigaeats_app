import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/schedule_validation_service.dart';
import '../../../user_management/domain/vendor.dart';
import '../../../core/utils/logger.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced schedule picker with business hours validation
class EnhancedSchedulePicker extends ConsumerStatefulWidget {
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime?> onDateTimeChanged;
  final String? vendorId;
  final Vendor? vendor;
  final bool allowSameDay;
  final int minimumAdvanceHours;
  final int maxDaysAhead;
  final bool showBusinessHours;

  const EnhancedSchedulePicker({
    super.key,
    this.selectedDateTime,
    required this.onDateTimeChanged,
    this.vendorId,
    this.vendor,
    this.allowSameDay = true,
    this.minimumAdvanceHours = 2,
    this.maxDaysAhead = 7,
    this.showBusinessHours = true,
  });

  @override
  ConsumerState<EnhancedSchedulePicker> createState() => _EnhancedSchedulePickerState();
}

class _EnhancedSchedulePickerState extends ConsumerState<EnhancedSchedulePicker>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isValidating = false;
  ScheduleValidationResult? _validationResult;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _initializeFromSelected();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeFromSelected() {
    if (widget.selectedDateTime != null) {
      _selectedDate = DateTime(
        widget.selectedDateTime!.year,
        widget.selectedDateTime!.month,
        widget.selectedDateTime!.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(widget.selectedDateTime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildDateTimeSelectors(theme),
                  const SizedBox(height: 16),
                  if (widget.showBusinessHours) ...[
                    _buildBusinessHoursInfo(theme),
                    const SizedBox(height: 16),
                  ],
                  _buildQuickOptions(theme),
                  if (_validationResult != null) ...[
                    const SizedBox(height: 16),
                    _buildValidationResult(theme),
                  ],
                  const SizedBox(height: 16),
                  _buildSchedulingGuidelines(theme),
                ],
              ),
            ),
            if (_isValidating)
              const SimpleLoadingOverlay(
                message: 'Validating schedule...',
                backgroundColor: Colors.transparent,
              ),
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
            Icons.schedule,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Delivery',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose when you\'d like your order delivered',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelectors(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildDateSelector(theme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimeSelector(theme),
        ),
      ],
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedDate != null 
                      ? _formatDate(_selectedDate!)
                      : 'Select date',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _selectedDate != null 
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedDate != null ? _selectTime : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: _selectedDate != null 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Time',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _selectedDate != null 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTime != null 
                      ? _formatTime(_selectedTime!)
                      : _selectedDate != null 
                          ? 'Select time'
                          : 'Select date first',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _selectedTime != null 
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHoursInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getBusinessHoursText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptions(ThemeData theme) {
    final now = DateTime.now();
    final quickOptions = _getQuickOptions(now);

    if (quickOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Options',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickOptions.map((option) {
            return FilterChip(
              selected: false,
              onSelected: (selected) {
                if (selected) {
                  _selectQuickOption(option);
                }
              },
              label: Text(option.label),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildValidationResult(ThemeData theme) {
    final result = _validationResult!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isValid 
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isValid 
              ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.isValid ? Icons.check_circle : Icons.error,
            size: 16,
            color: result.isValid 
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isValid ? 'Schedule Valid' : 'Schedule Issue',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: result.isValid 
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                  ),
                ),
                if (result.message != null)
                  Text(
                    result.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingGuidelines(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Scheduling Guidelines',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(theme, 'Minimum ${widget.minimumAdvanceHours} hours advance notice required'),
          _buildGuidelineItem(theme, 'Delivery available during business hours (8:00 AM - 10:00 PM)'),
          _buildGuidelineItem(theme, 'Schedule up to ${widget.maxDaysAhead} days in advance'),
          if (!widget.allowSameDay)
            _buildGuidelineItem(theme, 'Same-day delivery not available'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  String _getBusinessHoursText() {
    if (widget.vendor != null) {
      // TODO: Get actual business hours from vendor
      return 'Business Hours: 9:00 AM - 9:00 PM';
    }
    return 'Delivery Hours: 8:00 AM - 10:00 PM';
  }

  List<QuickScheduleOption> _getQuickOptions(DateTime now) {
    final options = <QuickScheduleOption>[];
    
    // Add "In 2 hours" if it's within business hours
    final in2Hours = now.add(Duration(hours: widget.minimumAdvanceHours));
    if (in2Hours.hour >= 8 && in2Hours.hour <= 22) {
      options.add(QuickScheduleOption(
        label: 'In ${widget.minimumAdvanceHours} hours',
        dateTime: in2Hours,
      ));
    }

    // Add "Tomorrow morning" (9 AM)
    final tomorrow9AM = DateTime(now.year, now.month, now.day + 1, 9, 0);
    options.add(QuickScheduleOption(
      label: 'Tomorrow 9:00 AM',
      dateTime: tomorrow9AM,
    ));

    // Add "Tomorrow evening" (6 PM)
    final tomorrow6PM = DateTime(now.year, now.month, now.day + 1, 18, 0);
    options.add(QuickScheduleOption(
      label: 'Tomorrow 6:00 PM',
      dateTime: tomorrow6PM,
    ));

    return options;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = widget.allowSameDay ? now : now.add(const Duration(days: 1));
    final lastDate = now.add(Duration(days: widget.maxDaysAhead));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Delivery Date',
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _selectedTime = null; // Reset time when date changes
        _validationResult = null;
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Select Delivery Time',
    );

    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
      });

      await _validateAndNotify();
    }
  }

  void _selectQuickOption(QuickScheduleOption option) {
    setState(() {
      _selectedDate = DateTime(
        option.dateTime.year,
        option.dateTime.month,
        option.dateTime.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(option.dateTime);
    });

    _validateAndNotify();
  }

  Future<void> _validateAndNotify() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() {
      _isValidating = true;
    });

    try {
      final validationService = ScheduleValidationService();
      final result = await validationService.validateSchedule(
        dateTime: selectedDateTime,
        vendorId: widget.vendorId,
        vendor: widget.vendor,
        minimumAdvanceHours: widget.minimumAdvanceHours,
        allowSameDay: widget.allowSameDay,
      );

      setState(() {
        _validationResult = result;
      });

      if (result.isValid) {
        widget.onDateTimeChanged(selectedDateTime);
      } else {
        widget.onDateTimeChanged(null);
      }

      _logger.info('📅 [SCHEDULE-PICKER] Schedule validation: ${result.isValid}');

    } catch (e) {
      _logger.error('❌ [SCHEDULE-PICKER] Validation failed', e);
      
      setState(() {
        _validationResult = ScheduleValidationResult(
          isValid: false,
          message: 'Failed to validate schedule: ${e.toString()}',
        );
      });
      
      widget.onDateTimeChanged(null);
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }
}

/// Quick schedule option
class QuickScheduleOption {
  final String label;
  final DateTime dateTime;

  const QuickScheduleOption({
    required this.label,
    required this.dateTime,
  });
}
