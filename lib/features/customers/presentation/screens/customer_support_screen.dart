import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_support_provider.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/faq_item.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

/// Main customer support screen
class CustomerSupportScreen extends ConsumerStatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  ConsumerState<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends ConsumerState<CustomerSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportState = ref.watch(customerSupportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Help Center'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Contact Us'),
          ],
        ),
      ),
      body: supportState.isLoading && supportState.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : supportState.error != null
              ? CustomErrorWidget(
                  message: supportState.error!,
                  onRetry: () {
                    ref.read(customerSupportProvider.notifier).clearError();
                  },
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHelpCenterTab(),
                    _buildMyTicketsTab(),
                    _buildContactUsTab(),
                  ],
                ),
    );
  }

  Widget _buildHelpCenterTab() {
    final faqCategories = ref.watch(faqCategoriesProvider);
    final searchResults = ref.watch(faqSearchResultsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for help...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(customerSupportProvider.notifier).searchFAQ('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (query) {
              ref.read(customerSupportProvider.notifier).searchFAQ(query);
            },
          ),
        ),

        // Content
        Expanded(
          child: _searchController.text.isNotEmpty
              ? _buildSearchResults(searchResults)
              : _buildFAQCategories(faqCategories),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<FAQItem> results) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No results found'),
            SizedBox(height: 8),
            Text(
              'Try different keywords or browse categories below',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final faq = results[index];
        return _buildFAQItem(faq);
      },
    );
  }

  Widget _buildFAQCategories(List<FAQCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildFAQCategoryCard(category);
      },
    );
  }

  Widget _buildFAQCategoryCard(FAQCategory category) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getIconData(category.icon),
          color: theme.colorScheme.primary,
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              )
            : null,
        children: category.faqItems.map((faq) => _buildFAQItem(faq)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        faq.question,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq.answer,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Was this helpful?'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(customerSupportProvider.notifier).markFAQHelpful(faq.id, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your feedback!')),
                      );
                    },
                    icon: const Icon(Icons.thumb_up, size: 16),
                    label: Text('${faq.helpfulCount}'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(customerSupportProvider.notifier).markFAQHelpful(faq.id, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your feedback!')),
                      );
                    },
                    icon: const Icon(Icons.thumb_down, size: 16),
                    label: Text('${faq.notHelpfulCount}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyTicketsTab() {
    final tickets = ref.watch(customerTicketsProvider);

    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No support tickets yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a support ticket if you need help',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Create Ticket',
                onPressed: () => context.push('/customer/support/create-ticket'),
                type: ButtonType.primary,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerSupportProvider.notifier).refreshTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customer/support/ticket/${ticket.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket #${ticket.ticketNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (ticket.category != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getIconData(ticket.category!.icon),
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.category!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(ticket.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    final theme = Theme.of(context);
    final color = Color(int.parse(status.colorCode.substring(1), radix: 16) + 0xFF000000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContactUsTab() {
    final emergencyContacts = ref.watch(emergencyContactsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create ticket section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a support ticket and our team will help you',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Create Support Ticket',
                      onPressed: () => context.push('/customer/support/create-ticket'),
                      type: ButtonType.primary,
                      icon: Icons.support_agent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Emergency contacts
          Text(
            'Emergency Contact',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: emergencyContacts['phone'],
                    onTap: () {
                      // TODO: Implement phone call
                    },
                  ),
                  const Divider(),
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: emergencyContacts['email'],
                    onTap: () {
                      // TODO: Implement email
                    },
                  ),
                  const Divider(),
                  _buildContactItem(
                    icon: Icons.chat,
                    title: 'WhatsApp',
                    subtitle: emergencyContacts['whatsapp'],
                    onTap: () {
                      // TODO: Implement WhatsApp
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support hours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Support Hours',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(emergencyContacts['hours']),
                  const SizedBox(height: 4),
                  Text(
                    emergencyContacts['response_time'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payment':
        return Icons.payment;
      case 'person':
        return Icons.person;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'bug_report':
        return Icons.bug_report;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'restaurant':
        return Icons.restaurant;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'build':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
