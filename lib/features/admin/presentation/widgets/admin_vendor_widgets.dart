import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_vendor_provider.dart';
import '../../../../core/utils/responsive_utils.dart';

// ============================================================================
// ADMIN VENDORS TAB
// ============================================================================

/// Main admin vendors tab widget
class AdminVendorsTab extends ConsumerStatefulWidget {
  const AdminVendorsTab({super.key});

  @override
  ConsumerState<AdminVendorsTab> createState() => _AdminVendorsTabState();
}

class _AdminVendorsTabState extends ConsumerState<AdminVendorsTab> {
  @override
  void initState() {
    super.initState();
    // Load vendors when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminVendorProvider.notifier).loadVendors(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(adminVendorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminVendorProvider.notifier).loadVendors(refresh: true);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportVendors,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          const AdminVendorSearchAndFilterBar(),
          
          // Vendor Statistics
          const AdminVendorStatsBar(),
          
          // Vendor List
          Expanded(
            child: vendorState.isLoading && vendorState.vendors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vendorState.vendors.isEmpty
                    ? _buildEmptyState()
                    : ResponsiveContainer(
                        child: context.isDesktop
                            ? _buildDesktopVendorsList(vendorState.vendors)
                            : _buildMobileVendorsList(vendorState.vendors),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No vendors found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileVendorsList(List<Map<String, dynamic>> vendors) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminVendorProvider.notifier).loadVendors(refresh: true);
      },
      child: ListView.builder(
        padding: context.responsivePadding,
        itemCount: vendors.length + 1, // +1 for load more indicator
        itemBuilder: (context, index) {
          if (index == vendors.length) {
            return _buildLoadMoreIndicator();
          }
          
          final vendor = vendors[index];
          return AdminVendorCard(vendor: vendor);
        },
      ),
    );
  }

  Widget _buildDesktopVendorsList(List<Map<String, dynamic>> vendors) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: vendors.length + 1, // +1 for load more indicator
      itemBuilder: (context, index) {
        if (index == vendors.length) {
          return _buildLoadMoreIndicator();
        }
        
        final vendor = vendors[index];
        return AdminVendorCard(vendor: vendor);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    final vendorState = ref.watch(adminVendorProvider);
    
    if (!vendorState.hasMore) {
      return const SizedBox.shrink();
    }
    
    if (vendorState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            ref.read(adminVendorProvider.notifier).loadMoreVendors();
          },
          child: const Text('Load More'),
        ),
      ),
    );
  }

  void _exportVendors() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting vendors...')),
    );
  }
}

// ============================================================================
// SEARCH AND FILTER BAR
// ============================================================================

/// Search and filter bar for vendors
class AdminVendorSearchAndFilterBar extends ConsumerWidget {
  const AdminVendorSearchAndFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorState = ref.watch(adminVendorProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search vendors...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              ref.read(adminVendorProvider.notifier).updateSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Verification Status Filter
                FilterChip(
                  label: const Text('All'),
                  selected: vendorState.selectedVerificationStatus == null,
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateVerificationStatusFilter(null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: vendorState.selectedVerificationStatus == 'pending',
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateVerificationStatusFilter(selected ? 'pending' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Approved'),
                  selected: vendorState.selectedVerificationStatus == 'approved',
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateVerificationStatusFilter(selected ? 'approved' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Rejected'),
                  selected: vendorState.selectedVerificationStatus == 'rejected',
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateVerificationStatusFilter(selected ? 'rejected' : null);
                  },
                ),
                const SizedBox(width: 8),
                
                // Active Status Filter
                FilterChip(
                  label: const Text('Active Only'),
                  selected: vendorState.isActiveFilter == true,
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateActiveStatusFilter(selected ? true : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactive Only'),
                  selected: vendorState.isActiveFilter == false,
                  onSelected: (selected) {
                    ref.read(adminVendorProvider.notifier)
                        .updateActiveStatusFilter(selected ? false : null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VENDOR STATISTICS BAR
// ============================================================================

/// Statistics bar showing vendor metrics
class AdminVendorStatsBar extends ConsumerWidget {
  const AdminVendorStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorState = ref.watch(adminVendorProvider);
    
    // Calculate stats from current vendor list
    final totalVendors = vendorState.vendors.length;
    final pendingVendors = vendorState.vendors.where((v) => v['verification_status'] == 'pending').length;
    final activeVendors = vendorState.vendors.where((v) => v['is_active'] == true).length;
    final totalRevenue = vendorState.vendors.fold<double>(0, (sum, v) => sum + (v['total_revenue'] as num? ?? 0).toDouble());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total', totalVendors.toString(), Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Pending', pendingVendors.toString(), Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Active', activeVendors.toString(), Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Revenue', 'RM ${totalRevenue.toStringAsFixed(0)}', Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VENDOR CARD
// ============================================================================

/// Individual vendor card for admin management
class AdminVendorCard extends ConsumerWidget {
  final Map<String, dynamic> vendor;

  const AdminVendorCard({
    super.key,
    required this.vendor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final verificationStatus = vendor['verification_status'] as String? ?? 'pending';
    final isActive = vendor['is_active'] as bool? ?? false;
    final businessName = vendor['business_name'] as String? ?? 'Unknown';
    final rating = (vendor['rating'] as num? ?? 0).toDouble();
    final totalOrders = vendor['order_count'] as int? ?? 0;
    final totalRevenue = (vendor['total_revenue'] as num? ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewVendorDetails(context, vendor['id'] as String),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vendor Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: _getStatusColor(verificationStatus).withValues(alpha: 0.1),
                child: Icon(
                  Icons.store,
                  color: _getStatusColor(verificationStatus),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Vendor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            businessName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(verificationStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$totalOrders orders',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'RM ${totalRevenue.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              PopupMenuButton<String>(
                onSelected: (value) => _handleVendorAction(context, ref, value, vendor),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  if (verificationStatus == 'pending') ...[
                    const PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Approve'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Reject'),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit Vendor')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'suspended':
        color = Colors.orange;
        label = 'Suspended';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _viewVendorDetails(BuildContext context, String vendorId) {
    context.push('/admin/vendors/$vendorId');
  }

  void _handleVendorAction(BuildContext context, WidgetRef ref, String action, Map<String, dynamic> vendor) {
    final vendorId = vendor['id'] as String;
    final businessName = vendor['business_name'] as String;

    switch (action) {
      case 'view':
        _viewVendorDetails(context, vendorId);
        break;
      case 'approve':
        _showApprovalDialog(context, ref, vendorId, businessName);
        break;
      case 'reject':
        _showRejectionDialog(context, ref, vendorId, businessName);
        break;
      case 'activate':
      case 'deactivate':
        _toggleVendorStatus(context, ref, vendorId, businessName, action == 'activate');
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit $businessName - Coming Soon')),
        );
        break;
    }
  }

  void _showApprovalDialog(BuildContext context, WidgetRef ref, String vendorId, String businessName) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve $businessName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to approve this vendor?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(adminVendorProvider.notifier).approveVendor(
                  vendorId,
                  adminNotes: notesController.text.isEmpty ? null : notesController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$businessName approved successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error approving vendor: $e')),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, WidgetRef ref, String vendorId, String businessName) {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $businessName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }

              Navigator.of(context).pop();
              try {
                await ref.read(adminVendorProvider.notifier).rejectVendor(
                  vendorId,
                  reasonController.text,
                  adminNotes: notesController.text.isEmpty ? null : notesController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$businessName rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting vendor: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _toggleVendorStatus(BuildContext context, WidgetRef ref, String vendorId, String businessName, bool activate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${activate ? 'Activate' : 'Deactivate'} $businessName'),
        content: Text('Are you sure you want to ${activate ? 'activate' : 'deactivate'} this vendor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(adminVendorProvider.notifier).toggleVendorStatus(vendorId, activate);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$businessName ${activate ? 'activated' : 'deactivated'}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating vendor status: $e')),
                  );
                }
              }
            },
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }
}
