import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Driver profile screen
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to edit profile
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Name'),
                subtitle: Text('Driver Name'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone'),
                subtitle: Text('+60123456789'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text('driver@gigaeats.com'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Vehicle'),
                subtitle: Text('Motorcycle - ABC1234'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
