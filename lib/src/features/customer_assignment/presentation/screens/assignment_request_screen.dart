import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/assignment_request.dart';
import '../providers/assignment_provider.dart';

/// Screen for sales agents to search and request customer assignments
class AssignmentRequestScreen extends ConsumerStatefulWidget {
  const AssignmentRequestScreen({super.key});

  @override
  ConsumerState<AssignmentRequestScreen> createState() => _AssignmentRequestScreenState();
}

class _AssignmentRequestScreenState extends ConsumerState<AssignmentRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _selectedCustomerId;
  AssignmentRequestPriority _selectedPriority = AssignmentRequestPriority.normal;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref.read(assignmentProvider.notifier).searchAvailableCustomers(
        searchQuery: _searchController.text.trim(),
      );
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendAssignmentRequest() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get current user's sales agent ID (this would normally come from auth state)
    // For now, we'll need to implement this properly
    const salesAgentId = 'current-sales-agent-id'; // TODO: Get from auth state

    final success = await ref.read(assignmentProvider.notifier).createAssignmentRequest(
      customerId: _selectedCustomerId!,
      salesAgentId: salesAgentId,
      message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      priority: _selectedPriority,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        setState(() {
          _selectedCustomerId = null;
          _searchResults = [];
        });
        _searchController.clear();
        _messageController.clear();
        
        // Navigate back or to requests list
        context.pop();
      } else {
        final errorMessage = ref.read(assignmentProvider).errorMessage ?? 'Failed to send request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Customer Assignment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: assignmentState.isLoading
          ? const LoadingWidget(message: 'Processing request...')
          : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Available Customers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, organization, or email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _selectedCustomerId = null;
                                    });
                                  },
                                ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Debounce search
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_searchController.text == value) {
                              _searchCustomers();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search Results
              if (_searchResults.isNotEmpty) ...[
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final customer = _searchResults[index];
                      final isSelected = _selectedCustomerId == customer['id'];
                      
                      return Card(
                        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              customer['contact_person_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                            ),
                          ),
                          title: Text(customer['contact_person_name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer['organization_name'] != null)
                                Text(customer['organization_name']),
                              if (customer['email'] != null)
                                Text(
                                  customer['email'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: () {
                            setState(() {
                              _selectedCustomerId = isSelected ? null : customer['id'];
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No available customers found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Search for customers to send assignment requests',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Request Form (shown when customer is selected)
              if (_selectedCustomerId != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assignment Request Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Priority Selection
                        DropdownButtonFormField<AssignmentRequestPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: AssignmentRequestPriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(priority.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Message
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Message (Optional)',
                            hintText: 'Add a personal message to introduce yourself...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sendAssignmentRequest,
                            child: const Text('Send Assignment Request'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
