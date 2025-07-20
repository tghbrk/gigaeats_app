# Driver Workflow UI Enhancements

## 🎯 Overview

The Driver Workflow UI Enhancements transform the existing single-order interface into a comprehensive multi-order management system with intuitive batch visualization, drag-and-drop route optimization, real-time progress tracking, and integrated customer communication tools.

## 🚀 Key Features

### **Multi-Order Dashboard**
- **Batch overview card** with metrics, progress tracking, and quick actions
- **Interactive route visualization** with Google Maps integration and waypoint management
- **Order sequence management** with drag-and-drop reordering capabilities
- **Real-time status updates** with automatic synchronization across all components

### **Enhanced Navigation Interface**
- **In-app turn-by-turn navigation** with voice guidance and traffic integration
- **Multi-waypoint route display** with pickup and delivery sequence visualization
- **Navigation instruction overlay** with clear maneuver guidance and ETA updates
- **Route optimization controls** with manual and automatic resequencing options

### **Customer Communication Hub**
- **Integrated communication panel** with call, message, and notification features
- **Batch notification management** with automated customer updates
- **ETA management tools** with real-time adjustment capabilities
- **Delivery confirmation interface** with photo capture and customer feedback

## 🏗️ UI Component Architecture

### **Multi-Order Driver Dashboard**
```dart
class MultiOrderDriverDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchState = ref.watch(activeBatchProvider);
    final driverStatus = ref.watch(driverStatusProvider);
    final navigationState = ref.watch(enhancedNavigationProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced app bar with batch information
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_getBatchTitle(batchState.value)),
              background: BatchStatusHeader(
                batch: batchState.value,
                driverStatus: driverStatus.value,
              ),
            ),
            actions: [
              BatchMenuButton(),
              NotificationButton(),
              IconButton(
                onPressed: () => _showDriverSettings(context),
                icon: Icon(Icons.settings),
              ),
            ],
          ),
          
          // Batch overview section
          SliverToBoxAdapter(
            child: batchState.when(
              data: (batch) => batch != null 
                ? BatchOverviewCard(batch: batch)
                : NoBatchActiveCard(),
              loading: () => BatchLoadingCard(),
              error: (error, stack) => BatchErrorCard(error: error),
            ),
          ),
          
          // Route visualization section
          SliverToBoxAdapter(
            child: RouteVisualizationCard(
              navigationState: navigationState.value,
              onRouteOptimize: () => _optimizeRoute(context, ref),
              onNavigationStart: () => _startNavigation(context, ref),
            ),
          ),
          
          // Order sequence list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final batch = batchState.value;
                if (batch == null || index >= batch.orders.length) return null;
                
                return OrderSequenceCard(
                  order: batch.orders[index],
                  sequenceNumber: index + 1,
                  isActive: index == batch.currentOrderIndex,
                  onStatusUpdate: (status) => _updateOrderStatus(
                    batch.orders[index].id, status, ref
                  ),
                  onReorder: (oldIndex, newIndex) => _reorderBatch(
                    batch.id, oldIndex, newIndex, ref
                  ),
                );
              },
              childCount: batchState.value?.orders.length ?? 0,
            ),
          ),
          
          // Customer communication section
          SliverToBoxAdapter(
            child: CustomerCommunicationPanel(
              batch: batchState.value,
              onCustomerContact: _handleCustomerContact,
              onBatchNotification: _sendBatchNotification,
            ),
          ),
        ],
      ),
      
      // Enhanced floating action button with batch controls
      floatingActionButton: BatchActionFAB(
        batch: batchState.value,
        navigationState: navigationState.value,
        onAction: (action) => _handleBatchAction(action, context, ref),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  String _getBatchTitle(DeliveryBatch? batch) {
    if (batch == null) return 'Driver Dashboard';
    return 'Batch #${batch.batchNumber}';
  }
}
```

### **Batch Overview Card**
```dart
class BatchOverviewCard extends StatelessWidget {
  final DeliveryBatch batch;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with batch info and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch #${batch.batchNumber}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${batch.orders.length} orders • ${batch.totalDistanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                BatchStatusChip(status: batch.status),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Metrics row
            Row(
              children: [
                Expanded(
                  child: BatchMetricTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders',
                    value: '${batch.orders.length}',
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: BatchMetricTile(
                    icon: Icons.route_outlined,
                    label: 'Distance',
                    value: '${batch.totalDistanceKm.toStringAsFixed(1)} km',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: BatchMetricTile(
                    icon: Icons.schedule_outlined,
                    label: 'Est. Time',
                    value: '${batch.estimatedDurationMinutes} min',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: BatchMetricTile(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Efficiency',
                    value: '${batch.optimizationScore.toStringAsFixed(0)}%',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Progress indicator
            BatchProgressIndicator(batch: batch),
            
            SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: batch.status == BatchStatus.planned
                        ? () => _startBatch(context)
                        : null,
                    icon: Icon(Icons.play_arrow),
                    label: Text(_getActionButtonText(batch.status)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _optimizeRoute(context),
                    icon: Icon(Icons.route),
                    label: Text('Optimize'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getActionButtonText(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return 'Start Batch';
      case BatchStatus.active:
        return 'In Progress';
      case BatchStatus.paused:
        return 'Resume';
      case BatchStatus.completed:
        return 'Completed';
      default:
        return 'Start Batch';
    }
  }
}
```

### **Interactive Route Visualization**
```dart
class RouteVisualizationCard extends StatefulWidget {
  final NavigationState? navigationState;
  final VoidCallback onRouteOptimize;
  final VoidCallback onNavigationStart;
  
  @override
  State<RouteVisualizationCard> createState() => _RouteVisualizationCardState();
}

class _RouteVisualizationCardState extends State<RouteVisualizationCard> {
  bool _isFullScreen = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header with controls
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Route Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onRouteOptimize,
                      icon: Icon(Icons.auto_fix_high),
                      tooltip: 'Optimize Route',
                    ),
                    IconButton(
                      onPressed: widget.onNavigationStart,
                      icon: Icon(Icons.navigation),
                      tooltip: 'Start Navigation',
                    ),
                    IconButton(
                      onPressed: () => _toggleFullScreen(),
                      icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                      tooltip: 'Toggle Full Screen',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Interactive map
          Container(
            height: _isFullScreen ? MediaQuery.of(context).size.height * 0.7 : 280,
            child: MultiOrderRouteMap(
              navigationState: widget.navigationState,
              onWaypointTap: _handleWaypointTap,
              onRouteReorder: _handleRouteReorder,
              showTraffic: true,
              showAlternativeRoutes: true,
            ),
          ),
          
          // Route summary
          Padding(
            padding: EdgeInsets.all(16),
            child: RouteSummaryRow(
              navigationState: widget.navigationState,
            ),
          ),
        ],
      ),
    );
  }
  
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }
}
```

### **Order Sequence Management**
```dart
class OrderSequenceCard extends StatefulWidget {
  final BatchedOrder order;
  final int sequenceNumber;
  final bool isActive;
  final Function(DriverOrderStatus) onStatusUpdate;
  final Function(int, int) onReorder;
  
  @override
  State<OrderSequenceCard> createState() => _OrderSequenceCardState();
}

class _OrderSequenceCardState extends State<OrderSequenceCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: widget.isActive ? 6 : 2,
            child: Container(
              decoration: widget.isActive 
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
              child: ExpansionTile(
                leading: _buildSequenceAvatar(),
                title: _buildOrderTitle(),
                subtitle: _buildOrderSubtitle(),
                trailing: _buildOrderTrailing(),
                children: [
                  OrderDetailsExpansion(
                    order: widget.order,
                    onStatusUpdate: widget.onStatusUpdate,
                  ),
                ],
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSequenceAvatar() {
    return CircleAvatar(
      backgroundColor: _getSequenceColor(),
      child: Text(
        '${widget.sequenceNumber}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  Widget _buildOrderTitle() {
    return Text(
      'Order #${widget.order.orderNumber}',
      style: TextStyle(
        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
        fontSize: 16,
      ),
    );
  }
  
  Widget _buildOrderSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.order.vendorName} → ${widget.order.customerName}',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 4),
        OrderStatusRow(order: widget.order),
        SizedBox(height: 4),
        Text(
          'ETA: ${_formatTime(widget.order.estimatedDeliveryTime)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrderTrailing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'RM ${widget.order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getSequenceColor() {
    if (widget.isActive) return Theme.of(context).primaryColor;
    
    switch (widget.order.status) {
      case BatchOrderStatus.completed:
        return Colors.green;
      case BatchOrderStatus.active:
        return Colors.orange;
      case BatchOrderStatus.pending:
        return Colors.grey;
      case BatchOrderStatus.delayed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

### **Enhanced Floating Action Button**
```dart
class BatchActionFAB extends StatelessWidget {
  final DeliveryBatch? batch;
  final NavigationState? navigationState;
  final Function(BatchAction) onAction;
  
  @override
  Widget build(BuildContext context) {
    if (batch == null) return SizedBox.shrink();
    
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 8,
      children: _buildSpeedDialChildren(context),
    );
  }
  
  List<SpeedDialChild> _buildSpeedDialChildren(BuildContext context) {
    final children = <SpeedDialChild>[];
    
    // Navigation actions
    if (navigationState?.isNavigating != true) {
      children.add(SpeedDialChild(
        child: Icon(Icons.navigation),
        label: 'Start Navigation',
        backgroundColor: Colors.blue,
        onTap: () => onAction(BatchAction.startNavigation),
      ));
    } else {
      children.add(SpeedDialChild(
        child: Icon(Icons.stop),
        label: 'Stop Navigation',
        backgroundColor: Colors.red,
        onTap: () => onAction(BatchAction.stopNavigation),
      ));
    }
    
    // Status update actions
    final currentOrder = _getCurrentOrder();
    if (currentOrder != null) {
      children.addAll(_getStatusActions(currentOrder));
    }
    
    // Batch management actions
    children.addAll([
      SpeedDialChild(
        child: Icon(Icons.reorder),
        label: 'Reorder Route',
        backgroundColor: Colors.orange,
        onTap: () => onAction(BatchAction.reorderRoute),
      ),
      SpeedDialChild(
        child: Icon(Icons.pause),
        label: batch!.status == BatchStatus.active ? 'Pause Batch' : 'Resume Batch',
        backgroundColor: Colors.grey,
        onTap: () => onAction(
          batch!.status == BatchStatus.active 
            ? BatchAction.pauseBatch 
            : BatchAction.resumeBatch
        ),
      ),
      SpeedDialChild(
        child: Icon(Icons.phone),
        label: 'Call Customer',
        backgroundColor: Colors.green,
        onTap: () => onAction(BatchAction.callCustomer),
      ),
      SpeedDialChild(
        child: Icon(Icons.message),
        label: 'Send Update',
        backgroundColor: Colors.purple,
        onTap: () => onAction(BatchAction.sendUpdate),
      ),
    ]);
    
    return children;
  }
  
  List<SpeedDialChild> _getStatusActions(BatchedOrder order) {
    final actions = <SpeedDialChild>[];
    
    switch (order.pickupStatus) {
      case OrderPickupStatus.pending:
        actions.add(SpeedDialChild(
          child: Icon(Icons.directions_car),
          label: 'En Route to Pickup',
          backgroundColor: Colors.blue,
          onTap: () => onAction(BatchAction.enRouteToPickup),
        ));
        break;
      case OrderPickupStatus.enRoute:
        actions.add(SpeedDialChild(
          child: Icon(Icons.store),
          label: 'Arrived at Vendor',
          backgroundColor: Colors.orange,
          onTap: () => onAction(BatchAction.arrivedAtVendor),
        ));
        break;
      case OrderPickupStatus.arrived:
        actions.add(SpeedDialChild(
          child: Icon(Icons.shopping_bag),
          label: 'Order Picked Up',
          backgroundColor: Colors.green,
          onTap: () => onAction(BatchAction.orderPickedUp),
        ));
        break;
    }
    
    if (order.pickupStatus == OrderPickupStatus.pickedUp) {
      switch (order.deliveryStatus) {
        case OrderDeliveryStatus.pending:
          actions.add(SpeedDialChild(
            child: Icon(Icons.local_shipping),
            label: 'En Route to Customer',
            backgroundColor: Colors.blue,
            onTap: () => onAction(BatchAction.enRouteToCustomer),
          ));
          break;
        case OrderDeliveryStatus.enRoute:
          actions.add(SpeedDialChild(
            child: Icon(Icons.home),
            label: 'Arrived at Customer',
            backgroundColor: Colors.orange,
            onTap: () => onAction(BatchAction.arrivedAtCustomer),
          ));
          break;
        case OrderDeliveryStatus.arrived:
          actions.add(SpeedDialChild(
            child: Icon(Icons.check_circle),
            label: 'Complete Delivery',
            backgroundColor: Colors.green,
            onTap: () => onAction(BatchAction.completeDelivery),
          ));
          break;
      }
    }
    
    return actions;
  }
}
```

## 🎨 Design System Integration

### **Material Design 3 Components**
```dart
class GigaEatsTheme {
  static ThemeData get driverTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2E7D32), // GigaEats green
      brightness: Brightness.light,
    ),
    
    // Card theme for batch components
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // App bar theme
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // List tile theme for order cards
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
```

### **Responsive Design Patterns**
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 800 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Usage in driver dashboard
class AdaptiveDriverDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileDriverDashboard(),
      tablet: TabletDriverDashboard(),
    );
  }
}
```

## 🧪 UI Testing Strategy

### **Widget Testing**
```dart
// Test batch overview card displays correct information
testWidgets('BatchOverviewCard displays batch information correctly', (tester) async {
  final mockBatch = DeliveryBatch(
    id: 'batch_123',
    batchNumber: 'B001',
    orders: [createMockOrder(), createMockOrder(), createMockOrder()],
    totalDistanceKm: 12.5,
    estimatedDurationMinutes: 45,
    optimizationScore: 85.0,
    status: BatchStatus.planned,
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BatchOverviewCard(batch: mockBatch),
      ),
    ),
  );
  
  // Verify batch information is displayed
  expect(find.text('Batch #B001'), findsOneWidget);
  expect(find.text('3 orders • 12.5 km'), findsOneWidget);
  expect(find.text('45 min'), findsOneWidget);
  expect(find.text('85%'), findsOneWidget);
  
  // Verify action buttons are present
  expect(find.text('Start Batch'), findsOneWidget);
  expect(find.text('Optimize'), findsOneWidget);
});

// Test order sequence card interaction
testWidgets('OrderSequenceCard handles status updates', (tester) async {
  bool statusUpdated = false;
  DriverOrderStatus? updatedStatus;
  
  final mockOrder = createMockBatchedOrder();
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OrderSequenceCard(
          order: mockOrder,
          sequenceNumber: 1,
          isActive: true,
          onStatusUpdate: (status) {
            statusUpdated = true;
            updatedStatus = status;
          },
          onReorder: (oldIndex, newIndex) {},
        ),
      ),
    ),
  );
  
  // Expand the card
  await tester.tap(find.byType(ExpansionTile));
  await tester.pumpAndSettle();
  
  // Tap status update button
  await tester.tap(find.text('Mark Picked Up'));
  await tester.pump();
  
  expect(statusUpdated, isTrue);
  expect(updatedStatus, equals(DriverOrderStatus.pickedUp));
});

// Test floating action button speed dial
testWidgets('BatchActionFAB shows correct actions', (tester) async {
  final mockBatch = createMockBatch();
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        floatingActionButton: BatchActionFAB(
          batch: mockBatch,
          navigationState: null,
          onAction: (action) {},
        ),
      ),
    ),
  );
  
  // Tap to open speed dial
  await tester.tap(find.byType(SpeedDial));
  await tester.pumpAndSettle();
  
  // Verify action buttons are present
  expect(find.text('Start Navigation'), findsOneWidget);
  expect(find.text('Reorder Route'), findsOneWidget);
  expect(find.text('Call Customer'), findsOneWidget);
  expect(find.text('Send Update'), findsOneWidget);
});
```

This comprehensive UI enhancement system provides an intuitive, efficient, and visually appealing interface for managing multi-order deliveries while maintaining consistency with the existing GigaEats design language and user experience patterns.
