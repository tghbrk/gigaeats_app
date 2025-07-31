# 🚗💰 GigaEats Driver Wallet System - Comprehensive Implementation Plan

## 🎯 Project Overview

This document provides a comprehensive implementation plan for the GigaEats Driver Wallet System, mirroring the existing customer wallet functionality while integrating seamlessly with the driver earnings and delivery workflow systems.

### **System Goals**
- **Automated Earnings Management**: Automatically deposit delivery earnings into driver wallets
- **Flexible Withdrawal Options**: Support bank transfers, e-wallet payouts, and cash-out requests
- **Real-time Balance Tracking**: Live balance updates and transaction notifications
- **Security & Compliance**: Robust RLS policies and audit logging for financial transactions
- **Seamless Integration**: Leverage existing wallet infrastructure and driver workflow systems

## 📋 Task 1: Database Schema Design & Migration

### **1.1 Existing Infrastructure Analysis**

The GigaEats platform already has a robust wallet infrastructure:
- `stakeholder_wallets` table supporting multiple user roles including 'driver'
- `wallet_transactions` table for comprehensive transaction history
- Existing RLS policies and security validation functions
- Edge Functions for secure wallet operations

### **1.2 Driver Wallet Schema Extensions**

#### **A. Stakeholder Wallets Table (Already Supports Drivers)**
```sql
-- Current stakeholder_wallets table already supports driver role
-- user_role TEXT includes 'driver' option
-- No schema changes needed for basic wallet functionality

-- Verify driver support in existing table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'stakeholder_wallets';
```

#### **B. Driver-Specific Wallet Transaction Types**
```sql
-- Extend wallet_transaction_type enum to include driver-specific types
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'delivery_earnings';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'completion_bonus';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'tip_payment';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'performance_bonus';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'fuel_allowance';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'withdrawal_request';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'bank_transfer';
ALTER TYPE wallet_transaction_type ADD VALUE IF NOT EXISTS 'ewallet_payout';
```

#### **C. Driver Wallet Settings Table**
```sql
CREATE TABLE IF NOT EXISTS driver_wallet_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Auto-payout preferences
    auto_payout_enabled BOOLEAN DEFAULT false,
    auto_payout_threshold DECIMAL(12,2) DEFAULT 100.00,
    auto_payout_schedule TEXT DEFAULT 'weekly', -- 'daily', 'weekly', 'monthly'
    
    -- Withdrawal preferences
    preferred_withdrawal_method TEXT DEFAULT 'bank_transfer', -- 'bank_transfer', 'ewallet', 'cash'
    minimum_withdrawal_amount DECIMAL(12,2) DEFAULT 10.00,
    maximum_daily_withdrawal DECIMAL(12,2) DEFAULT 1000.00,
    
    -- Bank account details
    bank_account_details JSONB DEFAULT '{}',
    ewallet_details JSONB DEFAULT '{}',
    
    -- Notification preferences
    earnings_notifications BOOLEAN DEFAULT true,
    withdrawal_notifications BOOLEAN DEFAULT true,
    low_balance_alerts BOOLEAN DEFAULT true,
    low_balance_threshold DECIMAL(12,2) DEFAULT 20.00,
    
    -- Security settings
    require_pin_for_withdrawals BOOLEAN DEFAULT false,
    require_biometric_auth BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(driver_id),
    UNIQUE(user_id)
);
```

#### **D. Driver Withdrawal Requests Table**
```sql
CREATE TABLE IF NOT EXISTS driver_withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    wallet_id UUID NOT NULL REFERENCES stakeholder_wallets(id) ON DELETE CASCADE,
    
    -- Request details
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    withdrawal_method TEXT NOT NULL, -- 'bank_transfer', 'ewallet', 'cash'
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed', 'cancelled'
    
    -- Processing details
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Payment details
    destination_details JSONB NOT NULL, -- Bank/e-wallet account info
    transaction_reference TEXT, -- External payment reference
    processing_fee DECIMAL(12,2) DEFAULT 0.00,
    net_amount DECIMAL(12,2) GENERATED ALWAYS AS (amount - processing_fee) STORED,
    
    -- Audit trail
    processed_by UUID REFERENCES auth.users(id),
    failure_reason TEXT,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### **1.3 RLS Policies for Driver Wallet Security**

#### **A. Driver Wallet Settings Policies**
```sql
-- Enable RLS
ALTER TABLE driver_wallet_settings ENABLE ROW LEVEL SECURITY;

-- Drivers can only access their own wallet settings
CREATE POLICY "Drivers can view own wallet settings" ON driver_wallet_settings
    FOR SELECT USING (
        user_id = auth.uid() OR 
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Drivers can update own wallet settings" ON driver_wallet_settings
    FOR UPDATE USING (
        user_id = auth.uid() OR 
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Drivers can insert own wallet settings" ON driver_wallet_settings
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR 
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );
```

#### **B. Driver Withdrawal Requests Policies**
```sql
-- Enable RLS
ALTER TABLE driver_withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Drivers can only access their own withdrawal requests
CREATE POLICY "Drivers can view own withdrawal requests" ON driver_withdrawal_requests
    FOR SELECT USING (
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Drivers can create withdrawal requests" ON driver_withdrawal_requests
    FOR INSERT WITH CHECK (
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

-- Only admins can update withdrawal request status
CREATE POLICY "Admins can update withdrawal requests" ON driver_withdrawal_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );
```

### **1.4 Database Functions for Driver Wallet Operations**

#### **A. Get or Create Driver Wallet Function**
```sql
CREATE OR REPLACE FUNCTION get_or_create_driver_wallet(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_wallet_id UUID;
    v_driver_id UUID;
BEGIN
    -- Get driver ID for the user
    SELECT id INTO v_driver_id 
    FROM drivers 
    WHERE user_id = p_user_id;
    
    IF v_driver_id IS NULL THEN
        RAISE EXCEPTION 'No driver profile found for user %', p_user_id;
    END IF;
    
    -- Check if wallet already exists
    SELECT id INTO v_wallet_id
    FROM stakeholder_wallets
    WHERE user_id = p_user_id AND user_role = 'driver';
    
    -- Create wallet if it doesn't exist
    IF v_wallet_id IS NULL THEN
        INSERT INTO stakeholder_wallets (
            user_id,
            user_role,
            available_balance,
            pending_balance,
            total_earned,
            total_withdrawn,
            currency,
            is_active,
            is_verified
        ) VALUES (
            p_user_id,
            'driver',
            0.00,
            0.00,
            0.00,
            0.00,
            'MYR',
            true,
            true
        ) RETURNING id INTO v_wallet_id;
        
        -- Create default wallet settings
        INSERT INTO driver_wallet_settings (
            driver_id,
            user_id
        ) VALUES (
            v_driver_id,
            p_user_id
        );
    END IF;
    
    RETURN v_wallet_id;
END;
$$;
```

### **1.5 Indexes for Performance Optimization**

```sql
-- Driver wallet settings indexes
CREATE INDEX IF NOT EXISTS idx_driver_wallet_settings_driver_id 
ON driver_wallet_settings(driver_id);

CREATE INDEX IF NOT EXISTS idx_driver_wallet_settings_user_id 
ON driver_wallet_settings(user_id);

-- Driver withdrawal requests indexes
CREATE INDEX IF NOT EXISTS idx_driver_withdrawal_requests_driver_id 
ON driver_withdrawal_requests(driver_id);

CREATE INDEX IF NOT EXISTS idx_driver_withdrawal_requests_status 
ON driver_withdrawal_requests(status);

CREATE INDEX IF NOT EXISTS idx_driver_withdrawal_requests_requested_at 
ON driver_withdrawal_requests(requested_at DESC);

-- Stakeholder wallets driver-specific indexes
CREATE INDEX IF NOT EXISTS idx_stakeholder_wallets_driver_role 
ON stakeholder_wallets(user_id, user_role) 
WHERE user_role = 'driver';
```

## 🔄 Next Steps

This database schema provides the foundation for the driver wallet system. The next tasks will build upon this infrastructure:

1. **Driver Wallet Model & Data Layer** - Create Flutter models and repositories
2. **Earnings Integration** - Connect with existing driver earnings system
3. **Edge Functions** - Secure wallet operations and transaction processing
4. **State Management** - Riverpod providers for real-time updates
5. **UI Integration** - Driver dashboard and wallet management screens

## 📊 Schema Summary

| Component | Purpose | Integration Points |
|-----------|---------|-------------------|
| `stakeholder_wallets` | Core wallet storage | Existing table, supports driver role |
| `driver_wallet_settings` | Driver preferences | Links to drivers table |
| `driver_withdrawal_requests` | Payout management | Links to wallets and drivers |
| RLS Policies | Security enforcement | Auth system integration |
| Database Functions | Automated operations | Wallet creation and management |

This schema design ensures seamless integration with existing systems while providing comprehensive driver wallet functionality.

## 📱 Task 2: Driver Wallet Model & Data Layer

### **2.1 Driver Wallet Model**

Following the existing `CustomerWallet` pattern, create a dedicated `DriverWallet` model:

```dart
// lib/src/features/drivers/data/models/driver_wallet.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_wallet.g.dart';

@JsonSerializable()
class DriverWallet extends Equatable {
  final String id;
  final String userId;
  final String driverId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final String currency;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const DriverWallet({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.currency,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory DriverWallet.fromJson(Map<String, dynamic> json) =>
      _$DriverWalletFromJson(json);

  Map<String, dynamic> toJson() => _$DriverWalletToJson(this);

  /// Create from StakeholderWallet
  factory DriverWallet.fromStakeholderWallet(
    Map<String, dynamic> stakeholderWallet,
    String driverId,
  ) {
    return DriverWallet(
      id: stakeholderWallet['id'],
      userId: stakeholderWallet['user_id'],
      driverId: driverId,
      availableBalance: (stakeholderWallet['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (stakeholderWallet['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (stakeholderWallet['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (stakeholderWallet['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: stakeholderWallet['currency'] ?? 'MYR',
      isActive: stakeholderWallet['is_active'] ?? true,
      isVerified: stakeholderWallet['is_verified'] ?? false,
      createdAt: DateTime.parse(stakeholderWallet['created_at']),
      updatedAt: DateTime.parse(stakeholderWallet['updated_at']),
      lastActivityAt: stakeholderWallet['last_activity_at'] != null
          ? DateTime.parse(stakeholderWallet['last_activity_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        driverId,
        availableBalance,
        pendingBalance,
        totalEarned,
        totalWithdrawn,
        currency,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
        lastActivityAt,
      ];

  /// Formatted balance displays
  String get formattedAvailableBalance => 'RM ${availableBalance.toStringAsFixed(2)}';
  String get formattedPendingBalance => 'RM ${pendingBalance.toStringAsFixed(2)}';
  String get formattedTotalEarned => 'RM ${totalEarned.toStringAsFixed(2)}';
  String get formattedTotalWithdrawn => 'RM ${totalWithdrawn.toStringAsFixed(2)}';

  /// Total balance (available + pending)
  double get totalBalance => availableBalance + pendingBalance;
  String get formattedTotalBalance => 'RM ${totalBalance.toStringAsFixed(2)}';

  /// Check if wallet has sufficient balance for withdrawal
  bool hasSufficientBalance(double amount) => availableBalance >= amount;

  /// Check if withdrawal amount meets minimum threshold
  bool meetsMinimumWithdrawal(double amount, double minimumAmount) => amount >= minimumAmount;
}
```

### **2.2 Driver Wallet Settings Model**

```dart
// lib/src/features/drivers/data/models/driver_wallet_settings.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_wallet_settings.g.dart';

@JsonSerializable()
class DriverWalletSettings extends Equatable {
  final String id;
  final String driverId;
  final String userId;

  // Auto-payout preferences
  final bool autoPayoutEnabled;
  final double autoPayoutThreshold;
  final String autoPayoutSchedule;

  // Withdrawal preferences
  final String preferredWithdrawalMethod;
  final double minimumWithdrawalAmount;
  final double maximumDailyWithdrawal;

  // Account details
  final Map<String, dynamic> bankAccountDetails;
  final Map<String, dynamic> ewalletDetails;

  // Notification preferences
  final bool earningsNotifications;
  final bool withdrawalNotifications;
  final bool lowBalanceAlerts;
  final double lowBalanceThreshold;

  // Security settings
  final bool requirePinForWithdrawals;
  final bool requireBiometricAuth;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverWalletSettings({
    required this.id,
    required this.driverId,
    required this.userId,
    this.autoPayoutEnabled = false,
    this.autoPayoutThreshold = 100.00,
    this.autoPayoutSchedule = 'weekly',
    this.preferredWithdrawalMethod = 'bank_transfer',
    this.minimumWithdrawalAmount = 10.00,
    this.maximumDailyWithdrawal = 1000.00,
    this.bankAccountDetails = const {},
    this.ewalletDetails = const {},
    this.earningsNotifications = true,
    this.withdrawalNotifications = true,
    this.lowBalanceAlerts = true,
    this.lowBalanceThreshold = 20.00,
    this.requirePinForWithdrawals = false,
    this.requireBiometricAuth = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverWalletSettings.fromJson(Map<String, dynamic> json) =>
      _$DriverWalletSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DriverWalletSettingsToJson(this);

  @override
  List<Object?> get props => [
        id,
        driverId,
        userId,
        autoPayoutEnabled,
        autoPayoutThreshold,
        autoPayoutSchedule,
        preferredWithdrawalMethod,
        minimumWithdrawalAmount,
        maximumDailyWithdrawal,
        bankAccountDetails,
        ewalletDetails,
        earningsNotifications,
        withdrawalNotifications,
        lowBalanceAlerts,
        lowBalanceThreshold,
        requirePinForWithdrawals,
        requireBiometricAuth,
        createdAt,
        updatedAt,
      ];
}
```

### **2.3 Driver Wallet Repository**

```dart
// lib/src/features/drivers/data/repositories/driver_wallet_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/driver_wallet.dart';
import '../models/driver_wallet_settings.dart';

class DriverWalletRepository extends BaseRepository {
  /// Get driver wallet for current user
  Future<Result<DriverWallet?>> getDriverWallet() async {
    return executeQuery(() async {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting wallet for user: ${user.id}');

      // First get driver ID
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (driverResponse == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] No driver profile found');
        return null;
      }

      final driverId = driverResponse['id'] as String;

      // Get wallet data
      final response = await supabase
          .from('stakeholder_wallets')
          .select('''
            id,
            user_id,
            available_balance,
            pending_balance,
            total_earned,
            total_withdrawn,
            currency,
            is_active,
            is_verified,
            created_at,
            updated_at,
            last_activity_at
          ''')
          .eq('user_id', user.id)
          .eq('user_role', 'driver')
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [DRIVER-WALLET-REPO] No wallet found, will need to create one');
        return null;
      }

      final wallet = DriverWallet.fromStakeholderWallet(response, driverId);
      debugPrint('✅ [DRIVER-WALLET-REPO] Wallet retrieved: ${wallet.formattedAvailableBalance}');

      return wallet;
    });
  }

  /// Stream driver wallet updates
  Stream<DriverWallet?> streamDriverWallet() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return supabase
        .from('stakeholder_wallets')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter for current user and driver role
          for (final item in data) {
            if (item['user_id'] == user.id && item['user_role'] == 'driver') {
              // Need to get driver ID - this is a limitation of stream approach
              // Consider caching driver ID or using a different approach
              return DriverWallet.fromStakeholderWallet(item, 'driver-id-placeholder');
            }
          }
          return null;
        });
  }

  /// Get driver wallet settings
  Future<Result<DriverWalletSettings?>> getDriverWalletSettings() async {
    return executeQuery(() async {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('driver_wallet_settings')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DriverWalletSettings.fromJson(response);
    });
  }

  /// Update driver wallet settings
  Future<Result<DriverWalletSettings>> updateDriverWalletSettings(
    DriverWalletSettings settings,
  ) async {
    return executeQuery(() async {
      final response = await supabase
          .from('driver_wallet_settings')
          .update(settings.toJson())
          .eq('id', settings.id)
          .select()
          .single();

      return DriverWalletSettings.fromJson(response);
    });
  }
}
```

## 💰 Task 3: Earnings Integration & Auto-Deposit System

### **3.1 Enhanced Driver Earnings Service Integration**

Extend the existing `DriverEarningsService` to integrate with wallet deposits:

```dart
// lib/src/features/drivers/data/services/enhanced_driver_wallet_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/driver_wallet.dart';
import '../repositories/driver_wallet_repository.dart';

class EnhancedDriverWalletService extends BaseRepository {
  final DriverWalletRepository _repository;

  EnhancedDriverWalletService(this._repository);

  /// Get or create driver wallet
  Future<Result<DriverWallet>> getOrCreateDriverWallet() async {
    return executeQuery(() async {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting or creating wallet for user: ${user.id}');

      // Check if wallet already exists
      final existingWalletResult = await _repository.getDriverWallet();
      return existingWalletResult.fold(
        (failure) => throw Exception('Failed to check existing wallet: ${failure.message}'),
        (existingWallet) async {
          if (existingWallet != null) {
            debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet already exists');
            return existingWallet;
          }

          // Create new wallet using database function
          final response = await supabase.rpc('get_or_create_driver_wallet', params: {
            'p_user_id': user.id,
          });

          if (response == null) {
            throw Exception('Failed to create driver wallet');
          }

          // Fetch the created wallet
          final newWalletResult = await _repository.getDriverWallet();
          return newWalletResult.fold(
            (failure) => throw Exception('Failed to fetch created wallet: ${failure.message}'),
            (newWallet) {
              if (newWallet == null) {
                throw Exception('Wallet creation failed');
              }
              debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Driver wallet created: ${newWallet.id}');
              return newWallet;
            },
          );
        },
      );
    });
  }

  /// Process earnings deposit from completed delivery
  Future<Result<void>> processEarningsDeposit({
    required String orderId,
    required double grossEarnings,
    required double netEarnings,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Processing earnings deposit for order: $orderId');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Net earnings: RM ${netEarnings.toStringAsFixed(2)}');

      // Ensure wallet exists
      final wallet = await getOrCreateDriverWallet();
      final walletData = wallet.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) => wallet,
      );

      // Call Edge Function to process earnings deposit
      final response = await supabase.functions.invoke(
        'driver-wallet-operations',
        body: {
          'action': 'process_earnings_deposit',
          'wallet_id': walletData.id,
          'order_id': orderId,
          'amount': netEarnings,
          'earnings_breakdown': earningsBreakdown,
          'metadata': {
            'gross_earnings': grossEarnings,
            'net_earnings': netEarnings,
            'deposit_source': 'delivery_completion',
            'processed_at': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.data == null || response.data['success'] != true) {
        throw Exception('Failed to process earnings deposit: ${response.data?['error'] ?? 'Unknown error'}');
      }

      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Earnings deposited successfully');
    });
  }

  /// Process withdrawal request
  Future<Result<String>> processWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Processing withdrawal request: RM ${amount.toStringAsFixed(2)}');

      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get driver ID
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final driverId = driverResponse['id'] as String;

      // Get wallet
      final walletResult = await _repository.getDriverWallet();
      final wallet = walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) => wallet ?? (throw Exception('Wallet not found')),
      );

      // Validate withdrawal amount
      if (!wallet.hasSufficientBalance(amount)) {
        throw Exception('Insufficient balance for withdrawal');
      }

      // Create withdrawal request
      final response = await supabase
          .from('driver_withdrawal_requests')
          .insert({
            'driver_id': driverId,
            'wallet_id': wallet.id,
            'amount': amount,
            'withdrawal_method': withdrawalMethod,
            'destination_details': destinationDetails,
            'status': 'pending',
          })
          .select('id')
          .single();

      final requestId = response['id'] as String;
      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Withdrawal request created: $requestId');

      return requestId;
    });
  }
}
```

### **3.2 Integration with Existing Driver Workflow**

Update the existing driver workflow to automatically trigger wallet deposits:

```dart
// Update in lib/src/features/drivers/data/services/enhanced_workflow_integration_service.dart
// Add this method to the existing service:

/// Process wallet deposit after delivery completion
Future<void> _processWalletDeposit(String orderId, String driverId, Map<String, dynamic> earningsData) async {
  try {
    debugPrint('🔍 [WORKFLOW-INTEGRATION] Processing wallet deposit for order: $orderId');

    final walletService = EnhancedDriverWalletService(DriverWalletRepository());

    await walletService.processEarningsDeposit(
      orderId: orderId,
      grossEarnings: earningsData['gross_earnings']?.toDouble() ?? 0.0,
      netEarnings: earningsData['net_earnings']?.toDouble() ?? 0.0,
      earningsBreakdown: earningsData,
    );

    debugPrint('✅ [WORKFLOW-INTEGRATION] Wallet deposit completed for order: $orderId');
  } catch (e) {
    debugPrint('❌ [WORKFLOW-INTEGRATION] Wallet deposit failed: $e');
    // Don't throw - earnings are still recorded in driver_earnings table
    // Wallet deposit can be retried later
  }
}

// Update the existing _storeEarningsRecord method to include wallet deposit:
Future<void> _storeEarningsRecord(String orderId, String driverId, Map<String, dynamic> earningsData) async {
  // Existing earnings storage code...
  await _supabase.from('driver_earnings').insert({
    'order_id': orderId,
    'driver_id': driverId,
    'gross_earnings': earningsData['gross_earnings'],
    'net_earnings': earningsData['net_earnings'],
    'base_commission': earningsData['base_commission'],
    'completion_bonus': earningsData['completion_bonus'],
    'peak_hour_bonus': earningsData['peak_hour_bonus'],
    'rating_bonus': earningsData['rating_bonus'],
    'other_bonuses': earningsData['other_bonuses'],
    'deductions': earningsData['deductions'],
    'earnings_type': 'delivery_completion',
    'created_at': DateTime.now().toIso8601String(),
  });

  // NEW: Process wallet deposit
  await _processWalletDeposit(orderId, driverId, earningsData);
}
```

## 🔧 Task 4: Supabase Edge Functions for Driver Wallet Operations

### **4.1 Driver Wallet Operations Edge Function**

Create a comprehensive Edge Function for secure driver wallet operations:

```typescript
// supabase/functions/driver-wallet-operations/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DriverWalletRequest {
  action: 'get_balance' | 'process_earnings_deposit' | 'process_withdrawal' | 'get_transaction_history'
  wallet_id?: string
  order_id?: string
  amount?: number
  earnings_breakdown?: Record<string, any>
  withdrawal_method?: string
  destination_details?: Record<string, any>
  metadata?: Record<string, any>
}

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`🚀 [DRIVER-WALLET-OPS-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      throw new Error('Unauthorized: Invalid or missing authentication token')
    }

    const requestBody: DriverWalletRequest = await req.json()
    console.log('🔍 [DRIVER-WALLET-OPS] Request body:', JSON.stringify(requestBody, null, 2))

    const { action } = requestBody
    let response: any

    switch (action) {
      case 'get_balance':
        response = await getDriverWalletBalance(supabaseClient, user.id)
        break
      case 'process_earnings_deposit':
        response = await processEarningsDeposit(supabaseClient, user.id, requestBody)
        break
      case 'process_withdrawal':
        response = await processWithdrawal(supabaseClient, user.id, requestBody)
        break
      case 'get_transaction_history':
        response = await getTransactionHistory(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(
      JSON.stringify({ success: true, data: response }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('❌ [DRIVER-WALLET-OPS] Error:', error.message)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})

async function getDriverWalletBalance(supabase: any, userId: string) {
  console.log('🔍 Getting driver wallet balance for user:', userId)

  const { data: wallet, error } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance, pending_balance, total_earned, total_withdrawn')
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (error) {
    throw new Error(`Failed to get wallet: ${error.message}`)
  }

  return wallet
}

async function processEarningsDeposit(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, order_id, amount, earnings_breakdown, metadata } = request

  console.log('🔍 Processing earnings deposit:', { wallet_id, order_id, amount })

  // Validate wallet ownership
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  const newBalance = wallet.available_balance + amount

  // Update wallet balance
  const { error: updateError } = await supabase
    .from('stakeholder_wallets')
    .update({
      available_balance: newBalance,
      total_earned: supabase.sql`total_earned + ${amount}`,
      last_activity_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('id', wallet_id)

  if (updateError) {
    throw new Error(`Failed to update wallet: ${updateError.message}`)
  }

  // Create transaction record
  const { error: transactionError } = await supabase
    .from('wallet_transactions')
    .insert({
      wallet_id: wallet_id,
      transaction_type: 'delivery_earnings',
      amount: amount,
      currency: 'MYR',
      balance_before: wallet.available_balance,
      balance_after: newBalance,
      reference_type: 'order',
      reference_id: order_id,
      description: `Delivery earnings for order ${order_id}`,
      metadata: {
        ...metadata,
        earnings_breakdown,
        processed_by: 'driver_wallet_operations',
        processed_at: new Date().toISOString()
      },
      processing_fee: 0,
      created_at: new Date().toISOString()
    })

  if (transactionError) {
    throw new Error(`Failed to create transaction: ${transactionError.message}`)
  }

  console.log('✅ Earnings deposit processed successfully')
  return { wallet_id, new_balance: newBalance, transaction_amount: amount }
}

async function processWithdrawal(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, amount, withdrawal_method, destination_details, metadata } = request

  console.log('🔍 Processing withdrawal:', { wallet_id, amount, withdrawal_method })

  // Validate wallet ownership and balance
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  if (wallet.available_balance < amount) {
    throw new Error('Insufficient balance for withdrawal')
  }

  // Get driver ID
  const { data: driver, error: driverError } = await supabase
    .from('drivers')
    .select('id')
    .eq('user_id', userId)
    .single()

  if (driverError || !driver) {
    throw new Error('Driver profile not found')
  }

  // Create withdrawal request
  const { data: withdrawalRequest, error: requestError } = await supabase
    .from('driver_withdrawal_requests')
    .insert({
      driver_id: driver.id,
      wallet_id: wallet_id,
      amount: amount,
      withdrawal_method: withdrawal_method,
      destination_details: destination_details,
      status: 'pending',
      metadata: metadata
    })
    .select('id')
    .single()

  if (requestError) {
    throw new Error(`Failed to create withdrawal request: ${requestError.message}`)
  }

  console.log('✅ Withdrawal request created successfully')
  return { request_id: withdrawalRequest.id, status: 'pending' }
}

async function getTransactionHistory(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id } = request

  console.log('🔍 Getting transaction history for wallet:', wallet_id)

  // Validate wallet ownership
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  // Get transaction history
  const { data: transactions, error: transactionError } = await supabase
    .from('wallet_transactions')
    .select('*')
    .eq('wallet_id', wallet_id)
    .order('created_at', { ascending: false })
    .limit(50)

  if (transactionError) {
    throw new Error(`Failed to get transactions: ${transactionError.message}`)
  }

  console.log('✅ Transaction history retrieved successfully')
  return transactions
}
```

## 🎯 Task 5: Flutter State Management & Providers

### **5.1 Driver Wallet Provider**

Create Riverpod providers for driver wallet state management:

```dart
// lib/src/features/drivers/presentation/providers/driver_wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/models/driver_wallet.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import '../../data/services/enhanced_driver_wallet_service.dart';

// Repository provider
final driverWalletRepositoryProvider = Provider<DriverWalletRepository>((ref) {
  return DriverWalletRepository();
});

// Service provider
final enhancedDriverWalletServiceProvider = Provider<EnhancedDriverWalletService>((ref) {
  final repository = ref.watch(driverWalletRepositoryProvider);
  return EnhancedDriverWalletService(repository);
});

// Driver wallet provider
final driverWalletProvider = FutureProvider<DriverWallet?>((ref) async {
  final service = ref.watch(enhancedDriverWalletServiceProvider);
  final result = await service.getOrCreateDriverWallet();

  return result.fold(
    (failure) {
      throw Exception('Failed to get driver wallet: ${failure.message}');
    },
    (wallet) => wallet,
  );
});

// Real-time driver wallet stream provider
final driverWalletStreamProvider = StreamProvider<DriverWallet?>((ref) {
  final repository = ref.watch(driverWalletRepositoryProvider);
  return repository.streamDriverWallet();
});

// Driver wallet balance provider (for quick access)
final driverWalletBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final walletAsync = ref.watch(driverWalletProvider);

  return walletAsync.when(
    data: (wallet) => AsyncValue.data(wallet?.availableBalance ?? 0.0),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Driver wallet settings provider
final driverWalletSettingsProvider = FutureProvider<DriverWalletSettings?>((ref) async {
  final repository = ref.watch(driverWalletRepositoryProvider);
  final result = await repository.getDriverWalletSettings();

  return result.fold(
    (failure) {
      throw Exception('Failed to get wallet settings: ${failure.message}');
    },
    (settings) => settings,
  );
});
```

### **5.2 Driver Wallet Transaction Provider**

```dart
// lib/src/features/drivers/presentation/providers/driver_wallet_transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../marketplace_wallet/data/models/wallet_transaction.dart';
import 'driver_wallet_provider.dart';

// Transaction history provider
final driverWalletTransactionHistoryProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final wallet = await ref.watch(driverWalletProvider.future);

  if (wallet == null) {
    return [];
  }

  // Call Edge Function to get transaction history
  final supabase = Supabase.instance.client;
  final response = await supabase.functions.invoke(
    'driver-wallet-operations',
    body: {
      'action': 'get_transaction_history',
      'wallet_id': wallet.id,
    },
  );

  if (response.data == null || response.data['success'] != true) {
    throw Exception('Failed to get transaction history');
  }

  final transactionsData = response.data['data'] as List<dynamic>;
  return transactionsData
      .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
      .toList();
});

// Earnings deposit provider
final processEarningsDepositProvider = Provider<Future<void> Function({
  required String orderId,
  required double grossEarnings,
  required double netEarnings,
  required Map<String, dynamic> earningsBreakdown,
})>((ref) {
  return ({
    required String orderId,
    required double grossEarnings,
    required double netEarnings,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    final service = ref.read(enhancedDriverWalletServiceProvider);
    final result = await service.processEarningsDeposit(
      orderId: orderId,
      grossEarnings: grossEarnings,
      netEarnings: netEarnings,
      earningsBreakdown: earningsBreakdown,
    );

    result.fold(
      (failure) => throw Exception('Failed to process earnings deposit: ${failure.message}'),
      (_) {
        // Refresh wallet data
        ref.invalidate(driverWalletProvider);
        ref.invalidate(driverWalletTransactionHistoryProvider);
      },
    );
  };
});

// Withdrawal request provider
final processWithdrawalRequestProvider = Provider<Future<String> Function({
  required double amount,
  required String withdrawalMethod,
  required Map<String, dynamic> destinationDetails,
})>((ref) {
  return ({
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
  }) async {
    final service = ref.read(enhancedDriverWalletServiceProvider);
    final result = await service.processWithdrawalRequest(
      amount: amount,
      withdrawalMethod: withdrawalMethod,
      destinationDetails: destinationDetails,
    );

    return result.fold(
      (failure) => throw Exception('Failed to process withdrawal: ${failure.message}'),
      (requestId) {
        // Refresh wallet data
        ref.invalidate(driverWalletProvider);
        ref.invalidate(driverWalletTransactionHistoryProvider);
        return requestId;
      },
    );
  };
});
```

## 📱 Task 6: Driver Dashboard Wallet Integration

### **6.1 Driver Wallet Balance Widget**

Create a wallet balance widget for the driver dashboard:

```dart
// lib/src/features/drivers/presentation/widgets/driver_wallet_balance_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/driver_wallet_provider.dart';

class DriverWalletBalanceWidget extends ConsumerWidget {
  const DriverWalletBalanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(driverWalletProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Balance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/driver/wallet'),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  tooltip: 'View Wallet Details',
                ),
              ],
            ),
            const SizedBox(height: 8),
            walletAsync.when(
              data: (wallet) {
                if (wallet == null) {
                  return const Text('Wallet not found');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.formattedAvailableBalance,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (wallet.pendingBalance > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pending: ${wallet.formattedPendingBalance}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/driver/wallet/withdraw'),
                            icon: const Icon(Icons.account_balance_wallet, size: 16),
                            label: const Text('Withdraw'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/driver/wallet/history'),
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text('History'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading wallet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(driverWalletProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 💸 Task 7: Withdrawal & Payout Management System

### **7.1 Withdrawal Request Screen**

```dart
// lib/src/features/drivers/presentation/screens/driver_wallet_withdrawal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/driver_wallet_provider.dart';
import '../providers/driver_wallet_transaction_provider.dart';

class DriverWalletWithdrawalScreen extends ConsumerStatefulWidget {
  const DriverWalletWithdrawalScreen({super.key});

  @override
  ConsumerState<DriverWalletWithdrawalScreen> createState() => _DriverWalletWithdrawalScreenState();
}

class _DriverWalletWithdrawalScreenState extends ConsumerState<DriverWalletWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedMethod = 'bank_transfer';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(driverWalletProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const Center(child: Text('Wallet not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            wallet.formattedAvailableBalance,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Withdrawal Amount
                  Text(
                    'Withdrawal Amount',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (RM)',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }

                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }

                      if (amount < 10.00) {
                        return 'Minimum withdrawal amount is RM 10.00';
                      }

                      if (amount > wallet.availableBalance) {
                        return 'Insufficient balance';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Withdrawal Method
                  Text(
                    'Withdrawal Method',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'ewallet',
                        child: Text('E-Wallet'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _processWithdrawal,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Request Withdrawal'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Card(
                    color: theme.colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Withdrawal Information',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Minimum withdrawal: RM 10.00\n'
                            '• Processing time: 1-3 business days\n'
                            '• No processing fees for bank transfers\n'
                            '• Withdrawals are processed during business hours',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(driverWalletProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final processWithdrawal = ref.read(processWithdrawalRequestProvider);

      final requestId = await processWithdrawal(
        amount: amount,
        withdrawalMethod: _selectedMethod,
        destinationDetails: {
          'method': _selectedMethod,
          'amount': amount,
          'currency': 'MYR',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request submitted successfully (ID: ${requestId.substring(0, 8)})'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process withdrawal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
```

## 📊 Task 8: Transaction History & Filtering UI

### **8.1 Transaction History Screen**

```dart
// lib/src/features/drivers/presentation/screens/driver_wallet_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../marketplace_wallet/data/models/wallet_transaction.dart';
import '../providers/driver_wallet_transaction_provider.dart';

class DriverWalletHistoryScreen extends ConsumerStatefulWidget {
  const DriverWalletHistoryScreen({super.key});

  @override
  ConsumerState<DriverWalletHistoryScreen> createState() => _DriverWalletHistoryScreenState();
}

class _DriverWalletHistoryScreenState extends ConsumerState<DriverWalletHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(driverWalletTransactionHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Transactions'),
              ),
              const PopupMenuItem(
                value: 'delivery_earnings',
                child: Text('Delivery Earnings'),
              ),
              const PopupMenuItem(
                value: 'completion_bonus',
                child: Text('Bonuses'),
              ),
              const PopupMenuItem(
                value: 'withdrawal_request',
                child: Text('Withdrawals'),
              ),
            ],
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filteredTransactions = _selectedFilter == 'all'
              ? transactions
              : transactions.where((t) => t.transactionType.value == _selectedFilter).toList();

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your transaction history will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(driverWalletTransactionHistoryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return _TransactionTile(transaction: transaction);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading transactions: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(driverWalletTransactionHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.transactionType == WalletTransactionType.deliveryEarnings ||
                     transaction.transactionType == WalletTransactionType.completionBonus ||
                     transaction.transactionType == WalletTransactionType.tipPayment;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          child: Icon(
            _getTransactionIcon(transaction.transactionType),
            color: isCredit
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onErrorContainer,
          ),
        ),
        title: Text(
          _getTransactionTitle(transaction.transactionType),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null) ...[
              Text(
                transaction.description!,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
            ],
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}RM ${transaction.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCredit
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
            Text(
              'Balance: RM ${transaction.balanceAfter.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.deliveryEarnings:
        return Icons.delivery_dining;
      case WalletTransactionType.completionBonus:
        return Icons.star;
      case WalletTransactionType.tipPayment:
        return Icons.thumb_up;
      case WalletTransactionType.withdrawalRequest:
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }

  String _getTransactionTitle(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.deliveryEarnings:
        return 'Delivery Earnings';
      case WalletTransactionType.completionBonus:
        return 'Completion Bonus';
      case WalletTransactionType.tipPayment:
        return 'Customer Tip';
      case WalletTransactionType.withdrawalRequest:
        return 'Withdrawal';
      default:
        return 'Transaction';
    }
  }
}
```

## 🔒 Task 9: Security Implementation & RLS Policies

### **9.1 Enhanced Security Validation**

The driver wallet system leverages existing security infrastructure while adding driver-specific validations:

```sql
-- Driver wallet ownership validation function
CREATE OR REPLACE FUNCTION validate_driver_wallet_ownership(
    p_wallet_id UUID,
    p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user owns the wallet and it's a driver wallet
    RETURN EXISTS (
        SELECT 1
        FROM stakeholder_wallets sw
        JOIN drivers d ON d.user_id = sw.user_id
        WHERE sw.id = p_wallet_id
        AND sw.user_id = p_user_id
        AND sw.user_role = 'driver'
        AND d.user_id = p_user_id
    );
END;
$$;

-- Driver withdrawal limits validation
CREATE OR REPLACE FUNCTION validate_driver_withdrawal_limits(
    p_driver_id UUID,
    p_amount DECIMAL(12,2)
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_daily_limit DECIMAL(12,2);
    v_today_total DECIMAL(12,2);
    v_min_amount DECIMAL(12,2);
    v_result JSONB;
BEGIN
    -- Get driver wallet settings
    SELECT
        maximum_daily_withdrawal,
        minimum_withdrawal_amount
    INTO v_daily_limit, v_min_amount
    FROM driver_wallet_settings
    WHERE driver_id = p_driver_id;

    -- Default limits if no settings found
    v_daily_limit := COALESCE(v_daily_limit, 1000.00);
    v_min_amount := COALESCE(v_min_amount, 10.00);

    -- Calculate today's withdrawal total
    SELECT COALESCE(SUM(amount), 0)
    INTO v_today_total
    FROM driver_withdrawal_requests
    WHERE driver_id = p_driver_id
    AND DATE(requested_at) = CURRENT_DATE
    AND status IN ('pending', 'processing', 'completed');

    -- Build validation result
    v_result := jsonb_build_object(
        'is_valid', (
            p_amount >= v_min_amount AND
            (v_today_total + p_amount) <= v_daily_limit
        ),
        'minimum_amount', v_min_amount,
        'daily_limit', v_daily_limit,
        'today_total', v_today_total,
        'remaining_limit', (v_daily_limit - v_today_total)
    );

    RETURN v_result;
END;
$$;
```

### **9.2 Audit Logging Integration**

```sql
-- Driver wallet audit trigger
CREATE OR REPLACE FUNCTION log_driver_wallet_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log wallet balance changes
    IF TG_OP = 'UPDATE' AND (
        OLD.available_balance != NEW.available_balance OR
        OLD.pending_balance != NEW.pending_balance
    ) THEN
        INSERT INTO financial_audit_log (
            entity_type,
            entity_id,
            action_type,
            user_id,
            old_values,
            new_values,
            metadata
        ) VALUES (
            'driver_wallet',
            NEW.id,
            'balance_update',
            NEW.user_id,
            jsonb_build_object(
                'available_balance', OLD.available_balance,
                'pending_balance', OLD.pending_balance
            ),
            jsonb_build_object(
                'available_balance', NEW.available_balance,
                'pending_balance', NEW.pending_balance
            ),
            jsonb_build_object(
                'user_role', NEW.user_role,
                'trigger_source', 'driver_wallet_audit'
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

-- Create audit trigger
CREATE TRIGGER driver_wallet_audit_trigger
    AFTER UPDATE ON stakeholder_wallets
    FOR EACH ROW
    WHEN (NEW.user_role = 'driver')
    EXECUTE FUNCTION log_driver_wallet_activity();
```

## 🔔 Task 10: Real-time Balance Updates & Notifications

### **10.1 Real-time Balance Notification Service**

```dart
// lib/src/features/drivers/data/services/driver_wallet_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/services/notification_service.dart';
import '../models/driver_wallet.dart';

class DriverWalletNotificationService {
  final NotificationService _notificationService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  DriverWalletNotificationService(
    this._notificationService,
    this._localNotifications,
  );

  /// Show earnings deposit notification
  Future<void> showEarningsDepositNotification({
    required double amount,
    required String orderId,
  }) async {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] Showing earnings deposit notification');

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Earnings Deposited! 💰',
      'RM ${amount.toStringAsFixed(2)} from order ${orderId.substring(0, 8)} has been added to your wallet',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'driver_wallet_earnings',
          'Driver Wallet Earnings',
          channelDescription: 'Notifications for driver wallet earnings deposits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_wallet',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'driver_wallet_earnings',
        ),
      ),
    );
  }

  /// Show low balance alert
  Future<void> showLowBalanceAlert({
    required double currentBalance,
    required double threshold,
  }) async {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] Showing low balance alert');

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Low Wallet Balance ⚠️',
      'Your wallet balance (RM ${currentBalance.toStringAsFixed(2)}) is below your alert threshold',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'driver_wallet_alerts',
          'Driver Wallet Alerts',
          channelDescription: 'Important alerts for driver wallet',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_warning',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'driver_wallet_alerts',
        ),
      ),
    );
  }

  /// Show withdrawal status notification
  Future<void> showWithdrawalStatusNotification({
    required String status,
    required double amount,
    required String requestId,
  }) async {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] Showing withdrawal status notification');

    String title;
    String body;

    switch (status) {
      case 'completed':
        title = 'Withdrawal Completed ✅';
        body = 'RM ${amount.toStringAsFixed(2)} has been transferred to your account';
        break;
      case 'failed':
        title = 'Withdrawal Failed ❌';
        body = 'Your withdrawal request for RM ${amount.toStringAsFixed(2)} could not be processed';
        break;
      case 'processing':
        title = 'Withdrawal Processing 🔄';
        body = 'Your withdrawal request for RM ${amount.toStringAsFixed(2)} is being processed';
        break;
      default:
        return;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'driver_wallet_withdrawals',
          'Driver Wallet Withdrawals',
          channelDescription: 'Notifications for driver wallet withdrawal status',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_bank',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'driver_wallet_withdrawals',
        ),
      ),
    );
  }
}
```

## 🧪 Task 11: Integration Testing & Validation

### **11.1 Driver Wallet Integration Tests**

```dart
// test/integration/driver_wallet_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/src/features/drivers/data/models/driver_wallet.dart';
import '../../lib/src/features/drivers/data/repositories/driver_wallet_repository.dart';
import '../../lib/src/features/drivers/data/services/enhanced_driver_wallet_service.dart';

void main() {
  group('Driver Wallet Integration Tests', () {
    late SupabaseClient supabase;
    late DriverWalletRepository repository;
    late EnhancedDriverWalletService service;

    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL',
        anonKey: 'YOUR_SUPABASE_ANON_KEY',
      );

      supabase = Supabase.instance.client;
      repository = DriverWalletRepository();
      service = EnhancedDriverWalletService(repository);
    });

    group('Wallet Creation and Retrieval', () {
      testWidgets('should create driver wallet for authenticated driver', (tester) async {
        // Test wallet creation
        final result = await service.getOrCreateDriverWallet();

        expect(result.isSuccess, true);

        final wallet = result.fold(
          (failure) => throw Exception('Test failed: ${failure.message}'),
          (wallet) => wallet,
        );

        expect(wallet.currency, 'MYR');
        expect(wallet.availableBalance, 0.0);
        expect(wallet.isActive, true);
      });

      testWidgets('should retrieve existing driver wallet', (tester) async {
        // Test wallet retrieval
        final result = await repository.getDriverWallet();

        expect(result.isSuccess, true);

        final wallet = result.fold(
          (failure) => null,
          (wallet) => wallet,
        );

        expect(wallet, isNotNull);
        expect(wallet!.currency, 'MYR');
      });
    });

    group('Earnings Deposit Processing', () {
      testWidgets('should process earnings deposit successfully', (tester) async {
        // Test earnings deposit
        final result = await service.processEarningsDeposit(
          orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
          grossEarnings: 25.00,
          netEarnings: 22.50,
          earningsBreakdown: {
            'base_commission': 20.00,
            'completion_bonus': 2.50,
            'deductions': 2.50,
          },
        );

        expect(result.isSuccess, true);

        // Verify wallet balance updated
        final walletResult = await repository.getDriverWallet();
        final wallet = walletResult.fold(
          (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
          (wallet) => wallet!,
        );

        expect(wallet.availableBalance, greaterThan(0));
        expect(wallet.totalEarned, greaterThan(0));
      });
    });

    group('Withdrawal Request Processing', () {
      testWidgets('should create withdrawal request successfully', (tester) async {
        // Ensure wallet has sufficient balance
        await service.processEarningsDeposit(
          orderId: 'test-order-withdrawal-${DateTime.now().millisecondsSinceEpoch}',
          grossEarnings: 50.00,
          netEarnings: 45.00,
          earningsBreakdown: {'base_commission': 45.00},
        );

        // Test withdrawal request
        final result = await service.processWithdrawalRequest(
          amount: 20.00,
          withdrawalMethod: 'bank_transfer',
          destinationDetails: {
            'bank_name': 'Test Bank',
            'account_number': '1234567890',
            'account_holder': 'Test Driver',
          },
        );

        expect(result.isSuccess, true);

        final requestId = result.fold(
          (failure) => throw Exception('Failed to create withdrawal: ${failure.message}'),
          (requestId) => requestId,
        );

        expect(requestId, isNotEmpty);
      });

      testWidgets('should reject withdrawal with insufficient balance', (tester) async {
        // Test insufficient balance scenario
        final result = await service.processWithdrawalRequest(
          amount: 10000.00, // Large amount
          withdrawalMethod: 'bank_transfer',
          destinationDetails: {'test': 'data'},
        );

        expect(result.isFailure, true);
      });
    });

    group('Real-time Updates', () {
      testWidgets('should stream wallet updates', (tester) async {
        final stream = repository.streamDriverWallet();

        // Listen to stream
        final streamData = <DriverWallet?>[];
        final subscription = stream.listen((wallet) {
          streamData.add(wallet);
        });

        // Wait for initial data
        await Future.delayed(const Duration(seconds: 2));

        expect(streamData, isNotEmpty);
        expect(streamData.last, isNotNull);

        await subscription.cancel();
      });
    });
  });
}
```

## 📚 Task 12: Documentation & Production Readiness

### **12.1 Production Deployment Checklist**

```markdown
# Driver Wallet System - Production Deployment Checklist

## Database Preparation
- [ ] Run database migrations for driver wallet tables
- [ ] Verify RLS policies are active and tested
- [ ] Create database indexes for performance
- [ ] Test database functions with sample data
- [ ] Verify audit logging is working

## Edge Functions Deployment
- [ ] Deploy driver-wallet-operations Edge Function
- [ ] Configure environment variables
- [ ] Test Edge Function endpoints
- [ ] Verify authentication and authorization
- [ ] Set up monitoring and logging

## Flutter App Integration
- [ ] Generate model classes with build_runner
- [ ] Test provider state management
- [ ] Verify real-time subscriptions
- [ ] Test UI components on Android emulator
- [ ] Validate error handling and edge cases

## Security Validation
- [ ] Test RLS policies with different user roles
- [ ] Verify wallet ownership validation
- [ ] Test withdrawal limits and validations
- [ ] Audit transaction logging
- [ ] Security penetration testing

## Performance Testing
- [ ] Load test Edge Functions
- [ ] Test real-time subscription performance
- [ ] Validate database query performance
- [ ] Test with multiple concurrent users
- [ ] Monitor memory usage and performance

## Integration Testing
- [ ] Test earnings deposit workflow
- [ ] Validate withdrawal request process
- [ ] Test real-time balance updates
- [ ] Verify notification delivery
- [ ] End-to-end driver workflow testing
```

### **12.2 Monitoring and Maintenance**

```sql
-- Driver wallet system health monitoring queries
-- Run these regularly to monitor system health

-- Check wallet balance consistency
SELECT
    COUNT(*) as total_wallets,
    SUM(available_balance) as total_available,
    SUM(pending_balance) as total_pending,
    AVG(available_balance) as avg_balance
FROM stakeholder_wallets
WHERE user_role = 'driver';

-- Monitor withdrawal request processing
SELECT
    status,
    COUNT(*) as request_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM driver_withdrawal_requests
WHERE requested_at >= NOW() - INTERVAL '7 days'
GROUP BY status;

-- Check for failed transactions
SELECT
    DATE(created_at) as date,
    COUNT(*) as failed_count
FROM wallet_transactions
WHERE wallet_id IN (
    SELECT id FROM stakeholder_wallets WHERE user_role = 'driver'
)
AND metadata->>'status' = 'failed'
AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## 🎯 Implementation Summary

This comprehensive implementation plan provides a complete driver wallet system that:

### **✅ Core Features Delivered**
- **Automated Earnings Deposits**: Seamless integration with driver earnings system
- **Flexible Withdrawal Options**: Bank transfers and e-wallet support
- **Real-time Balance Tracking**: Live updates using Supabase subscriptions
- **Comprehensive Security**: RLS policies, audit logging, and validation
- **Material Design 3 UI**: Consistent with existing app design

### **🔧 Technical Architecture**
- **Database Layer**: Extended stakeholder_wallets with driver-specific tables
- **Service Layer**: Enhanced services following existing patterns
- **State Management**: Riverpod providers for real-time updates
- **Security Layer**: RLS policies and audit logging
- **Edge Functions**: Secure wallet operations processing

### **📱 User Experience**
- **Driver Dashboard Integration**: Wallet balance widget and quick actions
- **Transaction History**: Comprehensive filtering and search capabilities
- **Withdrawal Management**: User-friendly withdrawal request process
- **Real-time Notifications**: Earnings deposits and withdrawal status updates

### **🚀 Production Ready**
- **Comprehensive Testing**: Integration tests and validation
- **Performance Optimized**: Database indexes and efficient queries
- **Monitoring Ready**: Health checks and audit trails
- **Documentation Complete**: Setup guides and maintenance procedures

This driver wallet system seamlessly integrates with the existing GigaEats infrastructure while providing drivers with a comprehensive financial management solution.
```
```
```
```
