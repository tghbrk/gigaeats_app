import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for assigning drivers to orders
class AssignDriverDialog extends ConsumerStatefulWidget {
  final String orderId;
  final Function(String driverId) onDriverAssigned;
  
  const AssignDriverDialog({
    super.key,
    required this.orderId,
    required this.onDriverAssigned,
  });

  @override
  ConsumerState<AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<AssignDriverDialog> {
  String? selectedDriverId;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Driver'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a driver for this order:'),
            const SizedBox(height: 16),
            // In a real app, this would fetch available drivers
            ListTile(
              title: const Text('Driver 1'),
              subtitle: const Text('Available'),
              leading: Radio<String>(
                value: 'driver1',
                groupValue: selectedDriverId,
                onChanged: (value) {
                  setState(() {
                    selectedDriverId = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Driver 2'),
              subtitle: const Text('Available'),
              leading: Radio<String>(
                value: 'driver2',
                groupValue: selectedDriverId,
                onChanged: (value) {
                  setState(() {
                    selectedDriverId = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedDriverId != null
              ? () {
                  widget.onDriverAssigned(selectedDriverId!);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
