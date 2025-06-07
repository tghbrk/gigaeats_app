import 'package:flutter/material.dart';

import '../data/models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final bool showDetails;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Customer Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCustomerTypeColor(customer.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getCustomerTypeIcon(customer.type),
                      color: _getCustomerTypeColor(customer.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.organizationName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.contactPersonName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Customer Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCustomerTypeColor(customer.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCustomerTypeText(customer.type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getCustomerTypeColor(customer.type),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 12),
                
                // Contact Info
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      customer.phoneNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (customer.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address.fullAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Stats
                Row(
                  children: [
                    _buildStatItem(
                      context,
                      'Orders',
                      customer.totalOrders.toString(),
                      Icons.shopping_bag,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      context,
                      'Spent',
                      'RM${customer.totalSpent.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getCustomerTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.corporate:
        return Colors.indigo;
      case CustomerType.school:
        return Colors.blue;
      case CustomerType.hospital:
        return Colors.red;
      case CustomerType.government:
        return Colors.purple;
      case CustomerType.event:
        return Colors.orange;
      case CustomerType.catering:
        return Colors.green;
      case CustomerType.other:
        return Colors.grey;
    }
  }

  IconData _getCustomerTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.corporate:
        return Icons.corporate_fare;
      case CustomerType.school:
        return Icons.school;
      case CustomerType.hospital:
        return Icons.local_hospital;
      case CustomerType.government:
        return Icons.account_balance;
      case CustomerType.event:
        return Icons.event;
      case CustomerType.catering:
        return Icons.restaurant_menu;
      case CustomerType.other:
        return Icons.business;
    }
  }

  String _getCustomerTypeText(CustomerType type) {
    switch (type) {
      case CustomerType.corporate:
        return 'Corporate';
      case CustomerType.school:
        return 'School';
      case CustomerType.hospital:
        return 'Hospital';
      case CustomerType.government:
        return 'Government';
      case CustomerType.event:
        return 'Event';
      case CustomerType.catering:
        return 'Catering';
      case CustomerType.other:
        return 'Other';
    }
  }
}
