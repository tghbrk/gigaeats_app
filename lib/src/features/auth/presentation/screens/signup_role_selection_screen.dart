import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';

/// Role selection screen for GigaEats signup
/// Phase 4: Frontend Implementation
class SignupRoleSelectionScreen extends StatefulWidget {
  const SignupRoleSelectionScreen({super.key});

  @override
  State<SignupRoleSelectionScreen> createState() => _SignupRoleSelectionScreenState();
}

class _SignupRoleSelectionScreenState extends State<SignupRoleSelectionScreen>
    with TickerProviderStateMixin {
  
  UserRole? _selectedRole;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildHeader(),
              ),
              
              const SizedBox(height: 40),
              
              // Role selection cards
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildRoleSelectionCards(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Continue button
              SlideTransition(
                position: _slideAnimation,
                child: _buildContinueButton(),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // GigaEats logo/title
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'GigaEats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Choose Your Role',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Select how you\'d like to use GigaEats',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCards() {
    final roles = [
      UserRole.customer,
      UserRole.vendor,
      UserRole.driver,
      UserRole.salesAgent,
    ];

    return ListView.builder(
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final roleInfo = _getRoleInfo(role);
        final isSelected = _selectedRole == role;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            elevation: isSelected ? 8 : 2,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedRole = role),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? roleInfo.primaryColor 
                        : Colors.transparent,
                    width: 2,
                  ),
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            roleInfo.primaryColor.withValues(alpha: 0.1),
                            roleInfo.primaryColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // Role icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: roleInfo.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        roleInfo.icon,
                        size: 32,
                        color: roleInfo.primaryColor,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Role info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? roleInfo.primaryColor 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleInfo.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? roleInfo.primaryColor 
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected 
                            ? roleInfo.primaryColor 
                            : Colors.transparent,
                      ),
                      child: isSelected 
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return GEButton.primary(
      onPressed: _selectedRole != null ? _handleContinue : null,
      text: _selectedRole != null
          ? 'Continue as ${_selectedRole!.displayName}'
          : 'Select a Role to Continue',
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

  void _handleContinue() {
    if (_selectedRole != null) {
      context.go('/signup/${_selectedRole!.value}');
    }
  }

  RoleSelectionInfo _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return RoleSelectionInfo(
          icon: Icons.restaurant,
          description: 'Order delicious food from restaurants',
          primaryColor: Colors.blue,
        );
      case UserRole.vendor:
        return RoleSelectionInfo(
          icon: Icons.store,
          description: 'Manage your restaurant business',
          primaryColor: Colors.green,
        );
      case UserRole.driver:
        return RoleSelectionInfo(
          icon: Icons.delivery_dining,
          description: 'Deliver food and earn money',
          primaryColor: Colors.orange,
        );
      case UserRole.salesAgent:
        return RoleSelectionInfo(
          icon: Icons.business,
          description: 'Help businesses with bulk orders',
          primaryColor: Colors.purple,
        );
      case UserRole.admin:
        return RoleSelectionInfo(
          icon: Icons.admin_panel_settings,
          description: 'Manage the platform',
          primaryColor: Colors.red,
        );
    }
  }
}

class RoleSelectionInfo {
  final IconData icon;
  final String description;
  final Color primaryColor;

  RoleSelectionInfo({
    required this.icon,
    required this.description,
    required this.primaryColor,
  });
}
