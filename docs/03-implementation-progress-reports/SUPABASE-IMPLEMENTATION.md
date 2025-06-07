# GigaEats Firebase Auth + Supabase Backend Implementation Plan

Based on the GigaEats Flutter plan and PRD, here's a comprehensive implementation plan for integrating Firebase Authentication with Supabase as the backend solution.

## Phase 1: Firebase Auth + Supabase Setup & Foundation (Weeks 1-4)

### Week 1: Project Setup & Hybrid Authentication

````dart path=lib/core/config/firebase_config.dart mode=EDIT
class FirebaseConfig {
  // Firebase configuration for authentication
  static const String prodProjectId = 'gigaeats-prod';
  static const String devProjectId = 'gigaeats-dev';

  static String get projectId => const bool.fromEnvironment('dart.vm.product')
    ? prodProjectId : devProjectId;
}
````

````dart path=lib/core/config/supabase_config.dart mode=EDIT
class SupabaseConfig {
  // Production environment
  static const String prodUrl = 'https://your-prod-project.supabase.co';
  static const String prodAnonKey = 'your-prod-anon-key';
  static const String prodServiceKey = 'your-prod-service-key'; // For server operations

  // Development environment
  static const String devUrl = 'https://your-dev-project.supabase.co';
  static const String devAnonKey = 'your-dev-anon-key';
  static const String devServiceKey = 'your-dev-service-key';

  // Current environment settings
  static String get url => const bool.fromEnvironment('dart.vm.product')
    ? prodUrl : devUrl;
  static String get anonKey => const bool.fromEnvironment('dart.vm.product')
    ? prodAnonKey : devAnonKey;
  static String get serviceKey => const bool.fromEnvironment('dart.vm.product')
    ? prodServiceKey : devServiceKey;
}
````

1. **Create Firebase Project**
   - Set up development and production Firebase projects
   - Configure Firebase Authentication
   - Enable email/password and phone authentication
   - Set up custom claims for user roles (sales_agent, vendor, admin)

2. **Create Supabase Project**
   - Set up development and production environments
   - Configure project settings and region (Asia)
   - Set up database backups and monitoring
   - **Disable Supabase Auth** (we'll use Firebase Auth instead)

3. **Hybrid Authentication Setup**
   - Configure Firebase Auth for user authentication
   - Set up phone verification for Malaysian numbers (+60)
   - Create Firebase custom claims for role management
   - Implement Firebase ID token verification in Supabase Edge Functions
   - Set up user synchronization between Firebase and Supabase

4. **Update Flutter Dependencies**
   - Add Firebase packages (firebase_auth, firebase_core)
   - Add Supabase packages for data operations
   - Configure deep linking for auth callbacks

### Week 2: Database Schema Design & Firebase-Supabase Integration

````sql path=supabase/migrations/001_initial_schema.sql mode=EDIT
-- Users table synchronized with Firebase Auth
CREATE TABLE users (
  id UUID PRIMARY KEY, -- This will match Firebase UID
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  role user_role_enum NOT NULL DEFAULT 'sales_agent',
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (firebase_uid = auth.jwt() ->> 'sub');

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (firebase_uid = auth.jwt() ->> 'sub');
````

````dart path=lib/core/services/auth_sync_service.dart mode=EDIT
class AuthSyncService {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthSyncService({
    FirebaseAuth? firebaseAuth,
    SupabaseClient? supabase,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _supabase = supabase ?? Supabase.instance.client;

  // Sync Firebase user to Supabase
  Future<void> syncUserToSupabase(User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();

    // Set the Firebase ID token as auth header for Supabase
    _supabase.auth.setSession(AccessToken(idToken));

    // Upsert user data in Supabase
    await _supabase.from('users').upsert({
      'id': firebaseUser.uid,
      'firebase_uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'phone': firebaseUser.phoneNumber,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
````

1. **Core Tables Design**
   - Users table synchronized with Firebase Auth UIDs
   - Profiles table with extended user information
   - Vendors table with business details
   - Products table with bulk pricing options
   - Orders table with multi-vendor support
   - Order_items junction table

2. **Firebase-Supabase Integration**
   - Create Edge Function to verify Firebase ID tokens
   - Implement user synchronization service
   - Set up automatic user creation on first login
   - Configure JWT validation for Supabase RLS

3. **RLS Policies with Firebase Auth**
   - Define access policies using Firebase UID from JWT
   - Implement row-level security for sensitive data
   - Create service roles for admin operations
   - Use Firebase custom claims for role-based access

4. **Database Migrations**
   - Set up initial schema migration
   - Create seed data for testing
   - Implement user sync triggers

### Week 3-4: Firebase Token Verification & Storage Setup

````typescript path=supabase/functions/verify-firebase-token/index.ts mode=EDIT
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { initializeApp, cert } from 'https://esm.sh/firebase-admin@11.5.0/app'
import { getAuth } from 'https://esm.sh/firebase-admin@11.5.0/auth'

// Initialize Firebase Admin
const firebaseApp = initializeApp({
  credential: cert({
    projectId: Deno.env.get('FIREBASE_PROJECT_ID'),
    clientEmail: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
    privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
  }),
})

const auth = getAuth(firebaseApp)

serve(async (req) => {
  try {
    const { token } = await req.json()

    // Verify Firebase ID token
    const decodedToken = await auth.verifyIdToken(token)

    // Create Supabase client with service key
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Sync user data to Supabase
    const { error } = await supabase.from('users').upsert({
      id: decodedToken.uid,
      firebase_uid: decodedToken.uid,
      email: decodedToken.email,
      phone: decodedToken.phone_number,
      updated_at: new Date().toISOString(),
    })

    if (error) throw error

    return new Response(
      JSON.stringify({
        success: true,
        uid: decodedToken.uid,
        claims: decodedToken
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
````

1. **Firebase Token Verification Edge Function**
   - Create Supabase Edge Function to verify Firebase ID tokens
   - Implement automatic user synchronization
   - Set up Firebase Admin SDK in Deno environment
   - Configure environment variables for Firebase credentials

2. **Storage Buckets Setup**
   - Create buckets for:
     - Vendor profiles and certifications
     - Menu items and images
     - User documents (KYC)
     - FCM tokens storage
   - Configure access policies for each bucket using Firebase UID

3. **Initial API Implementation**
   - Create basic CRUD operations for all entities
   - Implement stored procedures for complex operations
   - Set up database triggers for audit logs
   - Configure RLS policies to use Firebase JWT claims

4. **Real-time Subscriptions**
   - Configure real-time channels for orders
   - Set up presence for online status tracking
   - Implement Firebase token validation for real-time connections

## Phase 2: Core Features Implementation (Weeks 5-12)

### Week 5-6: Firebase Auth Integration & User Management

````dart path=lib/data/repositories/auth_repository.dart mode=EDIT
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final AuthSyncService _authSync;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    AuthSyncService? authSync,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _authSync = authSync ?? AuthSyncService();

  // Firebase Auth methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Sync to Supabase
    if (credential.user != null) {
      await _authSync.syncUserToSupabase(credential.user!);
    }

    return credential;
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Sync to Supabase
    if (credential.user != null) {
      await _authSync.syncUserToSupabase(credential.user!);
    }

    return credential;
  }

  Future<void> setUserRole(String role) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Set custom claims via Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
      await callable.call({'uid': user.uid, 'role': role});

      // Force token refresh to get new claims
      await user.getIdToken(true);
    }
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.currentUser?.linkWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        // Handle code sent
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
      },
    );
  }
}
````

````dart path=lib/data/repositories/user_repository.dart mode=EDIT
class UserRepository {
  final SupabaseClient _client;
  final FirebaseAuth _firebaseAuth;

  UserRepository({
    SupabaseClient? client,
    FirebaseAuth? firebaseAuth,
  }) : _client = client ?? Supabase.instance.client,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<UserProfile?> getUserProfile(String firebaseUid) async {
    // Ensure Firebase token is set for Supabase
    await _setFirebaseToken();

    final response = await _client
      .from('profiles')
      .select('*, user_role:user_roles(*)')
      .eq('firebase_uid', firebaseUid)
      .single();

    return response != null ? UserProfile.fromJson(response) : null;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _setFirebaseToken();

    await _client
      .from('profiles')
      .update(profile.toJson())
      .eq('firebase_uid', profile.firebaseUid);
  }

  // KYC document upload
  Future<String> uploadKycDocument(File document, String firebaseUid) async {
    await _setFirebaseToken();

    final fileName = '${firebaseUid}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _client.storage.from('kyc_documents').upload(fileName, document);
    return _client.storage.from('kyc_documents').getPublicUrl(fileName);
  }

  Future<void> _setFirebaseToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      _client.auth.setSession(AccessToken(idToken));
    }
  }
}
````

1. **Firebase Authentication Flow**
   - Implement Firebase email/password authentication
   - Create phone verification for Malaysian numbers (+60)
   - Set up custom claims for user roles
   - Implement automatic Supabase user sync

2. **Multi-role Registration Flow**
   - Implement role-based registration screens
   - Create KYC document upload functionality
   - Use Firebase custom claims for role assignment
   - Sync role data to Supabase profiles

3. **Profile Management**
   - Create profile completion workflows
   - Implement avatar and document uploads
   - Build profile verification system for admins
   - Use Firebase UID as primary identifier

4. **Role-based Navigation**
   - Integrate Firebase auth state with Go Router
   - Implement role-based redirects using Firebase custom claims
   - Create protected routes with Firebase auth guards

### Week 7-8: Sales Agent Module

````dart path=lib/data/repositories/vendor_repository.dart mode=EDIT
class VendorRepository {
  final SupabaseClient _client;
  final FirebaseAuth _firebaseAuth;

  VendorRepository({
    SupabaseClient? client,
    FirebaseAuth? firebaseAuth,
  }) : _client = client ?? Supabase.instance.client,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<List<Vendor>> getVendorsStream({
    String? searchQuery,
    List<String>? cuisineTypes,
    String? location,
  }) async* {
    // Set Firebase token for authentication
    await _setFirebaseToken();

    var query = _client
      .from('vendors')
      .select('*, cuisine_types(*), ratings(*)')
      .eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
      query = query.overlaps('cuisine_type_ids', cuisineTypes);
    }

    if (location != null && location.isNotEmpty) {
      query = query.eq('service_area', location);
    }

    yield* query.stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Vendor.fromJson(json)).toList());
  }

  Future<void> _setFirebaseToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      _client.auth.setSession(AccessToken(idToken));
    }
  }
}
````

1. **Dashboard Implementation**
   - Create real-time order tracking dashboard
   - Implement commission calculation and display
   - Build performance metrics visualization

2. **Vendor Catalog**
   - Implement vendor browsing with filters
   - Create search functionality with PostgreSQL full-text search
   - Build vendor detail views with menu items

3. **Order Creation System**
   - Implement multi-vendor cart functionality
   - Create order customization options
   - Build order submission and tracking

4. **CRM Lite Features**
   - Implement customer management database
   - Create customer history tracking
   - Build note-taking and follow-up system

### Week 9-10: Vendor Module

````dart path=lib/data/repositories/menu_repository.dart mode=EDIT
class MenuRepository {
  final SupabaseClient _client;
  
  MenuRepository({SupabaseClient? client}) 
    : _client = client ?? Supabase.instance.client;
  
  Future<List<MenuItem>> getMenuItems(String vendorId) async {
    final response = await _client
      .from('menu_items')
      .select('*, pricing_tiers(*)')
      .eq('vendor_id', vendorId)
      .order('category');
    
    return response.map<MenuItem>((json) => MenuItem.fromJson(json)).toList();
  }
  
  Future<void> updateMenuItem(MenuItem item) async {
    // Start a transaction
    await _client.rpc('update_menu_item', params: {
      'item_data': item.toJson(),
      'pricing_tiers': item.pricingTiers.map((tier) => tier.toJson()).toList()
    });
  }
  
  Future<String> uploadMenuItemImage(File image, String itemId) async {
    final fileName = 'menu_items/$itemId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('menu_images').upload(fileName, image);
    return _client.storage.from('menu_images').getPublicUrl(fileName);
  }
}
````

1. **Profile Management**
   - Implement business details management
   - Create certification upload and verification
   - Build service area configuration

2. **Menu Management**
   - Create bulk pricing tier system
   - Implement MOQ (Minimum Order Quantity) settings
   - Build menu item availability toggles
   - Implement image upload and management

3. **Order Management**
   - Build order acceptance/rejection workflow
   - Create kitchen production view
   - Implement status update system
   - Build delivery coordination interface

4. **Analytics Dashboard**
   - Implement sales metrics visualization
   - Create popular items analysis
   - Build revenue tracking system

### Week 11-12: Admin Panel & Platform Management

1. **User Approval System**
   - Create verification workflow
   - Implement user management interface
   - Build role assignment and permissions

2. **Order Oversight**
   - Implement global order monitoring
   - Create dispute resolution interface
   - Build order intervention tools

3. **Commission Management**
   - Implement commission rate configuration
   - Create payout tracking system
   - Build financial reporting tools

4. **Basic Reporting**
   - Implement platform usage metrics
   - Create sales and revenue reports
   - Build user acquisition analytics

## Phase 3: Integration & Advanced Features (Weeks 13-20)

### Week 13-14: Payment Integration

````dart path=lib/data/services/payment_service.dart mode=EDIT
class PaymentService {
  final SupabaseClient _client;
  
  PaymentService({SupabaseClient? client}) 
    : _client = client ?? Supabase.instance.client;
  
  Future<PaymentResult> processFPXPayment(PaymentRequest request) async {
    try {
      // Call Supabase Edge Function for payment processing
      final response = await _client.functions.invoke(
        'process-fpx-payment',
        body: request.toJson(),
      );
      
      if (response.status != 200) {
        return PaymentResult.failure(
          message: 'Payment processing failed: ${response.data['error']}',
        );
      }
      
      // Update order status via transaction
      await _client.rpc('update_order_payment_status', params: {
        'order_id': request.orderId,
        'payment_id': response.data['payment_id'],
        'status': 'paid'
      });
      
      return PaymentResult.success(
        transactionId: response.data['transaction_id'],
        amount: request.amount,
      );
    } catch (e) {
      return PaymentResult.failure(message: e.toString());
    }
  }
}
````

1. **Malaysian Payment Gateway Integration**
   - Implement FPX integration via Edge Functions
   - Create e-wallet integrations (GrabPay, Touch 'n Go)
   - Build credit/debit card processing
   - Implement SST calculation and display

2. **Payment Webhook Handling**
   - Create webhook endpoints for payment callbacks
   - Implement payment status updates
   - Build payment reconciliation system

3. **Invoice Generation**
   - Implement automated invoice creation
   - Create receipt generation system
   - Build financial record keeping

### Week 15-16: Real-time Features & Firebase Notifications

````dart path=lib/data/services/notification_service.dart mode=EDIT
class NotificationService {
  final SupabaseClient _client;
  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _messaging;

  NotificationService({
    SupabaseClient? client,
    FirebaseAuth? firebaseAuth,
    FirebaseMessaging? messaging,
  }) : _client = client ?? Supabase.instance.client,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  // Subscribe to order updates via Supabase real-time
  Stream<RealtimeChannelSnapshot<Map<String, dynamic>>> subscribeToOrderUpdates(String orderId) async* {
    await _setFirebaseToken();

    yield* _client
      .channel('order-$orderId')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'orders',
          filter: 'id=eq.$orderId',
        ),
        (payload, [ref]) {
          // Handle payload
          return payload;
        },
      )
      .subscribe();
  }

  // Initialize Firebase Cloud Messaging
  Future<void> initializeFCM() async {
    // Request permission for notifications
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and store in Supabase
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      await _storeFCMToken(fcmToken);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_storeFCMToken);
  }

  // Store FCM token in Supabase
  Future<void> _storeFCMToken(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _setFirebaseToken();
      await _client.from('user_fcm_tokens').upsert({
        'firebase_uid': user.uid,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Send push notification via Firebase Admin SDK (Edge Function)
  Future<void> sendPushNotification({
    required String firebaseUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _setFirebaseToken();

    await _client.functions.invoke(
      'send-firebase-notification',
      body: {
        'firebase_uid': firebaseUid,
        'title': title,
        'body': body,
        'data': data,
      },
    );
  }

  Future<void> _setFirebaseToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      _client.auth.setSession(AccessToken(idToken));
    }
  }
}
````

1. **Supabase Real-time + Firebase Notifications**
   - Configure Supabase real-time channels for order updates
   - Implement Firebase Cloud Messaging for push notifications
   - Create hybrid notification system using both platforms
   - Store FCM tokens in Supabase for targeted messaging

2. **Push Notifications via Firebase**
   - Integrate Firebase Cloud Messaging
   - Implement notification preferences in Supabase
   - Create targeted notification system using Firebase Admin SDK
   - Handle notification permissions and token management

3. **Real-time Commission Tracking**
   - Implement live earnings display via Supabase real-time
   - Create commission calculation triggers
   - Build real-time financial dashboard
   - Use Firebase auth for secure access

4. **Delivery Tracking**
   - Implement Lalamove API integration via Supabase Edge Functions
   - Create real-time delivery status updates
   - Build delivery ETA calculation
   - Send delivery notifications via Firebase

### Week 17-18: Multi-language Support & Localization

1. **Database-driven Translations**
   - Create translations table in Supabase
   - Implement translation fetching system
   - Build language preference storage

2. **UI Localization**
   - Implement Flutter localization
   - Create language switching mechanism
   - Build RTL support for future expansion

3. **Content Management**
   - Implement dynamic content storage
   - Create admin interface for content updates
   - Build content versioning system

### Week 19-20: Performance Optimization & Security

1. **Database Optimization**
   - Implement proper indexing
   - Create query optimization
   - Build caching strategies

2. **Security Hardening**
   - Audit RLS policies
   - Implement rate limiting
   - Create security monitoring

3. **Offline Capabilities**
   - Implement local storage with Hive
   - Create data synchronization
   - Build conflict resolution

## Phase 4: Testing, Deployment & Launch (Weeks 21-24)

### Week 21-22: Comprehensive Testing

1. **Unit & Integration Testing**
   - Create repository tests
   - Implement service layer tests
   - Build UI component tests

2. **End-to-End Testing**
   - Implement user journey tests
   - Create performance testing
   - Build security testing

3. **User Acceptance Testing**
   - Conduct beta testing with real users
   - Create feedback collection system
   - Implement bug tracking and resolution

### Week 23-24: Deployment & Launch Preparation

1. **CI/CD Pipeline Setup**
   - Implement GitHub Actions workflow
   - Create automated testing
   - Build deployment automation

2. **Production Environment Setup**
   - Configure production Supabase project
   - Implement database migration strategy
   - Create backup and disaster recovery plan

3. **Launch Preparation**
   - Create marketing materials
   - Implement analytics tracking
   - Build user onboarding flows

## Resource Requirements

1. **Development Team**
   - 2 Flutter Developers
   - 1 Firebase/Supabase Integration Specialist
   - 1 UI/UX Designer
   - 1 QA Engineer
   - 1 DevOps Engineer (for Firebase Functions and Supabase Edge Functions)

2. **Infrastructure**
   - **Firebase**: Authentication, Cloud Messaging, Cloud Functions
   - **Supabase**: Database, Storage, Real-time, Edge Functions
   - **Plans**: Firebase Blaze Plan, Supabase Pro Plan
   - CI/CD pipeline (GitHub Actions)

3. **Third-party Services**
   - Payment gateway accounts (FPX, e-wallets)
   - Lalamove API access
   - SMS verification service (Firebase Auth handles this)

## Key Benefits of Firebase Auth + Supabase Backend

1. **Best of Both Worlds**
   - Firebase's robust, battle-tested authentication system
   - Supabase's powerful PostgreSQL database and real-time features
   - Firebase's excellent mobile SDK integration
   - Supabase's developer-friendly API and dashboard

2. **Enhanced Security**
   - Firebase's advanced security features (MFA, fraud detection)
   - Supabase RLS policies using Firebase JWT tokens
   - Centralized user management through Firebase Console
   - Custom claims for role-based access control

3. **Scalability & Performance**
   - Firebase's global CDN for authentication
   - Supabase's optimized PostgreSQL for complex queries
   - Real-time capabilities from both platforms
   - Efficient data synchronization

4. **Developer Experience**
   - Familiar Firebase Auth patterns for Flutter developers
   - Supabase's intuitive database management
   - Comprehensive documentation for both platforms
   - Strong community support

This hybrid implementation plan provides a structured approach to building GigaEats with Firebase Authentication and Supabase as the backend, combining the strengths of both platforms while aligning with the requirements in the PRD.
