import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/driver_orders_provider.dart';
import '../../../../presentation/widgets/loading_widget.dart';
import '../../../../presentation/widgets/custom_error_widget.dart';

/// Driver performance dashboard widget
/// Shows comprehensive performance metrics, earnings, and goals
class DriverPerformanceDashboard extends ConsumerWidget {
  const DriverPerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('💰 DriverPerformanceDashboard: build() called at ${DateTime.now()}');

    final theme = Theme.of(context);
    final performanceSummary = ref.watch(driverPerformanceSummaryProvider);
    final goalsAndAchievements = ref.watch(driverGoalsAndAchievementsProvider);

    debugPrint('💰 DriverPerformanceDashboard: performanceSummary state = ${performanceSummary.runtimeType}');
    debugPrint('💰 DriverPerformanceDashboard: goalsAndAchievements state = ${goalsAndAchievements.runtimeType}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Performance Summary Cards
          performanceSummary.when(
            data: (summary) => _buildPerformanceSummary(summary, theme),
            loading: () => const LoadingWidget(),
            error: (error, stack) => CustomErrorWidget(
              message: 'Failed to load performance summary: $error',
              onRetry: () => ref.invalidate(driverPerformanceSummaryProvider),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Goals and Achievements
          goalsAndAchievements.when(
            data: (data) => _buildGoalsAndAchievements(data, theme),
            loading: () => const LoadingWidget(),
            error: (error, stack) => CustomErrorWidget(
              message: 'Failed to load goals: $error',
              onRetry: () => ref.invalidate(driverGoalsAndAchievementsProvider),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary(Map<String, dynamic>? summary, ThemeData theme) {
    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No performance data available',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Today's Performance
        _buildPerformanceCard(
          'Today\'s Performance',
          [
            _buildMetricItem('Deliveries', '${summary['today_successful_deliveries'] ?? 0}', Icons.local_shipping),
            _buildMetricItem('Earnings', 'RM ${(summary['today_earnings'] ?? 0).toStringAsFixed(2)}', Icons.attach_money),
            _buildMetricItem('Success Rate', '${(summary['today_success_rate'] ?? 0).toStringAsFixed(1)}%', Icons.check_circle),
            _buildMetricItem('Rating', '${(summary['today_rating'] ?? 0).toStringAsFixed(1)} ⭐', Icons.star),
          ],
          theme,
        ),
        
        const SizedBox(height: 16),
        
        // Weekly Performance
        _buildPerformanceCard(
          'This Week',
          [
            _buildMetricItem('Deliveries', '${summary['week_successful_deliveries'] ?? 0}', Icons.local_shipping),
            _buildMetricItem('Earnings', 'RM ${(summary['week_earnings'] ?? 0).toStringAsFixed(2)}', Icons.attach_money),
            _buildMetricItem('Success Rate', '${(summary['week_success_rate'] ?? 0).toStringAsFixed(1)}%', Icons.check_circle),
            _buildMetricItem('Avg Time', '${(summary['week_avg_delivery_time'] ?? 0).toStringAsFixed(0)} min', Icons.timer),
          ],
          theme,
        ),
        
        const SizedBox(height: 16),
        
        // Monthly Performance
        _buildPerformanceCard(
          'This Month',
          [
            _buildMetricItem('Deliveries', '${summary['month_successful_deliveries'] ?? 0}', Icons.local_shipping),
            _buildMetricItem('Earnings', 'RM ${(summary['month_earnings'] ?? 0).toStringAsFixed(2)}', Icons.attach_money),
            _buildMetricItem('Success Rate', '${(summary['month_success_rate'] ?? 0).toStringAsFixed(1)}%', Icons.check_circle),
            _buildMetricItem('Rating', '${(summary['month_rating'] ?? 0).toStringAsFixed(1)} ⭐', Icons.star),
          ],
          theme,
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String title, List<Widget> metrics, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: metrics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsAndAchievements(Map<String, dynamic> data, ThemeData theme) {
    final goals = data['goals'] as List<dynamic>? ?? [];
    final achievements = data['achievements'] as List<dynamic>? ?? [];
    final completionRate = data['completion_rate'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Goals & Achievements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: completionRate >= 75 ? Colors.green : completionRate >= 50 ? Colors.orange : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completionRate% Complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Goals Progress
        ...goals.map((goal) => _buildGoalCard(goal, theme)).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Container(
            key: ValueKey('goal_$index'),
            child: widget,
          );
        }),
        
        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Recent Achievements 🏆',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...achievements.take(3).map((achievement) => _buildAchievementCard(achievement, theme)).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final widget = entry.value;
            return Container(
              key: ValueKey('achievement_$index'),
              child: widget,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, ThemeData theme) {
    final progress = (goal['progress'] as num?)?.toDouble() ?? 0;
    final achieved = goal['achieved'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal['title'] ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (achieved)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              goal['description'] ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achieved ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal['current']}/${goal['target']}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.green.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.amber),
        title: Text(
          achievement['title'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(achievement['description'] ?? ''),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View Earnings',
                    Icons.attach_money,
                    () => _navigateToEarnings(context),
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Performance Trends',
                    Icons.trending_up,
                    () => _navigateToTrends(context),
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Leaderboard',
                    Icons.leaderboard,
                    () => _navigateToLeaderboard(context),
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Location History',
                    Icons.location_history,
                    () => _navigateToLocationHistory(context),
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }

  void _navigateToEarnings(BuildContext context) {
    // TODO: Navigate to earnings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Earnings screen coming soon!')),
    );
  }

  void _navigateToTrends(BuildContext context) {
    // TODO: Navigate to trends screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trends screen coming soon!')),
    );
  }

  void _navigateToLeaderboard(BuildContext context) {
    // TODO: Navigate to leaderboard screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leaderboard screen coming soon!')),
    );
  }

  void _navigateToLocationHistory(BuildContext context) {
    // TODO: Navigate to location history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location history screen coming soon!')),
    );
  }
}
