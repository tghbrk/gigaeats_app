import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../providers/enhanced_customer_order_history_providers.dart';
import '../../../data/models/customer_order_history_models.dart';

/// Calendar-based date picker with customer order count indicators
class CustomerOrderCalendarDatePicker extends ConsumerStatefulWidget {
  final Function(DateTime?)? onDateSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final bool allowRangeSelection;
  final DateTime? initialDate;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool showOrderCounts;

  const CustomerOrderCalendarDatePicker({
    super.key,
    this.onDateSelected,
    this.onDateRangeSelected,
    this.allowRangeSelection = false,
    this.initialDate,
    this.initialStartDate,
    this.initialEndDate,
    this.showOrderCounts = true,
  });

  @override
  ConsumerState<CustomerOrderCalendarDatePicker> createState() => _CustomerOrderCalendarDatePickerState();
}

class _CustomerOrderCalendarDatePickerState extends ConsumerState<CustomerOrderCalendarDatePicker> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  
  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate;
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),
            const SizedBox(height: 16),
            
            // Calendar
            _buildCalendar(theme),
            
            if (widget.allowRangeSelection) ...[
              const SizedBox(height: 16),
              _buildRangeInfo(theme),
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
          Icons.calendar_month,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.allowRangeSelection ? 'Select Date Range' : 'Select Date',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.showOrderCounts)
          Chip(
            label: const Text('Order counts'),
            avatar: Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            labelStyle: theme.textTheme.labelSmall,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar<String>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now(),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: widget.allowRangeSelection 
          ? RangeSelectionMode.toggledOn 
          : RangeSelectionMode.disabled,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      
      // Styling
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: theme.colorScheme.error),
        holidayTextStyle: TextStyle(color: theme.colorScheme.error),
        
        // Selected day styling
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        
        // Today styling
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
        
        // Range styling
        rangeStartDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        
        // Default day styling
        defaultDecoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        
        // Disabled day styling
        disabledTextStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      
      // Header styling
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle(fontWeight: FontWeight.w600),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Day of week styling
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ) ?? TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ) ?? TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Event callbacks
      onDaySelected: (selectedDay, focusedDay) {
        if (!widget.allowRangeSelection) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDateSelected?.call(selectedDay);
        }
      },
      
      onRangeSelected: widget.allowRangeSelection 
          ? (start, end, focusedDay) {
              setState(() {
                _rangeStart = start;
                _rangeEnd = end;
                _focusedDay = focusedDay;
              });
              widget.onDateRangeSelected?.call(start, end);
            }
          : null,
      
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      
      // Custom day builder with order counts
      calendarBuilders: widget.showOrderCounts
          ? CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayWithOrderCount(context, day, theme),
              selectedBuilder: (context, day, focusedDay) => _buildDayWithOrderCount(context, day, theme, isSelected: true),
              todayBuilder: (context, day, focusedDay) => _buildDayWithOrderCount(context, day, theme, isToday: true),
            )
          : CalendarBuilders(),
    );
  }

  Widget _buildDayWithOrderCount(BuildContext context, DateTime day, ThemeData theme, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    // Create a filter for this specific day
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayFilter = CustomerDateRangeFilter(
      startDate: dayStart,
      endDate: dayEnd,
      limit: 1, // We only need the count
    );

    final orderCountAsync = ref.watch(customerOrderCountProvider(dayFilter));

    Color backgroundColor;
    Color textColor;
    
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          
          // Order count indicator
          orderCountAsync.when(
            data: (count) => count > 0 
                ? Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected || isToday 
                          ? textColor.withValues(alpha: 0.7)
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox(height: 6),
            loading: () => const SizedBox(height: 6),
            error: (_, _) => const SizedBox(height: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeInfo(ThemeData theme) {
    String rangeText;
    if (_rangeStart != null && _rangeEnd != null) {
      rangeText = '${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd').format(_rangeEnd!)}';
    } else if (_rangeStart != null) {
      rangeText = 'Start: ${DateFormat('MMM dd').format(_rangeStart!)}';
    } else {
      rangeText = 'Select start and end dates';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rangeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_rangeStart != null || _rangeEnd != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                });
                widget.onDateRangeSelected?.call(null, null);
              },
              icon: const Icon(Icons.clear, size: 16),
              tooltip: 'Clear selection',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
