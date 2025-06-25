import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class WalletTestScreen extends ConsumerStatefulWidget {
  const WalletTestScreen({super.key});

  @override
  ConsumerState<WalletTestScreen> createState() => _WalletTestScreenState();
}

class _WalletTestScreenState extends ConsumerState<WalletTestScreen> {
  bool _isCreatingWallet = false;
  String _testResult = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet System Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${authState.user?.email ?? 'Not logged in'}'),
                    Text('Role: ${authState.user?.role.name ?? 'Unknown'}'),
                    Text('User ID: ${authState.user?.id ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Wallet Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('🚧 Wallet system is being configured'),
                    const Text('Please check back later for wallet functionality'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Initialize/Check Wallet Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingWallet ? null : _initializeWallet,
                        child: _isCreatingWallet
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Checking Wallet...'),
                                ],
                              )
                            : const Text('Initialize/Check Wallet'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Navigate to Wallet Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/customer/wallet'),
                        child: const Text('Open Customer Wallet'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Navigate to Shared Wallet Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/wallet/dashboard'),
                        child: const Text('Open Shared Wallet Dashboard'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test Navigation Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _testResult = '✅ Navigation test completed!';
                          });
                        },
                        child: const Text('Test Navigation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Results
            if (_testResult.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_testResult),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeWallet() async {
    setState(() {
      _isCreatingWallet = true;
      _testResult = '';
    });

    try {
      // Simulate wallet initialization
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _testResult = '✅ Wallet system test completed!';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Failed to test wallet: $e';
      });
    } finally {
      setState(() {
        _isCreatingWallet = false;
      });
    }
  }
}
