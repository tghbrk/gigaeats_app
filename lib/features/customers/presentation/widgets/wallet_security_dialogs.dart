import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/customer_security_provider.dart';
import '../../data/services/biometric_auth_service.dart';

/// Widget for biometric authentication settings
class BiometricAuthenticationWidget extends ConsumerStatefulWidget {
  final bool isEnabled;
  final VoidCallback? onChanged;

  const BiometricAuthenticationWidget({
    super.key,
    required this.isEnabled,
    this.onChanged,
  });

  @override
  ConsumerState<BiometricAuthenticationWidget> createState() => _BiometricAuthenticationWidgetState();
}

class _BiometricAuthenticationWidgetState extends ConsumerState<BiometricAuthenticationWidget> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAvailable = false;
  bool _isLoading = true;
  List<BiometricType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      final availableTypes = await _biometricService.getAvailableBiometrics();

      setState(() {
        _isAvailable = isAvailable;
        _availableTypes = availableTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBiometricIcon(),
                  color: _isAvailable ? AppTheme.primaryColor : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Authentication',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isAvailable
                            ? _getBiometricDisplayName()
                            : 'Not available on this device',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable && widget.isEnabled,
                  onChanged: _isAvailable ? _handleBiometricToggle : null,
                ),
              ],
            ),

            if (!_isAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometric authentication is not available on this device. Please set up fingerprint or face recognition in your device settings.',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableTypes.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableTypes.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }

  String _getBiometricDisplayName() {
    if (_availableTypes.isEmpty) {
      return 'Biometric Authentication';
    } else if (_availableTypes.length == 1) {
      return _availableTypes.first.displayName;
    } else {
      return 'Biometric Authentication';
    }
  }

  Future<void> _handleBiometricToggle(bool enabled) async {
    if (enabled) {
      // Test biometric authentication before enabling
      final result = await _biometricService.authenticate(
        reason: 'Verify your identity to enable biometric authentication for wallet transactions',
      );

      if (result.isSuccess) {
        try {
          await ref.read(customerSecurityProvider.notifier).enableBiometric();
          widget.onChanged?.call();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication enabled'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to enable biometric authentication: ${e.toString()}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Biometric authentication failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      try {
        await ref.read(customerSecurityProvider.notifier).disableBiometric();
        widget.onChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication disabled'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disable biometric authentication: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

/// Dialog for setting up a new PIN
class PinSetupDialog extends ConsumerStatefulWidget {
  const PinSetupDialog({super.key});

  @override
  ConsumerState<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends ConsumerState<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _currentPin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1; // 1: Enter PIN, 2: Confirm PIN

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        _step == 1 ? 'Set Up PIN' : 'Confirm PIN',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _step == 1 
                  ? 'Enter a 6-digit PIN for wallet transactions'
                  : 'Re-enter your PIN to confirm',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            if (_isLoading) ...[
              const LoadingWidget(),
            ] else ...[
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _step == 1 ? _pinController : _confirmPinController,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  inactiveFillColor: Colors.grey.shade100,
                  selectedFillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: AppTheme.primaryColor,
                ),
                enableActiveFill: true,
                onCompleted: (pin) {
                  if (_step == 1) {
                    setState(() {
                      _currentPin = pin;
                      _step = 2;
                      _errorMessage = null;
                    });
                  } else {
                    setState(() {
                      _confirmPin = pin;
                    });
                    _validateAndSetPin();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_step == 2) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = 1;
                    _currentPin = '';
                    _confirmPin = '';
                    _pinController.clear();
                    _confirmPinController.clear();
                    _errorMessage = null;
                  });
                },
                child: const Text('Back to Enter PIN'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_step == 1 && _currentPin.length == 6)
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _step = 2;
                _errorMessage = null;
              });
            },
            child: const Text('Next'),
          ),
      ],
    );
  }

  Future<void> _validateAndSetPin() async {
    if (_currentPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _step = 1;
        _currentPin = '';
        _confirmPin = '';
        _pinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(customerSecurityProvider.notifier).setPIN(_currentPin);
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set up successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to set PIN: ${e.toString()}';
      });
    }
  }
}

/// Dialog for changing an existing PIN
class PinChangeDialog extends ConsumerStatefulWidget {
  const PinChangeDialog({super.key});

  @override
  ConsumerState<PinChangeDialog> createState() => _PinChangeDialogState();
}

class _PinChangeDialogState extends ConsumerState<PinChangeDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1; // 1: Current PIN, 2: New PIN, 3: Confirm PIN

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    TextEditingController controller;

    switch (_step) {
      case 1:
        title = 'Enter Current PIN';
        subtitle = 'Enter your current 6-digit PIN';
        controller = _currentPinController;
        break;
      case 2:
        title = 'Enter New PIN';
        subtitle = 'Enter your new 6-digit PIN';
        controller = _newPinController;
        break;
      case 3:
        title = 'Confirm New PIN';
        subtitle = 'Re-enter your new PIN to confirm';
        controller = _confirmPinController;
        break;
      default:
        title = 'Change PIN';
        subtitle = '';
        controller = _currentPinController;
    }

    return AlertDialog(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            if (_isLoading) ...[
              const LoadingWidget(),
            ] else ...[
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: controller,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  inactiveFillColor: Colors.grey.shade100,
                  selectedFillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: AppTheme.primaryColor,
                ),
                enableActiveFill: true,
                onCompleted: (pin) {
                  _handlePinCompleted(pin);
                },
                onChanged: (value) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_step > 1)
          TextButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _step--;
                _errorMessage = null;
                // Clear the current controller
                switch (_step) {
                  case 1:
                    _currentPinController.clear();
                    break;
                  case 2:
                    _newPinController.clear();
                    break;
                }
              });
            },
            child: const Text('Back'),
          ),
      ],
    );
  }

  void _handlePinCompleted(String pin) {
    switch (_step) {
      case 1:
        setState(() {
          _currentPin = pin;
        });
        _verifyCurrentPin();
        break;
      case 2:
        setState(() {
          _newPin = pin;
          _step = 3;
          _errorMessage = null;
        });
        break;
      case 3:
        setState(() {
          _confirmPin = pin;
        });
        _validateAndChangePin();
        break;
    }
  }

  Future<void> _verifyCurrentPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await ref.read(customerSecurityProvider.notifier).verifyPIN(_currentPin);
      
      if (isValid) {
        setState(() {
          _isLoading = false;
          _step = 2;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Current PIN is incorrect';
          _currentPinController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to verify PIN: ${e.toString()}';
        _currentPinController.clear();
      });
    }
  }

  Future<void> _validateAndChangePin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'New PINs do not match. Please try again.';
        _step = 2;
        _newPin = '';
        _confirmPin = '';
        _newPinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    if (_newPin == _currentPin) {
      setState(() {
        _errorMessage = 'New PIN must be different from current PIN';
        _step = 2;
        _newPin = '';
        _confirmPin = '';
        _newPinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(customerSecurityProvider.notifier).setPIN(_newPin);
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN changed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to change PIN: ${e.toString()}';
      });
    }
  }
}
