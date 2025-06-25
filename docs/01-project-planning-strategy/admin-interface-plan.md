# 🎯 GigaEats Admin Interface Implementation Plan

## 📋 Current State Analysis

**Existing Foundation:**
- ✅ Basic admin dashboard scaffolding with navigation tabs
- ✅ Supabase backend with authentication and RLS policies
- ✅ Flutter/Dart with Riverpod state management
- ✅ Role-based authentication system
- ✅ Material Design 3 theming
- ✅ Go Router configuration for admin routes

**Gaps Identified:**
- ❌ Most admin screens are placeholder "Coming Soon" implementations
- ❌ No real-time data integration for admin dashboards
- ❌ Missing comprehensive user management backend
- ❌ No admin-specific database views and analytics
- ❌ Limited audit logging and activity tracking
- ❌ No data export functionality

---

## 🏗️ Phase 1: Backend Infrastructure (Weeks 1-2)

### 1.1 Database Schema Enhancements

**Admin-Specific Tables:**
```sql
-- Admin activity logs
CREATE TABLE admin_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES auth.users(id),
    action_type TEXT NOT NULL,
    target_type TEXT NOT NULL, -- 'user', 'order', 'vendor', etc.
    target_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- System settings
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Admin notifications
CREATE TABLE admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'info', 'warning', 'error', 'success'
    priority INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high, 4=critical
    is_read BOOLEAN DEFAULT FALSE,
    admin_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Support tickets
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open', -- 'open', 'in_progress', 'resolved', 'closed'
    priority TEXT NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    assigned_admin_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Analytics Views:**
```sql
-- Daily analytics view
CREATE VIEW daily_analytics AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) FILTER (WHERE status = 'delivered') as completed_orders,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
    SUM(total_amount) FILTER (WHERE status = 'delivered') as daily_revenue,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT vendor_id) as active_vendors
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- User statistics view
CREATE VIEW user_statistics AS
SELECT 
    role,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE email_confirmed_at IS NOT NULL) as verified_users,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as new_this_week,
    COUNT(*) FILTER (WHERE last_sign_in_at >= CURRENT_DATE - INTERVAL '7 days') as active_this_week
FROM auth.users u
JOIN user_profiles up ON u.id = up.user_id
GROUP BY role;
```

### 1.2 Enhanced RLS Policies

```sql
-- Admin access policies
CREATE POLICY "Admins can view all admin activity logs" ON admin_activity_logs
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can manage system settings" ON system_settings
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Enhanced user access for admins
CREATE POLICY "Admins can view all user profiles" ON user_profiles
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );
```

### 1.3 Database Functions

```sql
-- Function to log admin activities
CREATE OR REPLACE FUNCTION log_admin_activity(
    p_action_type TEXT,
    p_target_type TEXT,
    p_target_id UUID DEFAULT NULL,
    p_details JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    activity_id UUID;
BEGIN
    INSERT INTO admin_activity_logs (
        admin_user_id,
        action_type,
        target_type,
        target_id,
        details
    ) VALUES (
        auth.uid(),
        p_action_type,
        p_target_type,
        p_target_id,
        p_details
    ) RETURNING id INTO activity_id;
    
    RETURN activity_id;
END;
$$;

-- Function to get comprehensive user statistics
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check if user is admin
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: Admin role required';
    END IF;
    
    SELECT jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM auth.users),
        'total_orders', (SELECT COUNT(*) FROM orders),
        'total_revenue', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status = 'delivered'),
        'active_vendors', (SELECT COUNT(*) FROM vendors WHERE is_active = true),
        'pending_orders', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
        'today_orders', (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE),
        'today_revenue', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'delivered')
    ) INTO result;
    
    RETURN result;
END;
$$;
```

---

## 🎨 Phase 2: Frontend Data Layer (Weeks 3-4)

### 2.1 Admin Data Models

**File: `lib/features/admin/data/models/admin_user.dart`**
```dart
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    required bool isVerified,
    required bool isActive,
    required DateTime createdAt,
    DateTime? lastSignInAt,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}
```

**File: `lib/features/admin/data/models/admin_activity_log.dart`**
```dart
@freezed
class AdminActivityLog with _$AdminActivityLog {
  const factory AdminActivityLog({
    required String id,
    required String adminUserId,
    required String actionType,
    required String targetType,
    String? targetId,
    required Map<String, dynamic> details,
    String? ipAddress,
    String? userAgent,
    required DateTime createdAt,
  }) = _AdminActivityLog;

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) =>
      _$AdminActivityLogFromJson(json);
}
```

### 2.2 Admin Repositories

**File: `lib/features/admin/data/repositories/admin_repository.dart`**
```dart
class AdminRepository extends BaseRepository {
  AdminRepository() : super();

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    return executeQuery(() async {
      final response = await supabase.rpc('get_admin_dashboard_stats');
      return response as Map<String, dynamic>;
    });
  }

  /// Get all users with pagination and filters
  Future<List<AdminUser>> getUsers({
    String? searchQuery,
    UserRole? role,
    bool? isVerified,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('auth.users')
          .select('''
            id, email, phone, created_at, last_sign_in_at, email_confirmed_at,
            user_profiles!inner(full_name, role, is_active)
          ''');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'email.ilike.%$searchQuery%,user_profiles.full_name.ilike.%$searchQuery%'
        );
      }

      if (role != null) {
        query = query.eq('user_profiles.role', role.value);
      }

      if (isVerified != null) {
        if (isVerified) {
          query = query.not('email_confirmed_at', 'is', null);
        } else {
          query = query.is_('email_confirmed_at', null);
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => AdminUser.fromJson(json)).toList();
    });
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    return executeQuery(() async {
      await supabase
          .from('user_profiles')
          .update({'is_active': isActive})
          .eq('user_id', userId);

      // Log admin activity
      await supabase.rpc('log_admin_activity', params: {
        'p_action_type': isActive ? 'user_activated' : 'user_deactivated',
        'p_target_type': 'user',
        'p_target_id': userId,
      });
    });
  }

  /// Get activity logs
  Future<List<AdminActivityLog>> getActivityLogs({
    int limit = 100,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final response = await supabase
          .from('admin_activity_logs')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => AdminActivityLog.fromJson(json)).toList();
    });
  }
}
```

### 2.3 Admin Providers

**File: `lib/features/admin/presentation/providers/admin_providers.dart`**
```dart
// Admin Repository Provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// Dashboard Statistics Provider
final adminDashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(adminRepositoryProvider);
  return repository.getDashboardStats();
});

// Users Management Provider
final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final repository = ref.read(adminRepositoryProvider);
  return AdminUsersNotifier(repository);
});

// Activity Logs Provider
final adminActivityLogsProvider = FutureProvider<List<AdminActivityLog>>((ref) async {
  final repository = ref.read(adminRepositoryProvider);
  return repository.getActivityLogs();
});

// Real-time notifications provider
final adminNotificationsProvider = StreamProvider<List<AdminNotification>>((ref) {
  return Supabase.instance.client
      .from('admin_notifications')
      .stream(primaryKey: ['id'])
      .eq('admin_user_id', Supabase.instance.client.auth.currentUser!.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => AdminNotification.fromJson(json)).toList());
});
```

---

## 🖥️ Phase 3: Admin Interface Implementation (Weeks 5-8)

### 3.1 Enhanced Dashboard

**File: `lib/features/admin/presentation/screens/admin_dashboard_enhanced.dart`**
```dart
class AdminDashboardEnhanced extends ConsumerWidget {
  const AdminDashboardEnhanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final notificationsAsync = ref.watch(adminNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Real-time notifications badge
          notificationsAsync.when(
            data: (notifications) => _buildNotificationBadge(context, notifications),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Icon(Icons.notifications_off),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminDashboardStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(adminDashboardStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-time statistics cards
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorWidget(error),
              ),
              
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActions(context),
              
              const SizedBox(height: 24),
              
              // Recent activity and charts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildRecentActivity(ref),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildSystemHealth(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          stats['total_users']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
          subtitle: '+${stats['new_users_today'] ?? 0} today',
        ),
        _buildStatCard(
          'Total Orders',
          stats['total_orders']?.toString() ?? '0',
          Icons.shopping_cart,
          Colors.green,
          subtitle: '+${stats['today_orders'] ?? 0} today',
        ),
        _buildStatCard(
          'Revenue',
          'RM ${(stats['total_revenue'] ?? 0).toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.orange,
          subtitle: 'RM ${(stats['today_revenue'] ?? 0).toStringAsFixed(2)} today',
        ),
        _buildStatCard(
          'Active Vendors',
          stats['active_vendors']?.toString() ?? '0',
          Icons.store,
          Colors.purple,
          subtitle: '${stats['pending_vendors'] ?? 0} pending',
        ),
      ],
    );
  }
}
```

### 3.2 Comprehensive User Management

**File: `lib/features/admin/presentation/screens/admin_users_enhanced.dart`**
```dart
class AdminUsersEnhanced extends ConsumerStatefulWidget {
  const AdminUsersEnhanced({super.key});

  @override
  ConsumerState<AdminUsersEnhanced> createState() => _AdminUsersEnhancedState();
}

class _AdminUsersEnhancedState extends ConsumerState<AdminUsersEnhanced> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;
  bool? _isVerifiedFilter;

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _performSearch(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UserRole?>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Roles')),
                          ...UserRole.values.map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value);
                          _performSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _isVerifiedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Users')),
                          DropdownMenuItem(value: true, child: Text('Verified')),
                          DropdownMenuItem(value: false, child: Text('Unverified')),
                        ],
                        onChanged: (value) {
                          setState(() => _isVerifiedFilter = value);
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Users list
          Expanded(
            child: usersState.when(
              data: (users) => ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) => _buildUserCard(users[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
