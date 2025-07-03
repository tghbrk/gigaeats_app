import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore when vendor models and utils are implemented
// import '../../../vendors/data/models/vendor.dart';
// import '../../../user_management/application/vendor_utils.dart' as vendor_utils;
import '../../../../core/utils/logger.dart';
import '../../../data/services/schedule_delivery_validation_service.dart';

/// Enhanced schedule time picker with Material Design 3 styling and comprehensive validation
class ScheduleTimePicker extends ConsumerStatefulWidget {
  final DateTime? initialDateTime;
  // TODO: Restore when Vendor is implemented
  final dynamic vendor;
  final Function(DateTime?) onDateTimeSelected;
  final VoidCallback? onCancel;
  final String? title;
  final String? subtitle;
  final bool showBusinessHours;
  final int minimumAdvanceHours;
  final int maxDaysAhead;

  const ScheduleTimePicker({
    super.key,
    this.initialDateTime,
    this.vendor,
    required this.onDateTimeSelected,
    this.onCancel,
    this.title = 'Schedule Delivery',
    this.subtitle = 'Choose when you\'d like your order delivered',
    this.showBusinessHours = true,
    this.minimumAdvanceHours = 2,
    this.maxDaysAhead = 7,
  });

  @override
  ConsumerState<ScheduleTimePicker> createState() => _ScheduleTimePickerState();
}

class _ScheduleTimePickerState extends ConsumerState<ScheduleTimePicker>
    with SingleTickerProviderStateMixin {
  final AppLogger _logger = AppLogger();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _errorMessage;
  List<String> _warnings = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize with provided date/time
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

    // Start animation
    _animationController.forward();

    _logger.info('ScheduleTimePicker: Initialized with ${widget.initialDateTime}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header
              _buildHeader(theme),

              const SizedBox(height: 20),

              // Subtitle
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            
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
              if (widget.showBusinessHours && widget.vendor != null)
                _buildBusinessHoursInfo(theme),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorMessage(theme),
              ],

              // Warning Messages
              if (_warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWarningMessages(theme),
              ],

              const SizedBox(height: 24),

              // Enhanced Action Buttons
              _buildActionButtons(theme),
            ],
          ),
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
    // TODO: Restore when vendor_utils is implemented
    // final todayHours = vendor_utils.VendorUtils.getTodayHours(widget.vendor!);
    final todayHours = 'Business Hours: 9:00 AM - 9:00 PM'; // Placeholder
    
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

  bool get _canConfirm => _selectedDate != null && _selectedTime != null && _errorMessage == null;

  /// Build enhanced header with Material Design 3 styling
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
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title ?? 'Schedule Delivery',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _animationController.reverse().then((_) {
              if (widget.onCancel != null) {
                widget.onCancel!();
              } else {
                Navigator.of(context).pop();
              }
            });
          },
          icon: Icon(
            Icons.close,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Build enhanced error message with Material Design 3 styling
  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build warning messages with Material Design 3 styling
  Widget _buildWarningMessages(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Please Note:',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Text(
              '• $warning',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ))),
        ],
      ),
    );
  }

  /// Build enhanced action buttons with Material Design 3 styling
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _animationController.reverse().then((_) {
                if (widget.onCancel != null) {
                  widget.onCancel!();
                } else {
                  Navigator.of(context).pop();
                }
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _canConfirm ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _canConfirm ? 2 : 0,
            ),
            child: Text(
              'Confirm',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: _canConfirm
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now.add(Duration(hours: widget.minimumAdvanceHours));
    final lastDate = now.add(Duration(days: widget.maxDaysAhead));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Delivery Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _selectedTime = null; // Reset time when date changes
        _errorMessage = null;
      });

      _logger.info('ScheduleTimePicker: Date selected: $selectedDate');
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

    // Use the enhanced validation service
    final validationService = ref.read(scheduleDeliveryValidationServiceProvider);
    final validationResult = validationService.validateScheduledTime(
      scheduledTime: selectedDateTime,
      vendor: widget.vendor,
      minimumAdvanceHours: widget.minimumAdvanceHours,
      maxDaysAhead: widget.maxDaysAhead,
      checkBusinessHours: true,
      checkVendorHours: widget.vendor != null,
    );

    setState(() {
      _errorMessage = validationResult.primaryError;
      _warnings = validationResult.warnings;

      if (validationResult.isValid) {
        _logger.info('ScheduleTimePicker: Validation passed for $selectedDateTime');
        if (_warnings.isNotEmpty) {
          _logger.info('ScheduleTimePicker: Warnings: ${_warnings.join(', ')}');
        }
      } else {
        _logger.warning('ScheduleTimePicker: Validation failed: ${validationResult.errors.join(', ')}');
      }
    });
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

    // Validate the selection
    _validateSelection();

    if (_errorMessage == null) {
      _logger.info('ScheduleTimePicker: Confirmed scheduled delivery for $selectedDateTime');

      // Animate out and then call the callback
      _animationController.reverse().then((_) {
        widget.onDateTimeSelected(selectedDateTime);
        Navigator.of(context).pop();
      });
    } else {
      _logger.warning('ScheduleTimePicker: Validation failed: $_errorMessage');

      // Show a brief feedback animation for validation error
      _animationController.forward(from: 0.8);
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
