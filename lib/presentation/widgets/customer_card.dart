import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer.dart';
import '../../core/utils/responsive_utils.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: context.responsivePadding.horizontal / 2,
        vertical: 4,
      ),
      child: InkWell(
        onTap: onTap ?? () => _navigateToCustomerDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: context.responsivePadding,
          child: isDesktop ? _buildDesktopLayout(context, theme) : _buildMobileLayout(context, theme),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.organizationName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.contactPersonName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showActions) _buildActionButton(context),
          ],
        ),
        const SizedBox(height: 12),
        _buildCustomerInfo(context, theme),
        const SizedBox(height: 8),
        _buildStatsRow(context, theme),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Top row with main info
        Row(
          children: [
            _buildAvatar(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.organizationName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: customer.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customer.isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.contactPersonName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showActions) _buildActionButton(context),
          ],
        ),
        const SizedBox(height: 8),
        // Bottom row with customer info and stats
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildCustomerInfo(context, theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _buildCompactStatsRow(context, theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: _getTypeColor().withValues(alpha: 0.1),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 24,
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, ThemeData theme) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      // Compact horizontal layout for desktop
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(),
                size: 12,
                color: _getTypeColor(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.type.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${customer.address.city}, ${customer.address.state}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Original layout for mobile/tablet
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                customer.type.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${customer.address.city}, ${customer.address.state}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              customer.isActive ? Icons.check_circle : Icons.pause_circle,
              size: 16,
              color: customer.isActive ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              customer.isActive ? 'Active' : 'Inactive',
              style: theme.textTheme.bodySmall?.copyWith(
                color: customer.isActive ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          context,
          theme,
          'Orders',
          customer.totalOrders.toString(),
          Icons.receipt_long,
        ),
        _buildStatItem(
          context,
          theme,
          'Spent',
          'RM ${customer.totalSpent.toStringAsFixed(0)}',
          Icons.attach_money,
        ),
        _buildStatItem(
          context,
          theme,
          'Avg',
          'RM ${customer.averageOrderValue.toStringAsFixed(0)}',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildCompactStatsRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactStatItem(
          context,
          theme,
          'Orders',
          customer.totalOrders.toString(),
          Icons.receipt_long,
        ),
        _buildCompactStatItem(
          context,
          theme,
          'Spent',
          'RM ${customer.totalSpent.toStringAsFixed(0)}',
          Icons.attach_money,
        ),
        _buildCompactStatItem(
          context,
          theme,
          'Avg',
          'RM ${customer.averageOrderValue.toStringAsFixed(0)}',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'view':
            _navigateToCustomerDetails(context);
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('View Details'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    switch (customer.type) {
      case CustomerType.corporate:
        return Colors.blue;
      case CustomerType.school:
        return Colors.green;
      case CustomerType.hospital:
        return Colors.red;
      case CustomerType.government:
        return Colors.purple;
      case CustomerType.event:
        return Colors.orange;
      case CustomerType.catering:
        return Colors.teal;
      case CustomerType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (customer.type) {
      case CustomerType.corporate:
        return Icons.business;
      case CustomerType.school:
        return Icons.school;
      case CustomerType.hospital:
        return Icons.local_hospital;
      case CustomerType.government:
        return Icons.account_balance;
      case CustomerType.event:
        return Icons.event;
      case CustomerType.catering:
        return Icons.restaurant;
      case CustomerType.other:
        return Icons.business_center;
    }
  }

  void _navigateToCustomerDetails(BuildContext context) {
    context.push('/sales-agent/customers/${customer.id}');
  }
}
