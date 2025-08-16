import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';

class EmailVerificationErrorScreen extends ConsumerStatefulWidget {
  final String? errorCode;
  final String? errorMessage;
  final String? actionMessage;
  final String? email;

  const EmailVerificationErrorScreen({
    super.key,
    this.errorCode,
    this.errorMessage,
    this.actionMessage,
    this.email,
  });

  @override
  ConsumerState<EmailVerificationErrorScreen> createState() => _EmailVerificationErrorScreenState();
}

class _EmailVerificationErrorScreenState extends ConsumerState<EmailVerificationErrorScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shakeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _getErrorTitle {
    switch (widget.errorCode) {
      case 'otp_expired':
        return 'Link Expired';
      case 'access_denied':
        return 'Access Denied';
      case 'invalid_request':
        return 'Invalid Link';
      default:
        return 'Verification Failed';
    }
  }

  IconData get _getErrorIcon {
    switch (widget.errorCode) {
      case 'otp_expired':
        return Icons.access_time;
      case 'access_denied':
        return Icons.block;
      case 'invalid_request':
        return Icons.link_off;
      default:
        return Icons.error_outline;
    }
  }

  Color get _getErrorColor {
    switch (widget.errorCode) {
      case 'otp_expired':
        return Colors.orange;
      case 'access_denied':
        return Colors.red;
      case 'invalid_request':
        return Colors.red;
      default:
        return AppTheme.errorColor;
    }
  }

  List<Widget> get _getActionButtons {
    final buttons = <Widget>[];

    // Always show resend button if we have an email
    if (widget.email != null && widget.email!.isNotEmpty) {
      buttons.add(
        GEButton.primary(
          text: _isResending ? 'Sending...' : 'Send New Verification Email',
          onPressed: _isResending ? null : _resendVerificationEmail,
          isLoading: _isResending,
        ),
      );
      buttons.add(const SizedBox(height: 12));
    }

    // Show different secondary actions based on error type
    switch (widget.errorCode) {
      case 'otp_expired':
        buttons.add(
          GEButton.outline(
            text: 'Back to Email Verification',
            onPressed: () => _navigateToEmailVerification(),
          ),
        );
        break;
      case 'access_denied':
      case 'invalid_request':
        buttons.add(
          GEButton.outline(
            text: 'Try Different Email',
            onPressed: () => context.go('/register'),
          ),
        );
        break;
      default:
        buttons.add(
          GEButton.outline(
            text: 'Back to Login',
            onPressed: () => context.go(AppRoutes.login),
          ),
        );
    }

    buttons.add(const SizedBox(height: 16));
    buttons.add(
      TextButton(
        onPressed: () => context.go(AppRoutes.login),
        child: const Text(
          'Back to Login',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: Text(
          _getErrorTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated Error Icon
              ScaleTransition(
                scale: _shakeAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getErrorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getErrorColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getErrorIcon,
                    size: 60,
                    color: _getErrorColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Error Message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      _getErrorTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getErrorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    if (widget.errorMessage != null) ...[
                      Text(
                        widget.errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (widget.actionMessage != null) ...[
                      Text(
                        widget.actionMessage!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Troubleshooting Tips
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting Tips',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTroubleshootingTip('🔗', 'Make sure to open the link on the same device'),
                      _buildTroubleshootingTip('⏰', 'Verification links expire after 24 hours'),
                      _buildTroubleshootingTip('📧', 'Check your spam/junk folder for new emails'),
                      _buildTroubleshootingTip('🔄', 'Try requesting a fresh verification email'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: _getActionButtons,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingTip(String emoji, String text) {
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
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEmailVerification() {
    if (widget.email != null && widget.email!.isNotEmpty) {
      context.go('/email-verification?email=${Uri.encodeComponent(widget.email!)}');
    } else {
      context.go('/register');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (widget.email == null || widget.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No email address available. Please register again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await ref.read(authStateProvider.notifier).resendVerificationEmail(widget.email!);

      final authState = ref.read(authStateProvider);
      if (authState.errorMessage != null) {
        throw Exception(authState.errorMessage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New verification email sent successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate to email verification screen
        context.go('/email-verification?email=${Uri.encodeComponent(widget.email!)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
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
}
