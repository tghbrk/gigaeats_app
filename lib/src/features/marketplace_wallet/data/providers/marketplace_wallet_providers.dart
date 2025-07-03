import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/marketplace_wallet_repository.dart';
import '../services/marketplace_payment_service.dart';
import '../services/wallet_cache_service.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Wallet cache service provider
final walletCacheServiceProvider = Provider<WalletCacheService>((ref) {
  return WalletCacheService();
});

/// Marketplace wallet repository provider
final marketplaceWalletRepositoryProvider = Provider<MarketplaceWalletRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MarketplaceWalletRepository(client: client);
});

/// Marketplace payment service provider
final marketplacePaymentServiceProvider = Provider<MarketplacePaymentService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MarketplacePaymentService(client: client);
});

/// Repository providers with dependency injection
final walletRepositoryProvider = Provider<MarketplaceWalletRepository>((ref) {
  return ref.watch(marketplaceWalletRepositoryProvider);
});

final paymentServiceProvider = Provider<MarketplacePaymentService>((ref) {
  return ref.watch(marketplacePaymentServiceProvider);
});

final cacheServiceProvider = Provider<WalletCacheService>((ref) {
  return ref.watch(walletCacheServiceProvider);
});
