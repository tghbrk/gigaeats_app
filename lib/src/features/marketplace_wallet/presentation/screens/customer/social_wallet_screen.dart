
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../providers/social_wallet_provider.dart';
import '../../widgets/social_wallet_widgets.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../../data/models/customer_wallet_error.dart';
import '../../../data/models/social_wallet.dart';

class SocialWalletScreen extends ConsumerStatefulWidget {
  const SocialWalletScreen({super.key});

  @override
  ConsumerState<SocialWalletScreen> createState() => _SocialWalletScreenState();
}

class _SocialWalletScreenState extends ConsumerState<SocialWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [SOCIAL-WALLET-SCREEN] initState() called');
    _tabController = TabController(length: 3, vsync: this);

    // Load initial social wallet data only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        debugPrint('🔍 [SOCIAL-WALLET-SCREEN] PostFrameCallback: calling refreshAll()');
        _hasInitialized = true;
        ref.read(socialWalletProvider.notifier).refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socialWalletState = ref.watch(socialWalletProvider);

    // Listen for errors and show snackbar
    ref.listen<SocialWalletState>(socialWalletProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ref.read(socialWalletProvider.notifier).clearError();
                ref.read(socialWalletProvider.notifier).refreshAll();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Wallet'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: socialWalletState.isLoading
                ? null
                : () {
                    debugPrint('🔍 [SOCIAL-WALLET-SCREEN] Manual refresh triggered');
                    ref.read(socialWalletProvider.notifier).refreshAll();
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('Create Group'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'send_request',
                child: Row(
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 8),
                    Text('Send Request'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Social Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Groups', icon: Icon(Icons.groups, size: 20)),
            Tab(text: 'Bills', icon: Icon(Icons.receipt, size: 20)),
            Tab(text: 'Requests', icon: Icon(Icons.request_page, size: 20)),
          ],
        ),
      ),
      body: socialWalletState.isLoading
          ? const LoadingWidget()
          : socialWalletState.errorMessage != null
              ? CustomerWalletErrorWidget(
                  error: CustomerWalletError.fromMessage(socialWalletState.errorMessage!),
                  onRetry: () => ref.read(socialWalletProvider.notifier).refreshAll(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupsTab(),
                    _buildBillsTab(),
                    _buildRequestsTab(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Groups overview
          const GroupsOverviewCard(),
          const SizedBox(height: 24),

          // Active groups list
          const ActiveGroupsList(),
          const SizedBox(height: 24),

          // Recent group activity
          const RecentGroupActivity(),
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bills overview
          const BillsOverviewCard(),
          const SizedBox(height: 24),

          // Recent bill splits
          const RecentBillSplits(),
          const SizedBox(height: 24),

          // Pending settlements
          const PendingSettlements(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Requests overview
          const RequestsOverviewCard(),
          const SizedBox(height: 24),

          // Incoming requests
          const IncomingPaymentRequests(),
          const SizedBox(height: 24),

          // Outgoing requests
          const OutgoingPaymentRequests(),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionDialog(),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Quick Action'),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'create_group':
        _navigateToCreateGroup();
        break;
      case 'send_request':
        _navigateToSendRequest();
        break;
      case 'settings':
        _navigateToSocialSettings();
        break;
    }
  }

  void _showQuickActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Group'),
              subtitle: const Text('Start a new payment group'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToCreateGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Split Bill'),
              subtitle: const Text('Split a bill with friends'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToSplitBill();
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Send Request'),
              subtitle: const Text('Request payment from someone'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToSendRequest();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
  }

  void _navigateToSplitBill() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SplitBillScreen(),
      ),
    );
  }

  void _navigateToSendRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SendPaymentRequestScreen(),
      ),
    );
  }

  void _navigateToSocialSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SocialWalletSettingsScreen(),
      ),
    );
  }
}

/// Create group screen
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberEmailsController = TextEditingController();
  
  GroupType _selectedType = GroupType.friends;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memberEmailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                  helperText: 'Choose a memorable name for your group',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Group description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  helperText: 'Describe the purpose of this group',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Group type
              DropdownButtonFormField<GroupType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Group Type',
                  border: OutlineInputBorder(),
                ),
                items: GroupType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.displayName),
                        Text(
                          type.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Member emails
              TextFormField(
                controller: _memberEmailsController,
                decoration: const InputDecoration(
                  labelText: 'Member Emails',
                  border: OutlineInputBorder(),
                  helperText: 'Enter email addresses separated by commas',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final memberEmails = _memberEmailsController.text
          .split(',')
          .map((email) => email.trim())
          .where((email) => email.isNotEmpty)
          .toList();

      await ref.read(socialWalletProvider.notifier).createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        memberEmails: memberEmails,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
