import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_customization_test_screen.dart';
import 'customization_performance_test_screen.dart';
import 'customization_uat_screen.dart';
import 'performance_monitoring_dashboard.dart';
import 'feedback_analytics_dashboard.dart';
import 'payment_test_screen.dart';

class EnhancedFeaturesTestScreen extends ConsumerStatefulWidget {
  const EnhancedFeaturesTestScreen({super.key});

  @override
  ConsumerState<EnhancedFeaturesTestScreen> createState() => _EnhancedFeaturesTestScreenState();
}

class _EnhancedFeaturesTestScreenState extends ConsumerState<EnhancedFeaturesTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Features Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Features Test',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test advanced features and new implementations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Customization Test
            _buildTestCard(
              title: '🍔 Menu Customization',
              description: 'Test menu item customizations with size, spice level, and add-ons',
              buttonText: 'Test Customizations',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuCustomizationTestScreen(),
                  ),
                );
              },
              icon: Icons.tune,
              color: Colors.orange,
            ),

            const SizedBox(height: 16),

            // Performance Testing
            _buildTestCard(
              title: '⚡ Performance Testing',
              description: 'Test customization performance with large datasets and complex scenarios',
              buttonText: 'Run Performance Tests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomizationPerformanceTestScreen(),
                  ),
                );
              },
              icon: Icons.speed,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            // User Acceptance Testing
            _buildTestCard(
              title: '👥 User Acceptance Testing',
              description: 'Comprehensive UAT scenarios for vendors, customers, and sales agents',
              buttonText: 'Start UAT Suite',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomizationUATScreen(),
                  ),
                );
              },
              icon: Icons.people,
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            // Performance Monitoring
            _buildTestCard(
              title: '📊 Performance Monitoring',
              description: 'Real-time performance metrics and monitoring dashboard for production',
              buttonText: 'Open Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceMonitoringDashboard(),
                  ),
                );
              },
              icon: Icons.analytics,
              color: Colors.indigo,
            ),

            const SizedBox(height: 16),

            // Feedback Analytics
            _buildTestCard(
              title: '📝 Feedback Analytics',
              description: 'User feedback collection and analysis dashboard for continuous improvement',
              buttonText: 'View Analytics',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackAnalyticsDashboard(),
                  ),
                );
              },
              icon: Icons.feedback,
              color: Colors.purple,
            ),

            const SizedBox(height: 16),

            // Payment Integration Testing
            _buildTestCard(
              title: '💳 Payment Integration',
              description: 'Test Stripe payment integration with various card scenarios and error handling',
              buttonText: 'Test Payments',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentTestScreen(),
                  ),
                );
              },
              icon: Icons.payment,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Menu Customization System Deployed!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✅ Database Schema Ready\n✅ API Integration Complete\n✅ UI Components Functional\n✅ Performance Tested\n✅ UAT Framework Ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'PRODUCTION READY',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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

  Widget _buildTestCard({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
