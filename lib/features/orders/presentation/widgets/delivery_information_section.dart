import 'package:flutter/material.dart';

import '../../data/models/delivery_method.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class DeliveryInformationSection extends StatelessWidget {
  final DeliveryMethod selectedDeliveryMethod;
  final DateTime? selectedDeliveryDate;
  final TimeOfDay? selectedDeliveryTime;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final TextEditingController deliveryInstructionsController;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;

  const DeliveryInformationSection({
    super.key,
    required this.selectedDeliveryMethod,
    required this.selectedDeliveryDate,
    required this.selectedDeliveryTime,
    required this.streetController,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.deliveryInstructionsController,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time Selection
            _buildDateTimeSection(context),
            
            const SizedBox(height: 20),

            // Address Section (only for delivery methods)
            if (!selectedDeliveryMethod.isPickup) ...[
              _buildAddressSection(context),
              const SizedBox(height: 20),
            ],

            // Pickup Location Info (for pickup methods)
            if (selectedDeliveryMethod.isPickup) ...[
              _buildPickupLocationInfo(context),
              const SizedBox(height: 20),
            ],

            // Delivery Instructions
            _buildInstructionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedDeliveryMethod.isPickup ? 'Pickup Schedule' : 'Delivery Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onSelectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: selectedDeliveryMethod.isPickup ? 'Pickup Date *' : 'Delivery Date *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    selectedDeliveryDate != null
                        ? '${selectedDeliveryDate!.day}/${selectedDeliveryDate!.month}/${selectedDeliveryDate!.year}'
                        : 'Select date',
                    style: selectedDeliveryDate != null 
                      ? null 
                      : TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: onSelectTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: selectedDeliveryMethod.isPickup ? 'Pickup Time' : 'Delivery Time',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  child: Text(
                    selectedDeliveryTime != null
                        ? selectedDeliveryTime!.format(context)
                        : 'Select time',
                    style: selectedDeliveryTime != null 
                      ? null 
                      : TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Street Address
        CustomTextField(
          controller: streetController,
          label: 'Street Address *',
          hintText: 'Enter complete street address',
          prefixIcon: Icons.location_on,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Street address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // City and Postal Code
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: cityController,
                label: 'City *',
                hintText: 'e.g., Kuala Lumpur',
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: postalCodeController,
                label: 'Postal Code *',
                hintText: 'e.g., 50000',
                prefixIcon: Icons.markunread_mailbox,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Postal code is required';
                  }
                  if (value.length < 5) {
                    return 'Invalid postal code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // State
        CustomTextField(
          controller: stateController,
          label: 'State *',
          hintText: 'e.g., Selangor',
          prefixIcon: Icons.map,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'State is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPickupLocationInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedDeliveryMethod == DeliveryMethod.customerPickup 
                  ? Icons.store 
                  : Icons.person_pin_circle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                selectedDeliveryMethod == DeliveryMethod.customerPickup 
                  ? 'Pickup Location' 
                  : 'Sales Agent Pickup',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedDeliveryMethod == DeliveryMethod.customerPickup
              ? 'Customer will collect the order from the vendor location. Vendor address will be provided after order confirmation.'
              : 'Sales agent will collect the order from vendor and deliver to customer. No additional delivery address required.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedDeliveryMethod.isPickup ? 'Pickup Instructions' : 'Delivery Instructions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: deliveryInstructionsController,
          label: selectedDeliveryMethod.isPickup 
            ? 'Pickup Instructions (Optional)' 
            : 'Delivery Instructions (Optional)',
          hintText: selectedDeliveryMethod.isPickup
            ? 'Any special pickup instructions...'
            : 'Any special delivery instructions...',
          prefixIcon: Icons.note_add,
          maxLines: 3,
        ),
      ],
    );
  }
}
