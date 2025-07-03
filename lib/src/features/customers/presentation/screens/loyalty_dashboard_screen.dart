import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loyalty dashboard screen for customers
class LoyaltyDashboardScreen extends ConsumerWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Dashboard'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Summary Card
            _PointsSummaryCard(),
            const SizedBox(height: 20),
            
            // Rewards Section
            Text(
              'Available Rewards',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _RewardsGrid(),
            const SizedBox(height: 20),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _RecentActivityList(),
          ],
        ),
      ),
    );
  }
}

class _PointsSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Points',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1,250',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Expires in 90 days',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rewards = [
      {'title': 'RM 5 Off', 'points': 500, 'icon': Icons.discount},
      {'title': 'Free Delivery', 'points': 300, 'icon': Icons.local_shipping},
      {'title': 'RM 10 Off', 'points': 1000, 'icon': Icons.card_giftcard},
      {'title': 'Double Points', 'points': 750, 'icon': Icons.star},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return _RewardCard(
          title: reward['title'] as String,
          points: reward['points'] as int,
          icon: reward['icon'] as IconData,
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String title;
  final int points;
  final IconData icon;

  const _RewardCard({
    required this.title,
    required this.points,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$points pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activities = [
      {'title': 'Order #1234', 'points': '+25', 'date': '2 days ago'},
      {'title': 'Redeemed RM 5 Off', 'points': '-500', 'date': '1 week ago'},
      {'title': 'Order #1233', 'points': '+15', 'date': '1 week ago'},
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityTile(
          title: activity['title'] as String,
          points: activity['points'] as String,
          date: activity['date'] as String,
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String points;
  final String date;

  const _ActivityTile({
    required this.title,
    required this.points,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = points.startsWith('+');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive 
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isPositive ? Icons.add : Icons.remove,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        points,
        style: theme.textTheme.titleSmall?.copyWith(
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
