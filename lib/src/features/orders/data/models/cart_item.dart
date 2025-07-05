// Export the existing cart models to provide a unified interface
// Note: CartItem and CartState are defined in multiple providers - using specific exports to avoid conflicts
export '../../presentation/providers/cart_provider.dart' show CartItem, CartState, CartNotifier;
export '../../presentation/providers/customer/customer_cart_provider.dart' show CustomerCartState, CustomerCartNotifier;
// Enhanced cart exports:
// export '../../../sales_agent/presentation/providers/cart_provider.dart' show CartItem, CartState;

// Enhanced cart models
export 'enhanced_cart_models.dart' show EnhancedCartItem, EnhancedCartState, CartValidationResult, CartSummary;
export '../../presentation/providers/enhanced_cart_provider.dart' show EnhancedCartNotifier;
export '../services/enhanced_cart_service.dart' show EnhancedCartService;

// Cart persistence services
export '../services/cart_persistence_service.dart' show CartPersistenceService, CartPersistenceResult, CartLoadResult, CartHistoryEntry, CartMetadata;
export '../services/cart_storage_manager.dart' show CartStorageManager, CartStorageResult, CartStorageStats, CartStorageEvent;
export '../services/cart_sync_service.dart' show CartSyncService, CartSyncResult, CartSyncStatus, CartSyncState;

// Cart management services
export '../services/cart_management_service.dart' show CartManagementService, CartOperationResult, CartOperationEvent, CartPricingEvent, ItemPricingResult;
export '../services/cart_quantity_manager.dart' show CartQuantityManager, QuantityOptimizationResult, QuantityValidationResult, QuantityRecommendation, QuantityBudgetResult;

// Cart controllers
export '../../presentation/controllers/cart_operations_controller.dart' show CartOperationsController, CartOperationsState, CartOperation;
