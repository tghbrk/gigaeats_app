import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_providers_index.dart';
import '../../../user_management/domain/admin_user.dart';
import '../../../../data/models/user_role.dart';

// ============================================================================
// USER CREATION DIALOG
// ============================================================================

/// Dialog for creating new users
class UserCreationDialog extends ConsumerStatefulWidget {
  const UserCreationDialog({super.key});

  @override
  ConsumerState<UserCreationDialog> createState() => _UserCreationDialogState();
}

class _UserCreationDialogState extends ConsumerState<UserCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.customer;
  bool _isActive = true;
  bool _isVerified = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New User'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Role Selection
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  )).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      setState(() {
                        _selectedRole = role;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Status Switches
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('User can sign in and use the app'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Verified'),
                  subtitle: const Text('Email is verified'),
                  value: _isVerified,
                  onChanged: (value) {
                    setState(() {
                      _isVerified = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(adminUserManagementProvider.notifier);
      
      // Create user data
      final userData = {
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'role': _selectedRole.value,
        'is_active': _isActive,
        'is_verified': _isVerified,
        'password': _passwordController.text,
      };

      await notifier.createUser(userData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// ============================================================================
// USER EDIT DIALOG
// ============================================================================

/// Dialog for editing existing users
class UserEditDialog extends ConsumerStatefulWidget {
  final AdminUser user;

  const UserEditDialog({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends ConsumerState<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  
  late UserRole _selectedRole;
  late bool _isActive;
  late bool _isVerified;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _isVerified = widget.user.isVerified;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.user.fullName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email (read-only)
                TextFormField(
                  initialValue: widget.user.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                
                const SizedBox(height: 16),
                
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 16),
                
                // Role Selection
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  )).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      setState(() {
                        _selectedRole = role;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Status Switches
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('User can sign in and use the app'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Verified'),
                  subtitle: const Text('Email is verified'),
                  value: _isVerified,
                  onChanged: (value) {
                    setState(() {
                      _isVerified = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(adminUserManagementProvider.notifier);
      
      // Update user data
      final updates = <String, dynamic>{};
      
      if (_fullNameController.text.trim() != widget.user.fullName) {
        updates['full_name'] = _fullNameController.text.trim();
      }
      
      if (_phoneController.text.trim() != (widget.user.phoneNumber ?? '')) {
        updates['phone_number'] = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      }
      
      if (_selectedRole != widget.user.role) {
        updates['role'] = _selectedRole.value;
      }
      
      if (_isActive != widget.user.isActive) {
        updates['is_active'] = _isActive;
      }
      
      if (_isVerified != widget.user.isVerified) {
        updates['is_verified'] = _isVerified;
      }

      if (updates.isNotEmpty) {
        await notifier.updateUser(widget.user.id, updates);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
