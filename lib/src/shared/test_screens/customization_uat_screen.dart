import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class CustomizationUATScreen extends ConsumerStatefulWidget {
  const CustomizationUATScreen({super.key});

  @override
  ConsumerState<CustomizationUATScreen> createState() => _CustomizationUATScreenState();
}

class _CustomizationUATScreenState extends ConsumerState<CustomizationUATScreen> {
  int _currentScenario = 0;
  final List<String> _testResults = [];
  // TODO: Remove unused field when testing functionality is restored
  // ignore: unused_field
  final bool _isTestingInProgress = false;

  final List<TestScenario> _testScenarios = [
    TestScenario(
      title: 'Vendor: Create Basic Customizations',
      description: 'Test vendor ability to create simple customization groups',
      userRole: 'Vendor',
      steps: [
        'Navigate to menu item form',
        'Add "Size" customization group (single choice, required)',
        'Add options: Small (RM 0), Medium (+RM 2), Large (+RM 4)',
        'Save and verify customizations appear',
      ],
    ),
    TestScenario(
      title: 'Vendor: Create Complex Customizations',
      description: 'Test vendor ability to create multiple customization groups',
      userRole: 'Vendor',
      steps: [
        'Create "Spice Level" group (single choice, optional)',
        'Create "Add-ons" group (multiple choice, optional)',
        'Add various options with different prices',
        'Test reordering and editing options',
      ],
    ),
    TestScenario(
      title: 'Customer: Select Required Customizations',
      description: 'Test customer experience with required customizations',
      userRole: 'Customer',
      steps: [
        'Browse menu and select customizable item',
        'Attempt to add to cart without selecting required options',
        'Verify error message appears',
        'Select required options and successfully add to cart',
      ],
    ),
    TestScenario(
      title: 'Customer: Multiple Choice Customizations',
      description: 'Test customer experience with multiple choice options',
      userRole: 'Customer',
      steps: [
        'Select item with multiple choice customizations',
        'Select multiple add-ons',
        'Verify price updates correctly',
        'Add to cart and verify customizations are saved',
      ],
    ),
    TestScenario(
      title: 'Sales Agent: Order with Customizations',
      description: 'Test sales agent order creation with customizations',
      userRole: 'Sales Agent',
      steps: [
        'Create order for customer',
        'Add customized items to cart',
        'Verify pricing calculations include customizations',
        'Complete order and verify customizations in order details',
      ],
    ),
    TestScenario(
      title: 'Order Fulfillment: Vendor View',
      description: 'Test vendor order management with customizations',
      userRole: 'Vendor',
      steps: [
        'View incoming order with customizations',
        'Verify all customization details are visible',
        'Update order status through preparation stages',
        'Confirm customizations remain visible throughout',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Acceptance Testing'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customization UAT Suite',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comprehensive user acceptance testing for menu customizations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Test Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentScenario / _testScenarios.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text('Scenario ${_currentScenario + 1} of ${_testScenarios.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Test Scenario
            if (_currentScenario < _testScenarios.length)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(_testScenarios[_currentScenario].userRole),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _testScenarios[_currentScenario].userRole,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testScenarios[_currentScenario].title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _testScenarios[_currentScenario].description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Test Steps:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _testScenarios[_currentScenario].steps.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _testScenarios[_currentScenario].steps[index],
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _markTestPassed,
                              icon: const Icon(Icons.check),
                              label: const Text('Pass'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _markTestFailed,
                              icon: const Icon(Icons.close),
                              label: const Text('Fail'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _skipTest,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Skip'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Test Complete
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All Tests Completed!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Test Summary:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _testResults.length,
                            itemBuilder: (context, index) {
                              final result = _testResults[index];
                              final parts = result.split(': ');
                              final status = parts.last;
                              final title = parts.first;
                              
                              return ListTile(
                                leading: Icon(
                                  status == 'PASSED' ? Icons.check_circle : 
                                  status == 'FAILED' ? Icons.error : Icons.help,
                                  color: status == 'PASSED' ? Colors.green : 
                                         status == 'FAILED' ? Colors.red : Colors.orange,
                                ),
                                title: Text(title),
                                subtitle: Text(status),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _resetTests,
                          child: const Text('Reset Tests'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Vendor':
        return Colors.purple;
      case 'Customer':
        return Colors.blue;
      case 'Sales Agent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _markTestPassed() {
    _recordTestResult('PASSED');
    _nextTest();
  }

  void _markTestFailed() {
    _recordTestResult('FAILED');
    _nextTest();
  }

  void _skipTest() {
    _recordTestResult('SKIPPED');
    _nextTest();
  }

  void _recordTestResult(String result) {
    setState(() {
      _testResults.add('${_testScenarios[_currentScenario].title}: $result');
    });
  }

  void _nextTest() {
    setState(() {
      _currentScenario++;
    });
  }

  void _resetTests() {
    setState(() {
      _currentScenario = 0;
      _testResults.clear();
    });
  }
}

class TestScenario {
  final String title;
  final String description;
  final String userRole;
  final List<String> steps;

  TestScenario({
    required this.title,
    required this.description,
    required this.userRole,
    required this.steps,
  });
}
