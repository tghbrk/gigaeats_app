import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/auth_config.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/enhanced_auth_provider.dart';

class EnhancedEmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EnhancedEmailVerificationScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<EnhancedEmailVerificationScreen> createState() => _EnhancedEmailVerificationScreenState();
}

class _EnhancedEmailVerificationScreenState extends ConsumerState<EnhancedEmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  bool _isCheckingVerification = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  Timer? _autoCheckTimer;
  int _autoCheckAttempts = 0;
  static const int maxAutoCheckAttempts = 12; // 2 minutes of checking every 10 seconds
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoVerificationCheck();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _startAutoVerificationCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_autoCheckAttempts >= maxAutoCheckAttempts) {
        timer.cancel();
        return;
      }
      
      _autoCheckAttempts++;
      _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    if (_isCheckingVerification) return;
    
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // Check current auth status using enhanced provider
      final authState = ref.read(enhancedAuthStateProvider);

      if (authState.status == EnhancedAuthStatus.authenticated) {
        _autoCheckTimer?.cancel();
        _navigateToSuccess();
      }
    } catch (e) {
      debugPrint('Auto verification check failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  void _navigateToSuccess() {
    context.go('/email-verification-success?email=${Uri.encodeComponent(widget.email ?? '')}');
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoCheckTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(enhancedAuthStateProvider);

    // Listen to auth state changes for navigation
    ref.listen<EnhancedAuthState>(enhancedAuthStateProvider, (previous, next) {
      if (next.status == EnhancedAuthStatus.authenticated && next.user != null) {
        // Navigate to appropriate dashboard
        final dashboardRoute = AuthConfig.getRedirectUrlForRole(next.user!.role.value);
        context.go(dashboardRoute);
      }

      // Show success/error messages
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with improved back navigation
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // Animated email verification illustration
              _buildAnimatedIllustration(),
              
              const SizedBox(height: 32),
              
              // Enhanced content section
              SlideTransition(
                position: _slideAnimation,
                child: _buildContentSection(authState),
              ),

              const SizedBox(height: 32),

              // Action buttons with improved states
              _buildActionButtons(authState),
              
              const Spacer(),
              
              // Enhanced help section with multiple scenarios
              _buildEnhancedHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            _autoCheckTimer?.cancel();
            // Clear any pending state and navigate back
            context.go('/login');
          },
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.textPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          'Verify Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_isCheckingVerification)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedIllustration() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.mark_email_unread_outlined,
          size: 60,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildContentSection(EnhancedAuthState authState) {
    return Column(
      children: [
        // Title with status indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_autoCheckAttempts > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Checking...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Enhanced description
        Text(
          'We\'ve sent a verification link to:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Email address with copy functionality
        GestureDetector(
          onTap: () {
            // Copy email to clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Email copied to clipboard'),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.email ?? authState.pendingVerificationEmail ?? 'your email address',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Enhanced instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Click the verification link in your email to complete your registration and start using GigaEats.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re automatically checking for verification...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(EnhancedAuthState authState) {
    return Column(
      children: [
        // Resend email button with countdown
        CustomButton(
          text: _resendCountdown > 0 
              ? 'Resend in ${_resendCountdown}s'
              : _isResending 
                  ? 'Sending...' 
                  : 'Resend Verification Email',
          onPressed: (_isResending || _resendCountdown > 0) ? null : _resendVerificationEmail,
          isLoading: _isResending,
          type: ButtonType.outline,
        ),

        const SizedBox(height: 12),

        // Manual check button
        CustomButton(
          text: _isCheckingVerification ? 'Checking...' : 'Check Verification Status',
          onPressed: _isCheckingVerification ? null : _checkVerificationStatus,
          isLoading: _isCheckingVerification,
          type: ButtonType.secondary,
        ),

        const SizedBox(height: 16),

        // Back to login button
        CustomButton(
          text: 'Back to Login',
          onPressed: () {
            _autoCheckTimer?.cancel();
            context.go('/login');
          },
          type: ButtonType.text,
        ),
      ],
    );
  }

  Widget _buildEnhancedHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpItem('📧', 'Check your spam/junk folder'),
          _buildHelpItem('⏰', 'Verification links expire in 24 hours'),
          _buildHelpItem('🔄', 'Try resending if you don\'t receive it'),
          _buildHelpItem('📱', 'Make sure to open the link on this device'),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final email = widget.email ?? ref.read(enhancedAuthStateProvider).pendingVerificationEmail;
      if (email != null) {
        await ref.read(enhancedAuthStateProvider.notifier).resendVerificationEmail(email);
      } else {
        throw Exception('No email address found for verification');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Start countdown timer
        _startResendCountdown();
        
        // Reset auto-check attempts
        _autoCheckAttempts = 0;
        _startAutoVerificationCheck();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });

      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }
}
