import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/feedback/feedback_collector.dart';

class FeedbackAnalyticsDashboard extends ConsumerStatefulWidget {
  const FeedbackAnalyticsDashboard({super.key});

  @override
  ConsumerState<FeedbackAnalyticsDashboard> createState() => _FeedbackAnalyticsDashboardState();
}

class _FeedbackAnalyticsDashboardState extends ConsumerState<FeedbackAnalyticsDashboard> {
  final FeedbackCollector _collector = FeedbackCollector();
  FeedbackAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      final analytics = await _collector.getFeedbackAnalytics(
        startDate: lastWeek,
        endDate: now,
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSampleFeedback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate sample feedback data for demonstration
      await _generateCustomizationFeedback();
      await _generateUsabilityFeedback();
      await _generateFeatureRequests();
      await _generateBugReports();

      // Reload analytics
      await _loadAnalytics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample feedback generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateCustomizationFeedback() async {
    final feedbackItems = [
      {
        'rating': 5,
        'comments': 'Love the new customization options! Very easy to use.',
        'type': 'ease_of_use',
      },
      {
        'rating': 4,
        'comments': 'Great feature, but could use more visual feedback when selecting options.',
        'type': 'visual_feedback',
      },
      {
        'rating': 3,
        'comments': 'Sometimes the pricing updates are slow when selecting multiple options.',
        'type': 'performance',
      },
      {
        'rating': 5,
        'comments': 'Perfect for our restaurant! Customers love the flexibility.',
        'type': 'business_value',
      },
      {
        'rating': 4,
        'comments': 'Would be nice to have preset combinations for popular choices.',
        'type': 'enhancement',
      },
    ];

    for (int i = 0; i < feedbackItems.length; i++) {
      final item = feedbackItems[i];
      await _collector.collectCustomizationFeedback(
        userId: 'test-user-$i',
        userRole: i % 2 == 0 ? 'customer' : 'vendor',
        menuItemId: 'test-menu-item-$i',
        feedbackType: item['type'] as String,
        rating: item['rating'] as int,
        comments: item['comments'] as String,
        customizationData: {
          'customization_count': 3 + i,
          'option_count': 8 + (i * 2),
        },
      );
    }
  }

  Future<void> _generateUsabilityFeedback() async {
    final usabilityItems = [
      {
        'screen': 'product_details',
        'action': 'select_customizations',
        'difficulty': 2,
        'satisfaction': 4,
        'suggestions': 'Could use better visual hierarchy for required vs optional items.',
      },
      {
        'screen': 'cart',
        'action': 'review_customizations',
        'difficulty': 1,
        'satisfaction': 5,
        'suggestions': 'Perfect! Very clear display of all selected options.',
      },
      {
        'screen': 'vendor_dashboard',
        'action': 'manage_customizations',
        'difficulty': 3,
        'satisfaction': 3,
        'suggestions': 'Bulk editing would save a lot of time.',
      },
    ];

    for (int i = 0; i < usabilityItems.length; i++) {
      final item = usabilityItems[i];
      await _collector.collectUsabilityFeedback(
        userId: 'test-user-usability-$i',
        userRole: i == 2 ? 'vendor' : 'customer',
        screen: item['screen'] as String,
        action: item['action'] as String,
        difficultyRating: item['difficulty'] as int,
        satisfactionRating: item['satisfaction'] as int,
        suggestions: item['suggestions'] as String,
      );
    }
  }

  Future<void> _generateFeatureRequests() async {
    final requests = [
      {
        'title': 'Customization Templates',
        'description': 'Allow vendors to create preset customization templates for popular combinations',
        'priority': 4,
        'justification': 'Would speed up ordering process and reduce customer decision fatigue',
      },
      {
        'title': 'Customer Favorites',
        'description': 'Let customers save their favorite customization combinations for quick reordering',
        'priority': 5,
        'justification': 'Improve customer experience and increase repeat orders',
      },
      {
        'title': 'Bulk Customization Management',
        'description': 'Allow vendors to apply customizations to multiple menu items at once',
        'priority': 3,
        'justification': 'Reduce vendor setup time for similar items',
      },
    ];

    for (int i = 0; i < requests.length; i++) {
      final request = requests[i];
      await _collector.collectFeatureRequest(
        userId: 'test-user-request-$i',
        userRole: i == 2 ? 'vendor' : 'customer',
        featureTitle: request['title'] as String,
        featureDescription: request['description'] as String,
        priority: request['priority'] as int,
        businessJustification: request['justification'] as String,
      );
    }
  }

  Future<void> _generateBugReports() async {
    final bugs = [
      {
        'description': 'Price calculation sometimes shows incorrect total when deselecting options',
        'severity': 'medium',
        'steps': '1. Select multiple paid options 2. Deselect one option 3. Price doesn\'t update correctly',
        'expected': 'Price should decrease when deselecting paid options',
        'actual': 'Price remains the same or shows incorrect amount',
      },
      {
        'description': 'Customization form doesn\'t scroll properly on small screens',
        'severity': 'low',
        'steps': '1. Open product with many customizations on mobile 2. Try to scroll to bottom options',
        'expected': 'Should be able to scroll to all options',
        'actual': 'Bottom options are cut off and not accessible',
      },
    ];

    for (int i = 0; i < bugs.length; i++) {
      final bug = bugs[i];
      await _collector.collectBugReport(
        userId: 'test-user-bug-$i',
        userRole: 'customer',
        bugDescription: bug['description'] as String,
        severity: bug['severity'] as String,
        stepsToReproduce: bug['steps'] as String,
        expectedBehavior: bug['expected'] as String,
        actualBehavior: bug['actual'] as String,
        deviceInfo: {
          'platform': 'android',
          'version': '14',
          'device': 'emulator',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Analytics'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'User Feedback Analytics',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _generateSampleFeedback,
                            icon: const Icon(Icons.add_comment),
                            label: const Text('Generate Sample'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last 7 days feedback analysis',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Overview Stats
                      _buildOverviewCard(),
                      const SizedBox(height: 16),

                      // Category Breakdown
                      Row(
                        children: [
                          Expanded(child: _buildCategoryCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildUserRoleCard()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ratings by Category
                      _buildRatingsCard(),
                      const SizedBox(height: 16),

                      // Top Issues and Requests
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTopIssuesCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTopRequestsCard()),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Text(
                  'Feedback Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_analytics == null || _analytics!.totalFeedback == 0)
              const Text('No feedback data available')
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Total Feedback',
                      '${_analytics!.totalFeedback}',
                      Icons.comment,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Average Rating',
                      '${_analytics!.averageRating.toStringAsFixed(1)}/5',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics?.categoryBreakdown.isEmpty ?? true)
              const Text('No category data')
            else
              ..._analytics!.categoryBreakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatCategoryName(entry.key)),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRoleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback by User Role',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics?.userRoleBreakdown.isEmpty ?? true)
              const Text('No user role data')
            else
              ..._analytics!.userRoleBreakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatRoleName(entry.key)),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Ratings by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics?.categoryRatings.isEmpty ?? true)
              const Text('No rating data')
            else
              ..._analytics!.categoryRatings.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(_formatCategoryName(entry.key))),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < entry.value.round() ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIssuesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Issues',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics?.topIssues.isEmpty ?? true)
              const Text('No issues reported')
            else
              ..._analytics!.topIssues.take(5).map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bug_report, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRequestsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Feature Requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics?.topRequests.isEmpty ?? true)
              const Text('No feature requests')
            else
              ..._analytics!.topRequests.take(5).map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    return category.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatRoleName(String role) {
    return role[0].toUpperCase() + role.substring(1);
  }
}
