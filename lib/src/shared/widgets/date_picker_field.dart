import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A custom date picker field widget with consistent styling
class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final String? label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final bool enabled;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final void Function(DateTime?)? onDateSelected;
  final String dateFormat;

  const DatePickerField({
    super.key,
    this.selectedDate,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.enabled = true,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.onDateSelected,
    this.dateFormat = 'dd/MM/yyyy',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat(dateFormat);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            required ? '$label *' : label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        TextFormField(
          controller: TextEditingController(
            text: selectedDate != null ? formatter.format(selectedDate!) : '',
          ),
          readOnly: true,
          enabled: enabled,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: enabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : theme.disabledColor,
                  )
                : null,
            suffixIcon: enabled
                ? Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.disabledColor,
              ),
            ),
            filled: true,
            fillColor: enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (validator != null) {
              return validator!(selectedDate);
            }
            if (required && selectedDate == null) {
              return 'Please select a date';
            }
            return null;
          },
          onTap: enabled ? () => _selectDate(context) : null,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? now;
    final firstSelectableDate = firstDate ?? DateTime(now.year - 100);
    final lastSelectableDate = lastDate ?? DateTime(now.year + 10);

    final selectedDateResult = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstSelectableDate)
          ? firstSelectableDate
          : initialDate.isAfter(lastSelectableDate)
              ? lastSelectableDate
              : initialDate,
      firstDate: firstSelectableDate,
      lastDate: lastSelectableDate,
      helpText: 'Select Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
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

    if (selectedDateResult != null) {
      onDateSelected?.call(selectedDateResult);
    }
  }
}

/// Specialized date picker for future dates (appointments, deliveries, etc.)
class FutureDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final void Function(DateTime?)? onDateSelected;
  final String? Function(DateTime?)? validator;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool required;
  final int maxDaysAhead;

  const FutureDatePicker({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.validator,
    this.label,
    this.hintText,
    this.enabled = true,
    this.required = false,
    this.maxDaysAhead = 30,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxDate = now.add(Duration(days: maxDaysAhead));

    return DatePickerField(
      selectedDate: selectedDate,
      label: label ?? 'Select Date',
      hintText: hintText ?? 'Choose a future date',
      prefixIcon: Icons.event_outlined,
      enabled: enabled,
      required: required,
      firstDate: now,
      lastDate: maxDate,
      onDateSelected: onDateSelected,
      validator: validator ??
          (date) {
            if (required && date == null) {
              return 'Please select a date';
            }
            if (date != null && date.isBefore(now)) {
              return 'Please select a future date';
            }
            return null;
          },
    );
  }
}
