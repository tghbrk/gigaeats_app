import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Driver orders screen
class DriverOrdersScreen extends ConsumerWidget {
  const DriverOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Mock data
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('#${index + 1}'),
              ),
              title: Text('Order #${1000 + index}'),
              subtitle: const Text('Ready for pickup'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to order details
              },
            ),
          );
        },
      ),
    );
  }
}
