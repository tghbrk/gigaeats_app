import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';

class EnhancedVerificationSuccessScreen extends ConsumerStatefulWidget {
  final String? email;

  const EnhancedVerificationSuccessScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<EnhancedVerificationSuccessScreen> createState() => _EnhancedVerificationSuccessScreenState();
}

class _EnhancedVerificationSuccessScreenState extends ConsumerState<EnhancedVerificationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _successAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _autoRedirectTimer;
  int _redirectCountdown = 5;
  bool _isAutoRedirecting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _checkAuthAndStartRedirect();
  }

  void _setupAnimations() {
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _successController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  void _checkAuthAndStartRedirect() {
    // Check auth status after a short delay to allow for state updates
    Future.delayed(const Duration(milliseconds: 1500), () {
      final authState = ref.read(authStateProvider);
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        _startAutoRedirect();
      }
    });
  }

  void _startAutoRedirect() {
    setState(() {
      _isAutoRedirecting = true;
    });

    _autoRedirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _redirectCountdown--;
      });

      if (_redirectCountdown <= 0) {
        timer.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _cancelAutoRedirect() {
    _autoRedirectTimer?.cancel();
    setState(() {
      _isAutoRedirecting = false;
      _redirectCountdown = 5;
    });
  }

  @override
  void dispose() {
    _autoRedirectTimer?.cancel();
    _successController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    _cancelAutoRedirect();
    if (widget.email != null) {
      context.go('/login?email=${Uri.encodeComponent(widget.email!)}');
    } else {
      context.go('/login');
    }
  }

  void _navigateToDashboard() {
    _cancelAutoRedirect();
    final authState = ref.read(authStateProvider);
    if (authState.user != null) {
      final route = AppRouter.getDashboardRoute(authState.user!.role);
      context.go(route);
    } else {
      _navigateToLogin();
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.salesAgent:
        return 'Sales Agent';
      case UserRole.driver:
        return 'Driver';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            _cancelAutoRedirect();
            context.go('/login');
          },
        ),
        title: const Text(
          'Email Verified',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isAutoRedirecting)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _cancelAutoRedirect,
                child: const Text('Cancel'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated Success Icon
              ScaleTransition(
                scale: _successAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
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

                    if (isAuthenticated && user != null) ...[
                      Text(
                        'Welcome to GigaEats, ${user.fullName}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_getRoleDisplayName(user.role)} Account',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You\'re all set to start using GigaEats! Your account has been successfully verified and you\'re now logged in.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        'Your email has been successfully verified. You can now sign in to your account.',
                        style: const TextStyle(
                          fontSize: 16,
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

              // Auto-redirect notification
              if (_isAutoRedirecting && isAuthenticated)
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Redirecting to dashboard in ${_redirectCountdown}s',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taking you to your ${_getRoleDisplayName(user?.role ?? UserRole.customer).toLowerCase()} dashboard...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Action Buttons
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    if (isAuthenticated && user != null) ...[
                      // User is authenticated - show dashboard button
                      CustomButton(
                        text: _isAutoRedirecting 
                            ? 'Go to Dashboard Now' 
                            : 'Go to Dashboard',
                        onPressed: _navigateToDashboard,
                        type: ButtonType.primary,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _cancelAutoRedirect();
                          context.go('/login');
                        },
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
                      CustomButton(
                        text: 'Sign In Now',
                        onPressed: _navigateToLogin,
                        type: ButtonType.primary,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text(
                          'Create a different account',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
