import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/enhanced_schedule_picker.dart';

import '../providers/checkout_flow_provider.dart';
import '../../data/services/schedule_validation_service.dart';
import '../../../user_management/domain/vendor.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/custom_button.dart';

/// Enhanced schedule management screen for order scheduling
class EnhancedScheduleManagementScreen extends ConsumerStatefulWidget {
  final DateTime? initialDateTime;
  final String? vendorId;
  final Vendor? vendor;
  final bool isModal;

  const EnhancedScheduleManagementScreen({
    super.key,
    this.initialDateTime,
    this.vendorId,
    this.vendor,
    this.isModal = false,
  });

  @override
  ConsumerState<EnhancedScheduleManagementScreen> createState() => _EnhancedScheduleManagementScreenState();
}

class _EnhancedScheduleManagementScreenState extends ConsumerState<EnhancedScheduleManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  DateTime? _selectedDateTime;
  List<TimeSlot> _availableSlots = [];
  bool _isLoadingSlots = false;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _selectedDateTime = widget.initialDateTime;
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSchedulePickerTab(theme),
            _buildAvailableSlotsTab(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Schedule Delivery',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onSurface,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Pick Time', icon: Icon(Icons.schedule)),
          Tab(text: 'Available Slots', icon: Icon(Icons.view_timeline)),
        ],
      ),
    );
  }

  Widget _buildSchedulePickerTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          EnhancedSchedulePicker(
            selectedDateTime: _selectedDateTime,
            onDateTimeChanged: _onDateTimeChanged,
            vendorId: widget.vendorId,
            vendor: widget.vendor,
            allowSameDay: true,
            minimumAdvanceHours: 2,
            maxDaysAhead: 7,
            showBusinessHours: true,
          ),
          const SizedBox(height: 24),
          _buildSelectedScheduleInfo(theme),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotsTab(ThemeData theme) {
    return Column(
      children: [
        _buildDateSelector(theme),
        Expanded(
          child: _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : _buildTimeSlotsList(theme),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When would you like your order delivered?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a convenient time for delivery. We\'ll send you notifications to keep you updated.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedScheduleInfo(ThemeData theme) {
    if (_selectedDateTime == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Scheduled Delivery',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatSelectedDateTime(_selectedDateTime!),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll deliver your order at the scheduled time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Select Date',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _selectDateForSlots,
            child: Text(
              _selectedDateTime != null 
                  ? _formatDate(_selectedDateTime!)
                  : 'Choose Date',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList(ThemeData theme) {
    if (_availableSlots.isEmpty) {
      return _buildEmptySlotsState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTimeSlotCard(theme, slot),
        );
      },
    );
  }

  Widget _buildTimeSlotCard(ThemeData theme, TimeSlot slot) {
    final isSelected = _selectedDateTime != null &&
        _selectedDateTime!.isAtSameMomentAs(slot.dateTime);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : slot.isAvailable
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: slot.isAvailable ? () => _selectTimeSlot(slot) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: slot.isAvailable 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    slot.isAvailable ? Icons.access_time : Icons.block,
                    size: 16,
                    color: slot.isAvailable 
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(TimeOfDay.fromDateTime(slot.dateTime)),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: slot.isAvailable 
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (slot.reason != null)
                        Text(
                          slot.reason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: slot.hasWarnings 
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (slot.hasWarnings)
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No time slots available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a date to view available delivery times',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_selectedDateTime != null)
              Expanded(
                child: CustomButton(
                  text: 'Clear Schedule',
                  onPressed: _clearSchedule,
                  variant: ButtonVariant.outlined,
                  icon: Icons.clear,
                ),
              ),
            if (_selectedDateTime != null) const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: _selectedDateTime != null 
                    ? 'Confirm Schedule'
                    : 'Skip Scheduling',
                onPressed: _confirmSchedule,
                variant: ButtonVariant.primary,
                icon: _selectedDateTime != null ? Icons.check : Icons.skip_next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (selectedDay == today) {
      dateStr = 'Today';
    } else if (selectedDay == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      
      dateStr = '${weekdays[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]}';
    }

    final timeStr = _formatTime(TimeOfDay.fromDateTime(dateTime));
    
    return '$dateStr at $timeStr';
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  void _onDateTimeChanged(DateTime? dateTime) {
    setState(() {
      _selectedDateTime = dateTime;
    });

    _logger.info('📅 [SCHEDULE-MANAGEMENT] DateTime changed: $dateTime');
  }

  Future<void> _selectDateForSlots() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      helpText: 'Select Date for Time Slots',
    );

    if (selectedDate != null) {
      await _loadAvailableSlots(selectedDate);
    }
  }

  Future<void> _loadAvailableSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
    });

    try {
      _logger.info('📅 [SCHEDULE-MANAGEMENT] Loading slots for: $date');

      final validationService = ScheduleValidationService();
      final slots = await validationService.getAvailableTimeSlots(
        date: date,
        vendorId: widget.vendorId,
        vendor: widget.vendor,
        minimumAdvanceHours: 2,
      );

      setState(() {
        _availableSlots = slots;
      });

      _logger.info('✅ [SCHEDULE-MANAGEMENT] Loaded ${slots.length} time slots');

    } catch (e) {
      _logger.error('❌ [SCHEDULE-MANAGEMENT] Failed to load slots', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load time slots: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  void _selectTimeSlot(TimeSlot slot) {
    setState(() {
      _selectedDateTime = slot.dateTime;
    });

    _logger.info('📅 [SCHEDULE-MANAGEMENT] Selected time slot: ${slot.dateTime}');
  }

  void _clearSchedule() {
    setState(() {
      _selectedDateTime = null;
    });

    _logger.info('🗑️ [SCHEDULE-MANAGEMENT] Schedule cleared');
  }

  void _confirmSchedule() {
    _logger.info('✅ [SCHEDULE-MANAGEMENT] Confirming schedule: $_selectedDateTime');

    // Update checkout flow with selected schedule
    if (_selectedDateTime != null) {
      ref.read(checkoutFlowProvider.notifier).setScheduledDeliveryTime(_selectedDateTime);
    }

    if (widget.isModal) {
      context.pop(_selectedDateTime);
    } else {
      context.pop();
    }
  }
}
