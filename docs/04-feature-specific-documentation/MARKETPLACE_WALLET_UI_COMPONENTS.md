# GigaEats Marketplace Wallet UI Components

## 🎯 Overview

This document describes the comprehensive Material Design 3 UI implementation for the GigaEats marketplace wallet system. The components provide role-based interfaces for customers, vendors, sales agents, drivers, and administrators with consistent design patterns and accessibility features.

## 🎨 Design System

### **Material Design 3 Implementation**

**Color Scheme**:
- **Primary**: AppTheme.primaryColor (GigaEats brand color)
- **Success**: Green (#4CAF50) for positive actions and earnings
- **Warning**: Orange (#FF9800) for alerts and pending states
- **Error**: Red (#F44336) for failures and negative amounts
- **Info**: Blue (#2196F3) for informational content

**Typography**:
- **Headlines**: Bold weights for main titles and balance displays
- **Body Text**: Regular weights for descriptions and content
- **Captions**: Light weights for timestamps and metadata

**Spacing**:
- **Base Unit**: 8px grid system
- **Card Padding**: 16-24px for content areas
- **Section Spacing**: 24px between major sections
- **Item Spacing**: 8-12px between related items

## 📱 Screen Components

### **1. Wallet Dashboard Screen**

**File**: `wallet_dashboard_screen.dart`

**Purpose**: Main wallet interface with role-based content and quick actions

**Key Features**:
- ✅ **Role-based content** with different layouts for each user type
- ✅ **Real-time balance updates** via Riverpod providers
- ✅ **Quick action grid** with role-specific actions
- ✅ **Commission summary** for earning roles (vendor, sales agent, driver)
- ✅ **Statistics overview** with earnings, withdrawals, and transaction counts
- ✅ **Recent transactions** preview with "View All" navigation
- ✅ **Notification badge** with unread count indicator
- ✅ **Pull-to-refresh** functionality

**Role Variants**:
```dart
// Specialized dashboard variants for each role
class VendorWalletDashboard extends ConsumerWidget { ... }
class SalesAgentWalletDashboard extends ConsumerWidget { ... }
class DriverWalletDashboard extends ConsumerWidget { ... }
class CustomerWalletDashboard extends ConsumerWidget { ... }
class AdminWalletDashboard extends ConsumerWidget { ... }
```

**Layout Structure**:
1. **App Bar** with notifications and settings
2. **Wallet Balance Card** with gradient background
3. **Quick Actions Grid** (2x2 or 2x3 based on role)
4. **Commission Summary** (for earning roles)
5. **Statistics Grid** (2x2 overview cards)
6. **Recent Transactions** list preview
7. **Recent Notifications** list preview

### **2. Transaction History Screen**

**File**: `transaction_history_screen.dart`

**Purpose**: Complete transaction history with filtering and pagination

**Key Features**:
- ✅ **Transaction summary card** with credits, debits, and net amount
- ✅ **Advanced filtering** by type, date range, and amount
- ✅ **Filter chips** showing active filters with clear options
- ✅ **Infinite scroll pagination** with load-more functionality
- ✅ **Pull-to-refresh** for latest transactions
- ✅ **Search functionality** (placeholder for future implementation)
- ✅ **Empty state** with contextual messaging
- ✅ **Error handling** with retry functionality

**Filter Options**:
- Transaction type (credit, debit, commission, payout, refund, adjustment, bonus)
- Date range (start date, end date)
- Amount range (future enhancement)
- Status filtering (completed, pending, failed)

## 🧩 Widget Components

### **1. Wallet Balance Card**

**File**: `wallet_balance_card.dart`

**Purpose**: Primary balance display with gradient design and role-specific styling

**Features**:
- ✅ **Gradient background** with role-specific colors
- ✅ **Role icon** and display name
- ✅ **Wallet status indicator** (active, inactive, unverified, empty)
- ✅ **Available balance** with large, prominent typography
- ✅ **Pending balance** display when applicable
- ✅ **Auto-payout status** indicator
- ✅ **Action buttons** for payout requests and transaction viewing
- ✅ **Loading and error states** with appropriate messaging

**Status Indicators**:
```dart
enum WalletStatus {
  active,    // Green - fully functional
  inactive,  // Red - disabled wallet
  unverified, // Orange - needs verification
  empty,     // Grey - no balance
}
```

### **2. Wallet Quick Actions**

**File**: `wallet_quick_actions.dart`

**Purpose**: Role-based action grid with contextual functionality

**Role-Specific Actions**:

**Vendor Actions**:
- Transaction History
- Analytics
- Request Payout
- Commission Tracking

**Sales Agent Actions**:
- Transaction History
- Analytics
- Request Payout
- Sales Performance

**Driver Actions**:
- Transaction History
- Analytics
- Request Payout
- Delivery Earnings

**Customer Actions**:
- Transaction History
- Analytics
- Add Funds
- Rewards

**Admin Actions**:
- Platform Overview
- Payout Management
- Audit Logs
- Commission Settings

**Action Card Design**:
- Icon with role-specific color coding
- Title and subtitle text
- Enabled/disabled states with visual feedback
- Lock icon for unavailable actions
- Tap feedback with Material ripple effects

### **3. Recent Transactions Widget**

**File**: `recent_transactions_widget.dart`

**Purpose**: Transaction list with rich formatting and status indicators

**Features**:
- ✅ **Transaction tiles** with icon, description, and amount
- ✅ **Color-coded amounts** (green for credits, red for debits)
- ✅ **Transaction type icons** with contextual colors
- ✅ **Status badges** with appropriate styling
- ✅ **Timestamp formatting** (relative time for recent, dates for older)
- ✅ **Empty state** with encouraging messaging
- ✅ **Error state** with retry functionality
- ✅ **Loading state** with skeleton placeholders

**Transaction Tile Components**:
```dart
class TransactionTile extends StatelessWidget {
  // Icon container with type-specific color
  // Transaction description and type
  // Formatted timestamp
  // Amount with +/- indicator
  // Status badge
  // Tap navigation to details
}
```

### **4. Commission Summary Widget**

**File**: `commission_summary_widget.dart`

**Purpose**: Earnings overview for revenue-generating roles

**Features**:
- ✅ **Period-based earnings** display (this month, last month, etc.)
- ✅ **Growth rate indicator** with trending icons
- ✅ **Order count** and average commission
- ✅ **Role-specific messaging** and icons
- ✅ **Gradient background** with commission theme
- ✅ **Action button** to detailed analytics
- ✅ **Empty state** for new users

**Metrics Displayed**:
- Total earned in selected period
- Growth rate compared to previous period
- Number of orders completed
- Average commission per order
- Role-specific earnings label

### **5. Wallet Notifications Widget**

**File**: `wallet_notifications_widget.dart`

**Purpose**: Real-time notification display with interactive features

**Features**:
- ✅ **Notification tiles** with type-specific icons and colors
- ✅ **Read/unread states** with visual differentiation
- ✅ **Swipe-to-dismiss** functionality
- ✅ **Tap-to-navigate** with action URLs
- ✅ **Timestamp formatting** with relative time
- ✅ **Notification types** with appropriate styling
- ✅ **Empty state** with helpful messaging

**Notification Types**:
```dart
enum WalletNotificationType {
  balanceUpdate,        // Balance changes
  transactionReceived,  // New transactions
  payoutCompleted,      // Successful payouts
  payoutFailed,         // Failed payouts
  autoPayoutTriggered,  // Auto-payout threshold reached
  lowBalance,           // Balance warning
  verificationRequired, // Account verification needed
}
```

## 🎯 Role-Based UI Patterns

### **Access Control**

```dart
// Role-based widget visibility
if (_shouldShowCommissionSummary(userRole)) {
  CommissionSummaryWidget(userRole: userRole),
}

// Role-specific action availability
bool canRequestPayout = wallet.canRequestPayout && 
                       ['vendor', 'sales_agent', 'driver'].contains(userRole);
```

### **Content Customization**

```dart
// Role-specific labels and messaging
String _getRoleEarningsLabel(String role) {
  switch (role) {
    case 'vendor': return 'Restaurant earnings from orders';
    case 'sales_agent': return 'Commission from sales';
    case 'driver': return 'Delivery earnings';
    default: return 'Total earnings';
  }
}
```

### **Navigation Patterns**

```dart
// Role-based route generation
String getDashboardRoute(UserRole role) {
  switch (role) {
    case UserRole.vendor: return '/vendor/wallet';
    case UserRole.salesAgent: return '/sales-agent/wallet';
    case UserRole.driver: return '/driver/wallet';
    case UserRole.customer: return '/customer/wallet';
    case UserRole.admin: return '/admin/wallet';
  }
}
```

## 🔄 State Management Integration

### **Provider Watching**

```dart
// Real-time balance updates
final walletState = ref.watch(currentUserWalletProvider);

// Transaction history with pagination
final transactionState = ref.watch(currentUserTransactionHistoryProvider);

// Notification count for badge
final unreadCount = ref.watch(currentUserUnreadNotificationsCountProvider);
```

### **Action Handling**

```dart
// Centralized actions through providers
final walletActions = ref.read(walletActionsProvider);
await walletActions.refreshCurrentUserWallet();

final transactionActions = ref.read(transactionActionsProvider);
await transactionActions.loadMoreTransactions(walletId);
```

### **Error Handling**

```dart
// Consistent error state handling
if (state.errorMessage != null) {
  return ErrorWidget(
    message: state.errorMessage!,
    onRetry: () => actions.refresh(),
  );
}
```

## 📱 Responsive Design

### **Breakpoints**

- **Mobile**: < 600px - Single column layout
- **Tablet**: 600-1200px - Adaptive grid layouts
- **Desktop**: > 1200px - Multi-column layouts with sidebars

### **Adaptive Layouts**

```dart
// Responsive grid columns
int getGridColumns(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1200) return 4;
  if (width > 600) return 3;
  return 2;
}
```

## ♿ Accessibility Features

### **Semantic Labels**

```dart
// Screen reader support
Semantics(
  label: 'Wallet balance: ${wallet.formattedAvailableBalance}',
  child: BalanceDisplay(...),
)
```

### **Focus Management**

```dart
// Keyboard navigation support
FocusableActionDetector(
  onShowFocusHighlight: (focused) => setState(() => _focused = focused),
  child: ActionCard(...),
)
```

### **Color Contrast**

- All text meets WCAG AA contrast requirements
- Color is not the only indicator of state
- Icons and text labels provide redundant information

## 🧪 Testing Support

### **Widget Testing**

```dart
// Test wallet balance display
testWidgets('displays wallet balance correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserWalletProvider.overrideWith((ref) => mockWalletState),
      ],
      child: WalletBalanceCard(userRole: 'vendor'),
    ),
  );
  
  expect(find.text('MYR 150.00'), findsOneWidget);
});
```

### **Integration Testing**

```dart
// Test transaction list pagination
testWidgets('loads more transactions on scroll', (tester) async {
  // Setup mock providers
  // Pump widget
  // Scroll to bottom
  // Verify more transactions loaded
});
```

This comprehensive UI implementation provides a consistent, accessible, and role-appropriate interface for the GigaEats marketplace wallet system, ensuring optimal user experience across all stakeholder types.
