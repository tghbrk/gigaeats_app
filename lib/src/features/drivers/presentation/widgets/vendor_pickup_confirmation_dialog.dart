import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../drivers/data/models/pickup_confirmation.dart';

/// Mandatory pickup confirmation dialog that drivers must complete at vendor location
/// This dialog enforces order verification and cannot be bypassed
class VendorPickupConfirmationDialog extends ConsumerStatefulWidget {
  final DriverOrder order;
  final Function(PickupConfirmation) onConfirmed;
  final VoidCallback? onCancelled;

  const VendorPickupConfirmationDialog({
    super.key,
    required this.order,
    required this.onConfirmed,
    this.onCancelled,
  });

  @override
  ConsumerState<VendorPickupConfirmationDialog> createState() => _VendorPickupConfirmationDialogState();
}

class _VendorPickupConfirmationDialogState extends ConsumerState<VendorPickupConfirmationDialog> {
  final _notesController = TextEditingController();
  final _checklistItems = <String, bool>{};
  bool _isSubmitting = false;
  bool _allItemsVerified = false;

  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeChecklist() {
    // Initialize mandatory verification checklist
    _checklistItems.addAll({
      'Order number matches': false,
      'All items are present': false,
      'Items are properly packaged': false,
      'Special instructions noted': false,
      'Temperature requirements met': false,
    });
    _updateAllItemsVerified();
  }

  void _updateAllItemsVerified() {
    setState(() {
      _allItemsVerified = _checklistItems.values.every((checked) => checked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false, // Prevent dismissing without confirmation
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.restaurant,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Pickup Confirmation'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo(theme),
                const SizedBox(height: 20),
                _buildVerificationChecklist(theme),
                const SizedBox(height: 16),
                _buildNotesSection(theme),
                const SizedBox(height: 16),
                _buildWarningMessage(theme),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () {
              widget.onCancelled?.call();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (_allItemsVerified && !_isSubmitting) ? _confirmPickup : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Pickup'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vendor: ${widget.order.vendorName}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Customer: ${widget.order.customerName}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Items: ${widget.order.orderItemsCount} items',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Total: RM${widget.order.orderTotal.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChecklist(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Checklist',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify all items before confirming pickup:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._checklistItems.entries.map((entry) => _buildChecklistItem(
          theme,
          entry.key,
          entry.value,
          (value) {
            setState(() {
              _checklistItems[entry.key] = value;
            });
            _updateAllItemsVerified();
          },
        )),
      ],
    );
  }

  Widget _buildChecklistItem(
    ThemeData theme,
    String title,
    bool checked,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: theme.colorScheme.primary,
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special notes about the pickup...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You must verify all items before confirming pickup. This action cannot be undone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPickup() async {
    // Show final confirmation summary before submitting
    final shouldProceed = await _showFinalConfirmationSummary();
    if (!shouldProceed) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final confirmation = PickupConfirmation(
        orderId: widget.order.id,
        confirmedAt: DateTime.now(),
        verificationChecklist: Map.from(_checklistItems),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        confirmedBy: 'driver', // TODO: Get actual driver info
      );

      // Simulate network delay for processing
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirmed(confirmation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Show final confirmation summary with all verified items
  Future<bool> _showFinalConfirmationSummary() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Pickup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please confirm that you have verified all the following items:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ..._checklistItems.entries.where((entry) => entry.value).map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_notesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes: ${_notesController.text.trim()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will confirm pickup and cannot be undone.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review Again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Pickup'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

// PickupConfirmation class moved to lib/src/features/drivers/data/models/pickup_confirmation.dart
