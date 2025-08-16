import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/auth_config.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';
import '../providers/enhanced_auth_provider.dart';

/// Role-specific signup screen for GigaEats authentication
/// Phase 4: Frontend Implementation
class RoleSignupScreen extends ConsumerStatefulWidget {
  final UserRole role;
  
  const RoleSignupScreen({super.key, required this.role});

  @override
  ConsumerState<RoleSignupScreen> createState() => _RoleSignupScreenState();
}

class _RoleSignupScreenState extends ConsumerState<RoleSignupScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(enhancedAuthStateProvider);

    // Listen to auth state changes for navigation
    ref.listen<EnhancedAuthState>(enhancedAuthStateProvider, (previous, next) {
      if (next.status == EnhancedAuthStatus.emailVerificationPending) {
        // Navigate to email verification screen
        context.go('/email-verification?email=${Uri.encodeComponent(next.pendingVerificationEmail ?? '')}');
      } else if (next.status == EnhancedAuthStatus.authenticated && next.user != null) {
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
      appBar: AppBar(
        title: Text('Sign Up as ${widget.role.displayName}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role-specific header
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildRoleHeader(),
                ),
                
                const SizedBox(height: 32),
                
                // Form fields
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildFormFields(),
                ),
                
                const SizedBox(height: 24),
                
                // Terms and conditions
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildTermsAndConditions(),
                ),
                
                const SizedBox(height: 32),
                
                // Signup button
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildSignupButton(authState),
                ),
                
                const SizedBox(height: 16),
                
                // Login link
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginLink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeader() {
    final roleInfo = _getRoleInfo(widget.role);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: roleInfo.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: roleInfo.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            roleInfo.icon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Join as ${widget.role.displayName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roleInfo.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Full Name
        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Email
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Phone (conditional based on role)
        if (_shouldShowPhoneField())
          Column(
            children: [
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number ${_isPhoneRequired() ? '' : '(Optional)'}',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _isPhoneRequired() ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        
        // Password
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (!AuthConfig.isPasswordValid(value)) {
              return 'Password must be at least 8 characters with uppercase, lowercase, and number';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Confirm Password
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton(EnhancedAuthState authState) {
    return GEButton.primary(
      onPressed: authState.status == EnhancedAuthStatus.loading || !_acceptedTerms
          ? null
          : _handleSignup,
      isLoading: authState.status == EnhancedAuthStatus.loading,
      text: 'Create ${widget.role.displayName} Account',
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/login'),
        child: Text.rich(
          TextSpan(
            text: 'Already have an account? ',
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: 'Sign In',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ref.read(enhancedAuthStateProvider.notifier).signUpWithRole(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      role: widget.role,
      phoneNumber: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null,
    );
  }

  bool _shouldShowPhoneField() {
    return AuthConfig.requiresPhoneVerification(widget.role.value) ||
           widget.role == UserRole.vendor;
  }

  bool _isPhoneRequired() {
    return AuthConfig.requiresPhoneVerification(widget.role.value);
  }

  RoleInfo _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return RoleInfo(
          icon: Icons.restaurant,
          description: 'Order delicious food from your favorite restaurants',
          gradientColors: [Colors.blue, Colors.blueAccent],
        );
      case UserRole.vendor:
        return RoleInfo(
          icon: Icons.store,
          description: 'Manage your restaurant and reach more customers',
          gradientColors: [Colors.green, Colors.greenAccent],
        );
      case UserRole.driver:
        return RoleInfo(
          icon: Icons.delivery_dining,
          description: 'Earn money by delivering food to customers',
          gradientColors: [Colors.orange, Colors.orangeAccent],
        );
      case UserRole.salesAgent:
        return RoleInfo(
          icon: Icons.business,
          description: 'Help businesses with bulk food ordering',
          gradientColors: [Colors.purple, Colors.purpleAccent],
        );
      case UserRole.admin:
        return RoleInfo(
          icon: Icons.admin_panel_settings,
          description: 'Manage the GigaEats platform',
          gradientColors: [Colors.red, Colors.redAccent],
        );
    }
  }
}

class RoleInfo {
  final IconData icon;
  final String description;
  final List<Color> gradientColors;

  RoleInfo({
    required this.icon,
    required this.description,
    required this.gradientColors,
  });
}
