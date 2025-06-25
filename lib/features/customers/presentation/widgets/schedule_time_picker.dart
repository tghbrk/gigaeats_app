import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vendors/data/models/vendor.dart';
import '../../../customers/utils/vendor_utils.dart' as vendor_utils;
import '../../../../core/utils/logger.dart';

class ScheduleTimePicker extends ConsumerStatefulWidget {
  final DateTime? initialDateTime;
  final Vendor? vendor;
  final Function(DateTime?) onDateTimeSelected;
  final VoidCallback? onCancel;

  const ScheduleTimePicker({
    super.key,
    this.initialDateTime,
    this.vendor,
    required this.onDateTimeSelected,
    this.onCancel,
  });

  @override
  ConsumerState<ScheduleTimePicker> createState() => _ScheduleTimePickerState();
}

class _ScheduleTimePickerState extends ConsumerState<ScheduleTimePicker> {
  final AppLogger _logger = AppLogger();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateTime != null) {
      _selectedDate = DateTime(
        widget.initialDateTime!.year,
        widget.initialDateTime!.month,
        widget.initialDateTime!.day,
      );
      _selectedTime = TimeOfDay(
        hour: widget.initialDateTime!.hour,
        minute: widget.initialDateTime!.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Schedule Delivery',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Guidelines
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                           color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduling Guidelines',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Orders must be scheduled at least 2 hours in advance\n'
                    '• Delivery hours: 8:00 AM - 10:00 PM daily\n'
                    '• Subject to vendor business hours',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection
            _buildDateSelector(theme),
            
            const SizedBox(height: 16),
            
            // Time Selection
            _buildTimeSelector(theme),
            
            const SizedBox(height: 16),
            
            // Vendor Business Hours (if available)
            if (widget.vendor != null) _buildBusinessHoursInfo(theme),
            
            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, 
                         color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canConfirm ? _confirmSelection : null,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select delivery date',
                    style: TextStyle(
                      color: _selectedDate != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectedDate != null ? _selectTime : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedDate != null 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade200,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time, 
                  color: _selectedDate != null 
                      ? theme.colorScheme.primary 
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : _selectedDate != null 
                            ? 'Select delivery time'
                            : 'Select date first',
                    style: TextStyle(
                      color: _selectedTime != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down, 
                  color: _selectedDate != null 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursInfo(ThemeData theme) {
    final todayHours = vendor_utils.VendorUtils.getTodayHours(widget.vendor!);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Vendor Hours Today',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            todayHours,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  bool get _canConfirm => _selectedDate != null && _selectedTime != null;

  void _selectDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 7)); // Allow scheduling up to 7 days ahead
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Delivery Date',
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _selectedTime = null; // Reset time when date changes
        _errorMessage = null;
      });
    }
  }

  void _selectTime() async {
    if (_selectedDate == null) return;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Select Delivery Time',
    );
    
    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
        _errorMessage = null;
      });
      
      // Validate the selected time
      _validateSelection();
    }
  }

  void _validateSelection() {
    if (_selectedDate == null || _selectedTime == null) return;
    
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    final now = DateTime.now();
    final minimumAdvanceTime = now.add(const Duration(hours: 2));
    
    setState(() {
      _errorMessage = null;
      
      // Check advance notice
      if (selectedDateTime.isBefore(minimumAdvanceTime)) {
        _errorMessage = 'Please schedule at least 2 hours in advance';
        return;
      }
      
      // Check business hours
      if (_selectedTime!.hour < 8 || _selectedTime!.hour > 22) {
        _errorMessage = 'Delivery time must be between 8:00 AM and 10:00 PM';
        return;
      }
      
      // Check vendor business hours if available
      if (widget.vendor != null && !_isWithinVendorHours(selectedDateTime)) {
        _errorMessage = 'Selected time is outside vendor business hours';
        return;
      }
    });
  }

  bool _isWithinVendorHours(DateTime dateTime) {
    // This is a simplified check - you might want to implement more sophisticated logic
    return vendor_utils.VendorUtils.isVendorOpen(widget.vendor!);
  }

  void _confirmSelection() {
    if (_selectedDate == null || _selectedTime == null) return;
    
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    _validateSelection();
    
    if (_errorMessage == null) {
      _logger.info('ScheduleTimePicker: Selected time: $selectedDateTime');
      widget.onDateTimeSelected(selectedDateTime);
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today, ${_formatDateString(date)}';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow, ${_formatDateString(date)}';
    } else {
      return _formatDateString(date);
    }
  }

  String _formatDateString(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
