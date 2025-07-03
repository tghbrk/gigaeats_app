import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/services/realtime_notification_service.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/presentation/widgets/notification_widgets.dart';

class RealtimeNotificationsTestScreen extends ConsumerStatefulWidget {
  const RealtimeNotificationsTestScreen({super.key});

  @override
  ConsumerState<RealtimeNotificationsTestScreen> createState() =>
      _RealtimeNotificationsTestScreenState();
}

class _RealtimeNotificationsTestScreenState
    extends ConsumerState<RealtimeNotificationsTestScreen> {
  final RealtimeNotificationService _notificationService = RealtimeNotificationService();
  final NotificationRepository _repository = NotificationRepository();
  final List<String> _logs = [];
  bool _isLoading = false;
  bool _isServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    debugPrint('RealtimeNotificationsTest: $message');
  }

  Future<void> _initializeService() async {
    try {
      _log('🔄 Initializing notification service...');
      
      // Initialize with test user
      await _notificationService.initialize(
        userId: 'test-user-id',
        userRole: 'customer',
      );
      
      setState(() {
        _isServiceInitialized = true;
      });
      
      _log('✅ Notification service initialized');
      
      // Listen to notification stream
      _notificationService.notificationStream.listen((notification) {
        _log('📱 Received notification: ${notification.title}');
      });
      
      // Listen to counts stream
      _notificationService.countsStream.listen((counts) {
        _log('📊 Counts updated: ${counts.unreadCount} unread');
      });
      
    } catch (e) {
      _log('❌ Failed to initialize service: $e');
    }
  }

  Future<void> _testCreateNotification() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 Testing notification creation...');

    try {
      // Test creating notification from template
      _log('📝 Step 1: Creating notification from template...');
      final success = await _notificationService.createNotificationFromTemplate(
        templateKey: 'order_created',
        userId: 'test-user-id',
        variables: {
          'order_number': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          'customer_name': 'Test Customer',
          'total_amount': 'RM 25.50',
        },
        relatedEntityType: 'order',
        relatedEntityId: 'test-order-id',
      );

      if (success) {
        _log('✅ Notification created successfully');
      } else {
        _log('❌ Failed to create notification');
      }

      // Test creating custom notification
      _log('📝 Step 2: Creating custom notification...');
      final customNotificationId = await _repository.createNotification(
        userId: 'test-user-id',
        type: 'system_announcement',
        title: 'Test Notification',
        message: 'This is a test notification created at ${DateTime.now()}',
        priority: 'high',
        category: 'system',
        richContent: {
          'icon': '🧪',
          'color': '#FF5722',
        },
      );

      if (customNotificationId.isNotEmpty) {
        _log('✅ Custom notification created: $customNotificationId');
      } else {
        _log('❌ Failed to create custom notification');
      }

      // Test broadcast notification
      _log('📝 Step 3: Creating broadcast notification...');
      final broadcastId = await _repository.createNotification(
        isBroadcast: true,
        type: 'system_announcement',
        title: 'System Maintenance',
        message: 'The system will undergo maintenance tonight from 2 AM to 4 AM.',
        priority: 'normal',
        category: 'system',
      );

      if (broadcastId.isNotEmpty) {
        _log('✅ Broadcast notification created: $broadcastId');
      } else {
        _log('❌ Failed to create broadcast notification');
      }

    } catch (e) {
      _log('❌ Error during notification creation test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotificationOperations() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 Testing notification operations...');

    try {
      // Get user notifications
      _log('📋 Step 1: Getting user notifications...');
      final notifications = await _repository.getUserNotifications(
        userId: 'test-user-id',
        limit: 10,
      );
      _log('✅ Found ${notifications.length} notifications');

      if (notifications.isNotEmpty) {
        final firstNotification = notifications.first;
        
        // Test marking as read
        _log('📖 Step 2: Marking notification as read...');
        final readSuccess = await _repository.markAsRead(
          firstNotification.id,
          userId: 'test-user-id',
        );
        
        if (readSuccess) {
          _log('✅ Notification marked as read');
        } else {
          _log('❌ Failed to mark notification as read');
        }
      }

      // Get notification counts
      _log('📊 Step 3: Getting notification counts...');
      final counts = await _repository.getNotificationCounts(userId: 'test-user-id');
      _log('✅ Counts - Total: ${counts.totalCount}, Unread: ${counts.unreadCount}');

      // Test mark all as read
      _log('📖 Step 4: Marking all notifications as read...');
      final markedCount = await _repository.markAllAsRead(userId: 'test-user-id');
      _log('✅ Marked $markedCount notifications as read');

    } catch (e) {
      _log('❌ Error during notification operations test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRealtimeFeatures() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 Testing real-time features...');

    try {
      _log('🔄 Step 1: Checking service connection...');
      _log('📡 Service connected: ${_notificationService.isConnected}');
      _log('🔧 Service initialized: ${_notificationService.isInitialized}');

      // Test creating a notification that should trigger real-time update
      _log('📝 Step 2: Creating notification for real-time test...');
      final notificationId = await _repository.createNotification(
        userId: 'test-user-id',
        type: 'order_ready',
        title: 'Real-time Test',
        message: 'This notification should appear in real-time!',
        priority: 'high',
        category: 'order',
      );

      if (notificationId.isNotEmpty) {
        _log('✅ Real-time notification created: $notificationId');
        _log('⏳ Watch for real-time update...');
      }

      // Test role-based notification
      _log('📝 Step 3: Creating role-based notification...');
      final roleNotificationId = await _repository.createNotification(
        roleFilter: ['customer'],
        type: 'promotion_available',
        title: 'Special Offer for Customers',
        message: 'Get 20% off your next order!',
        priority: 'normal',
        category: 'promotion',
      );

      if (roleNotificationId.isNotEmpty) {
        _log('✅ Role-based notification created: $roleNotificationId');
      }

    } catch (e) {
      _log('❌ Error during real-time features test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotificationTemplates() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 Testing notification templates...');

    try {
      // Get available templates
      _log('📋 Step 1: Getting notification templates...');
      final templates = await _repository.getNotificationTemplates();
      _log('✅ Found ${templates.length} templates');

      for (final template in templates.take(5)) {
        _log('  • ${template.name} (${template.templateKey})');
      }

      // Test each template type
      final testTemplates = [
        {
          'key': 'order_confirmed',
          'variables': {'order_number': 'ORD-TEST-001'},
        },
        {
          'key': 'payment_received',
          'variables': {'amount': 'RM 35.00', 'order_number': 'ORD-TEST-002'},
        },
        {
          'key': 'driver_assigned',
          'variables': {'order_number': 'ORD-TEST-003', 'driver_name': 'Ahmad Rahman'},
        },
      ];

      for (final testTemplate in testTemplates) {
        _log('📝 Testing template: ${testTemplate['key']}');
        final success = await _notificationService.createNotificationFromTemplate(
          templateKey: testTemplate['key'] as String,
          userId: 'test-user-id',
          variables: testTemplate['variables'] as Map<String, dynamic>,
        );

        if (success) {
          _log('✅ Template ${testTemplate['key']} created successfully');
        } else {
          _log('❌ Failed to create from template ${testTemplate['key']}');
        }
      }

    } catch (e) {
      _log('❌ Error during template test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Notifications Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          NotificationBadge(
            onTap: () {
              // Show notifications
            },
            child: const Icon(Icons.notifications),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Service status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isServiceInitialized ? Colors.green[100] : Colors.red[100],
            child: Row(
              children: [
                Icon(
                  _isServiceInitialized ? Icons.check_circle : Icons.error,
                  color: _isServiceInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isServiceInitialized 
                      ? 'Notification Service: Connected'
                      : 'Notification Service: Disconnected',
                  style: TextStyle(
                    color: _isServiceInitialized ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Notification summary
          const Padding(
            padding: EdgeInsets.all(16),
            child: NotificationSummary(),
          ),

          // Test controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCreateNotification,
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Test Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNotificationOperations,
                  icon: const Icon(Icons.settings),
                  label: const Text('Test Operations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testRealtimeFeatures,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Test Real-time'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNotificationTemplates,
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Test Templates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Test logs
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal),
                        const SizedBox(width: 8),
                        const Text(
                          'Test Logs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
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

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
