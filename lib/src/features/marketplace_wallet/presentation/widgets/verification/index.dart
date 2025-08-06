// Customer wallet verification widgets
//
// This module provides a comprehensive set of widgets for customer wallet verification,
// following the unified verification approach that combines bank account verification,
// document upload, and optional instant verification into a single cohesive experience.

// Core verification widgets
export 'customer_unified_verification_form.dart';
export 'customer_verification_status_card.dart';
export 'customer_verification_progress_indicator.dart';
export 'customer_verification_info_banner.dart';

/// Widget Usage Examples:
/// 
/// ```dart
/// // Status card with retry functionality
/// CustomerVerificationStatusCard(
///   isVerified: false,
///   verificationStatus: 'failed',
///   lastUpdated: DateTime.now(),
///   onRetry: () => _retryVerification(),
///   showInstantVerificationInfo: true,
/// )
/// 
/// // Progress indicator with unified verification details
/// CustomerVerificationProgressIndicator(
///   currentStep: 2,
///   totalSteps: 3,
///   showUnifiedProgress: true,
///   verificationStatuses: {
///     'bank_verification_status': 'verified',
///     'document_verification_status': 'processing',
///     'instant_verification_status': 'pending',
///   },
/// )
/// 
/// // Info banner for unverified wallet
/// CustomerVerificationInfoBanner.unverified(
///   onStartVerification: () => _startVerification(),
/// )
/// 
/// // Unified verification form
/// CustomerUnifiedVerificationForm(
///   onSubmit: (data) => _handleVerificationSubmit(data),
///   isLoading: false,
/// )
/// ```
