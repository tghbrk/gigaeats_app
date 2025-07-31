import 'package:flutter/material.dart';

import '../../../data/models/driver_bank_account.dart';

/// Widget for selecting bank account for withdrawal
class BankAccountSelector extends StatelessWidget {
  final List<DriverBankAccount> bankAccounts;
  final String? selectedAccountId;
  final Function(String?) onAccountSelected;
  final bool isLoading;

  const BankAccountSelector({
    super.key,
    required this.bankAccounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading bank accounts...'),
            ],
          ),
        ),
      );
    }
    
    if (bankAccounts.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Filter verified accounts only
    final verifiedAccounts = bankAccounts
        .where((account) => account.verificationStatus == 'verified')
        .toList();
    
    if (verifiedAccounts.isEmpty) {
      return _buildNoVerifiedAccountsState(context);
    }
    
    return Column(
      children: verifiedAccounts.map((account) {
        return _buildAccountCard(context, account);
      }).toList(),
    );
  }

  Widget _buildAccountCard(BuildContext context, DriverBankAccount account) {
    final theme = Theme.of(context);
    final isSelected = selectedAccountId == account.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: () => onAccountSelected(account.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bank icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Account details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          account.bankName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (account.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Primary',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskAccountNumber(account.accountNumber),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.accountHolderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Verification status and selection
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getVerificationStatusColor(theme, account.verificationStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Radio<String>(
                    value: account.id,
                    groupValue: selectedAccountId,
                    onChanged: (value) => onAccountSelected(value),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Bank Accounts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to add and verify a bank account before you can withdraw funds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // Navigate to add bank account screen
                // This would be handled by the parent widget
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVerifiedAccountsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.pending_actions,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Verified Accounts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have bank accounts but none are verified yet. Please complete the verification process to enable withdrawals.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to bank accounts management
                  },
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Manage Accounts'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    // Navigate to add new account
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) {
      return accountNumber;
    }
    
    final visibleDigits = 4;
    final maskedPart = '*' * (accountNumber.length - visibleDigits);
    final visiblePart = accountNumber.substring(accountNumber.length - visibleDigits);
    
    return '$maskedPart$visiblePart';
  }

  Color _getVerificationStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
