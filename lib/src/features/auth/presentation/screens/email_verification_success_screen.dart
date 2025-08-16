import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';
import '../providers/auth_provider.dart';

class EmailVerificationSuccessScreen extends ConsumerStatefulWidget {
  final String? email;
  final bool autoLoginAttempted;

  const EmailVerificationSuccessScreen({
    super.key,
    this.email,
    this.autoLoginAttempted = false,
  });

  @override
  ConsumerState<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends ConsumerState<EmailVerificationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    if (widget.email != null) {
      context.go('${AppRoutes.login}?email=${Uri.encodeComponent(widget.email!)}');
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _navigateToDashboard() {
    final authState = ref.read(authStateProvider);
    if (authState.user != null) {
      final route = AppRouter.getDashboardRoute(authState.user!.role);
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text(
          'Email Verified',
          style: TextStyle(
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon with Animation
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 60,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Success Message
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Email Verified!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          Text(
                            isAuthenticated
                                ? 'Welcome to GigaEats! You\'re all set to start ordering.'
                                : 'Your email has been successfully verified. You can now sign in to your account.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (widget.email != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.email!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    if (isAuthenticated) ...[
                      // User is authenticated - show dashboard button
                      GEButton.primary(
                        text: 'Go to Dashboard',
                        onPressed: _navigateToDashboard,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Sign in with different account',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else ...[
                      // User needs to sign in manually
                      GEButton.primary(
                        text: 'Sign In Now',
                        onPressed: _navigateToLogin,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text(
                          'Create a different account',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
