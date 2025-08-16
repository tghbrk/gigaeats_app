import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_activity_log.dart';

/// Audit log card widget
class AuditLogCard extends StatelessWidget {
  final AdminActivityLog log;
  final VoidCallback? onTap;

  const AuditLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with action and timestamp
              Row(
                children: [
                  // Action type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActionColor(log.actionType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getActionColor(log.actionType).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      log.actionType.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getActionColor(log.actionType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Timestamp
                  Text(
                    DateFormat('MMM dd, HH:mm').format(log.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Admin and target info
              Row(
                children: [
                  // Admin info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.adminName ?? log.adminUserId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (log.adminEmail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            log.adminEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                  
                  // Target info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log.targetType.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.targetName ?? log.targetId ?? 'N/A',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Description if available
              if (log.description != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.description!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              
              // Details preview
              if (log.details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${log.details.length} detail${log.details.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap for details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
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

  Color _getActionColor(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'user_created':
      case 'user_activated':
      case 'vendor_approved':
        return Colors.green;
      case 'user_deleted':
      case 'user_deactivated':
      case 'vendor_suspended':
      case 'order_cancelled':
        return Colors.red;
      case 'user_updated':
      case 'system_setting_updated':
        return Colors.blue;
      case 'login_failure':
      case 'security_alert':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Audit log filter dialog
class AuditLogFilterDialog extends StatefulWidget {
  final ActivityLogFilter currentFilter;
  final Function(ActivityLogFilter) onApplyFilter;

  const AuditLogFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<AuditLogFilterDialog> createState() => _AuditLogFilterDialogState();
}

class _AuditLogFilterDialogState extends State<AuditLogFilterDialog> {
  late ActivityLogFilter _filter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    
    if (_filter.startDate != null && _filter.endDate != null) {
      _dateRange = DateTimeRange(
        start: _filter.startDate!,
        end: _filter.endDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Audit Logs'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action Type
            DropdownButtonFormField<String?>(
              initialValue: _filter.actionType,
              decoration: const InputDecoration(
                labelText: 'Action Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Actions')),
                ...AdminActionType.allActionTypes.map((action) => DropdownMenuItem(
                  value: action,
                  child: Text(action.replaceAll('_', ' ').toUpperCase()),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(actionType: value);
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Target Type
            DropdownButtonFormField<String?>(
              initialValue: _filter.targetType,
              decoration: const InputDecoration(
                labelText: 'Target Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Targets')),
                ...AdminTargetType.allTargetTypes.map((target) => DropdownMenuItem(
                  value: target,
                  child: Text(target.toUpperCase()),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(targetType: value);
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date Range
            ListTile(
              title: const Text('Date Range'),
              subtitle: Text(_dateRange != null
                  ? '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}'
                  : 'All dates'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _selectDateRange,
                  ),
                  if (_dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _dateRange = null;
                          _filter = _filter.copyWith(
                            startDate: null,
                            endDate: null,
                          );
                        });
                      },
                    ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _filter = const ActivityLogFilter();
              _dateRange = null;
            });
          },
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApplyFilter(_filter);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (range != null) {
      setState(() {
        _dateRange = range;
        _filter = _filter.copyWith(
          startDate: range.start,
          endDate: range.end,
        );
      });
    }
  }
}

/// Audit log details dialog
class AuditLogDetailsDialog extends StatelessWidget {
  final AdminActivityLog log;

  const AuditLogDetailsDialog({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Audit Log Details'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Basic Info
              _buildInfoSection(
                'Basic Information',
                [
                  _buildInfoRow('Action Type', log.actionType),
                  _buildInfoRow('Target Type', log.targetType),
                  _buildInfoRow('Target ID', log.targetId ?? 'N/A'),
                  _buildInfoRow('Timestamp', DateFormat('MMM dd, yyyy HH:mm:ss').format(log.createdAt)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Admin Info
              _buildInfoSection(
                'Admin Information',
                [
                  _buildInfoRow('Admin ID', log.adminUserId),
                  if (log.adminName != null) _buildInfoRow('Admin Name', log.adminName!),
                  if (log.adminEmail != null) _buildInfoRow('Admin Email', log.adminEmail!),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Technical Info
              _buildInfoSection(
                'Technical Information',
                [
                  _buildInfoRow('IP Address', log.ipAddress ?? 'N/A'),
                  _buildInfoRow('User Agent', log.userAgent ?? 'N/A'),
                ],
              ),
              
              // Details
              if (log.details.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDetailsSection(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _copyLogData(context),
          child: const Text('Copy Data'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: SelectableText(
            _formatDetails(log.details),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _formatDetails(Map<String, dynamic> details) {
    final buffer = StringBuffer();
    details.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  void _copyLogData(BuildContext context) {
    final data = {
      'id': log.id,
      'action_type': log.actionType,
      'target_type': log.targetType,
      'target_id': log.targetId,
      'admin_user_id': log.adminUserId,
      'admin_name': log.adminName,
      'admin_email': log.adminEmail,
      'ip_address': log.ipAddress,
      'user_agent': log.userAgent,
      'created_at': log.createdAt.toIso8601String(),
      'details': log.details,
    };

    Clipboard.setData(ClipboardData(text: data.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log data copied to clipboard')),
    );
  }
}
