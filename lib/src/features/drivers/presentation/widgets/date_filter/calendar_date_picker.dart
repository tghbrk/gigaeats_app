import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Calendar-based date picker with order count indicators
class OrderHistoryCalendarDatePicker extends ConsumerStatefulWidget {
  final Function(DateTime?)? onDateSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final bool allowRangeSelection;
  final DateTime? initialDate;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const OrderHistoryCalendarDatePicker({
    super.key,
    this.onDateSelected,
    this.onDateRangeSelected,
    this.allowRangeSelection = false,
    this.initialDate,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  ConsumerState<OrderHistoryCalendarDatePicker> createState() => _OrderHistoryCalendarDatePickerState();
}

class _OrderHistoryCalendarDatePickerState extends ConsumerState<OrderHistoryCalendarDatePicker> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Map<String, int> _dailyStats = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate;
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _loadDailyStats();
  }

  Future<void> _loadDailyStats() async {
    try {
      // Get current driver ID and load daily stats
      final authState = ref.read(authStateProvider);
      if (authState.user?.id != null) {
        final supabase = Supabase.instance.client;
        final driverResponse = await supabase
            .from('drivers')
            .select('id')
            .eq('user_id', authState.user!.id)
            .maybeSingle();

        if (driverResponse != null) {
          final driverId = driverResponse['id'] as String;
          final stats = await ref.read(dailyOrderStatsProvider(driverId).future);
          setState(() {
            _dailyStats = stats;
          });
        }
      }
    } catch (e) {
      debugPrint('🚗 Calendar: Error loading daily stats: $e');
    }
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_focusedDay),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Column(
      children: [
        // Weekday headers
        _buildWeekdayHeaders(theme),
        const SizedBox(height: 8),
        
        // Calendar grid
        _buildCalendarGrid(theme),
      ],
    );
  }

  Widget _buildWeekdayHeaders(ThemeData theme) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Row(
      children: weekdays.map((weekday) {
        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfWeek; i++) {
      days.add(const SizedBox());
    }
    
    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      days.add(_buildDayCell(theme, date));
    }
    
    // Create rows of 7 days each
    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      final rowDays = days.sublist(i, (i + 7).clamp(0, days.length));
      while (rowDays.length < 7) {
        rowDays.add(const SizedBox());
      }
      rows.add(
        Row(
          children: rowDays.map((day) => Expanded(child: day)).toList(),
        ),
      );
    }
    
    return Column(children: rows);
  }

  Widget _buildDayCell(ThemeData theme, DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    final orderCount = _dailyStats[dateKey] ?? 0;
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
    final isInRange = _isInRange(date);
    final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isPastDate = date.isAfter(DateTime.now());

    Color? backgroundColor;
    Color? foregroundColor;
    BorderRadius? borderRadius;

    if (isSelected || isRangeStart || isRangeEnd) {
      backgroundColor = theme.colorScheme.primary;
      foregroundColor = theme.colorScheme.onPrimary;
      borderRadius = BorderRadius.circular(20);
    } else if (isInRange) {
      backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
      foregroundColor = theme.colorScheme.onSurface;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer;
      foregroundColor = theme.colorScheme.onPrimaryContainer;
      borderRadius = BorderRadius.circular(20);
    }

    return GestureDetector(
      onTap: isPastDate ? null : () => _onDaySelected(date),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: isToday && !isSelected 
              ? Border.all(color: theme.colorScheme.primary, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPastDate 
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : foregroundColor ?? theme.colorScheme.onSurface,
                fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (orderCount > 0 && !isPastDate)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: foregroundColor?.withValues(alpha: 0.7) ?? 
                         theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeInfo(ThemeData theme) {
    if (_rangeStart == null && _rangeEnd == null) {
      return Text(
        'Tap dates to select a range',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    String rangeText = '';
    if (_rangeStart != null && _rangeEnd != null) {
      final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      rangeText = '${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd').format(_rangeEnd!)} ($days days)';
    } else if (_rangeStart != null) {
      rangeText = 'From ${DateFormat('MMM dd').format(_rangeStart!)}';
    } else if (_rangeEnd != null) {
      rangeText = 'Until ${DateFormat('MMM dd').format(_rangeEnd!)}';
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

  void _onDaySelected(DateTime selectedDay) {
    if (widget.allowRangeSelection) {
      setState(() {
        if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
          // Start new range
          _rangeStart = selectedDay;
          _rangeEnd = null;
        } else if (_rangeStart != null && _rangeEnd == null) {
          // Complete range
          if (selectedDay.isBefore(_rangeStart!)) {
            _rangeEnd = _rangeStart;
            _rangeStart = selectedDay;
          } else {
            _rangeEnd = selectedDay;
          }
        }
      });
      widget.onDateRangeSelected?.call(_rangeStart, _rangeEnd);
    } else {
      setState(() {
        _selectedDay = selectedDay;
      });
      widget.onDateSelected?.call(selectedDay);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return date.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
           date.isBefore(_rangeEnd!.add(const Duration(days: 1)));
  }
}
