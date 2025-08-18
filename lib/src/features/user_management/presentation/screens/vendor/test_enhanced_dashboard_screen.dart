import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/design_system.dart';

/// Test Screen for Enhanced Vendor Dashboard
/// 
/// A simple test screen that provides navigation to the enhanced vendor dashboard
/// and displays any errors or issues that occur during navigation.
class TestEnhancedDashboardScreen extends StatelessWidget {
  const TestEnhancedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🧪 [TEST-ENHANCED-DASHBOARD] Building test screen');
    
    return GEScreen(
      appBar: GEAppBar(
        title: 'Enhanced Dashboard Test',
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(GESpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(GESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Vendor Dashboard Test',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GESpacing.sm),
                    const Text(
                      'This screen allows you to test the enhanced vendor dashboard implementation. '
                      'Click the button below to navigate to the enhanced dashboard and check for any UI rendering issues.',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: GESpacing.lg),
            
            // Navigation Button
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🧪 [TEST-ENHANCED-DASHBOARD] Navigating to enhanced dashboard');
                try {
                  context.push('/test-enhanced-vendor-dashboard');
                } catch (e, stackTrace) {
                  debugPrint('❌ [TEST-ENHANCED-DASHBOARD] Navigation error: $e');
                  debugPrint('❌ [TEST-ENHANCED-DASHBOARD] Stack trace: $stackTrace');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigation error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Test Enhanced Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: GESpacing.md,
                  horizontal: GESpacing.lg,
                ),
              ),
            ),
            
            const SizedBox(height: GESpacing.md),
            
            // Direct Route Button
            OutlinedButton.icon(
              onPressed: () {
                debugPrint('🧪 [TEST-ENHANCED-DASHBOARD] Direct navigation to enhanced dashboard');
                try {
                  context.go('/test-enhanced-vendor-dashboard');
                } catch (e, stackTrace) {
                  debugPrint('❌ [TEST-ENHANCED-DASHBOARD] Direct navigation error: $e');
                  debugPrint('❌ [TEST-ENHANCED-DASHBOARD] Stack trace: $stackTrace');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Direct navigation error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.launch),
              label: const Text('Direct Navigation (Go)'),
            ),
            
            const SizedBox(height: GESpacing.lg),
            
            // Debug Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(GESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GESpacing.sm),
                    Text('Screen Size: ${MediaQuery.of(context).size}'),
                    Text('Device Pixel Ratio: ${MediaQuery.of(context).devicePixelRatio}'),
                    Text('Platform: ${Theme.of(context).platform}'),
                    const SizedBox(height: GESpacing.sm),
                    const Text(
                      'Check the console logs for detailed debug information when navigating to the enhanced dashboard.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Back Button
            TextButton.icon(
              onPressed: () {
                debugPrint('🧪 [TEST-ENHANCED-DASHBOARD] Navigating back to vendor dashboard');
                context.go('/vendor/dashboard');
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Vendor Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
