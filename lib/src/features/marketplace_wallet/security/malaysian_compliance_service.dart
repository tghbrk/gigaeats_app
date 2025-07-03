
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../data/models/wallet_transaction.dart';
import '../data/models/payout_request.dart';
import '../data/models/stakeholder_wallet.dart';

/// Malaysian financial compliance service implementing Bank Negara Malaysia guidelines
class MalaysianComplianceService {
  final AppLogger _logger;

  MalaysianComplianceService(this._logger);

  /// Validates compliance with Bank Negara Malaysia (BNM) e-money regulations
  Future<ComplianceValidationResult> validateEMoneyCompliance({
    required StakeholderWallet wallet,
    required WalletTransaction transaction,
  }) async {
    final violations = <ComplianceViolation>[];
    final warnings = <String>[];

    try {
      // BNM e-Money Regulation 1: Maximum wallet balance limit
      if (wallet.availableBalance + transaction.amount > 5000.00) {
        violations.add(ComplianceViolation(
          code: 'BNM_EMONEY_001',
          description: 'E-money wallet balance exceeds RM 5,000 limit',
          regulation: 'Bank Negara Malaysia e-Money Guidelines',
          severity: ComplianceSeverity.high,
        ));
      }

      // BNM e-Money Regulation 2: Daily transaction limit
      final dailyTotal = await _calculateDailyTransactionTotal(wallet.id);
      if (dailyTotal + transaction.amount > 1000.00) {
        violations.add(ComplianceViolation(
          code: 'BNM_EMONEY_002',
          description: 'Daily transaction limit of RM 1,000 exceeded',
          regulation: 'Bank Negara Malaysia e-Money Guidelines',
          severity: ComplianceSeverity.medium,
        ));
      }

      // BNM e-Money Regulation 3: Monthly transaction limit
      final monthlyTotal = await _calculateMonthlyTransactionTotal(wallet.id);
      if (monthlyTotal + transaction.amount > 10000.00) {
        violations.add(ComplianceViolation(
          code: 'BNM_EMONEY_003',
          description: 'Monthly transaction limit of RM 10,000 exceeded',
          regulation: 'Bank Negara Malaysia e-Money Guidelines',
          severity: ComplianceSeverity.high,
        ));
      }

      // Warning for approaching limits
      if (wallet.availableBalance + transaction.amount > 4000.00) {
        warnings.add('Approaching maximum wallet balance limit (RM 5,000)');
      }

      _logger.info('BNM e-money compliance validation completed', {
        'wallet_id': wallet.id,
        'transaction_amount': transaction.amount,
        'violations': violations.length,
        'warnings': warnings.length,
      });

      return ComplianceValidationResult(
        isCompliant: violations.isEmpty,
        violations: violations,
        warnings: warnings,
        requiresApproval: violations.any((v) => v.severity == ComplianceSeverity.high),
      );
    } catch (e) {
      _logger.error('BNM compliance validation error', e);
      return ComplianceValidationResult(
        isCompliant: false,
        violations: [
          ComplianceViolation(
            code: 'BNM_SYSTEM_ERROR',
            description: 'Compliance validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        warnings: [],
        requiresApproval: true,
      );
    }
  }

  /// Validates Anti-Money Laundering (AML) compliance
  Future<AMLValidationResult> validateAMLCompliance({
    required String userId,
    required WalletTransaction transaction,
    Map<String, dynamic>? additionalContext,
  }) async {
    final suspiciousActivities = <SuspiciousActivity>[];

    try {
      // AML Check 1: Large transaction reporting (RM 25,000+)
      if (transaction.amount >= 25000.00) {
        suspiciousActivities.add(SuspiciousActivity(
          type: SuspiciousActivityType.largeTransaction,
          description: 'Transaction amount exceeds RM 25,000 reporting threshold',
          amount: transaction.amount,
          riskLevel: RiskLevel.high,
          reportingRequired: true,
        ));
      }

      // AML Check 2: Rapid succession of transactions
      final recentTransactions = await _getRecentTransactions(userId, Duration(hours: 1));
      if (recentTransactions.length > 10) {
        suspiciousActivities.add(SuspiciousActivity(
          type: SuspiciousActivityType.rapidTransactions,
          description: 'Multiple transactions in short time period',
          amount: transaction.amount,
          riskLevel: RiskLevel.medium,
          reportingRequired: false,
        ));
      }

      // AML Check 3: Unusual transaction patterns
      final patternAnalysis = await _analyzeTransactionPattern(userId, transaction);
      if (patternAnalysis.isUnusual) {
        suspiciousActivities.add(SuspiciousActivity(
          type: SuspiciousActivityType.unusualPattern,
          description: patternAnalysis.description,
          amount: transaction.amount,
          riskLevel: patternAnalysis.riskLevel,
          reportingRequired: patternAnalysis.riskLevel == RiskLevel.high,
        ));
      }

      // AML Check 4: Cross-border transaction monitoring
      if (additionalContext?['cross_border'] == true) {
        suspiciousActivities.add(SuspiciousActivity(
          type: SuspiciousActivityType.crossBorder,
          description: 'Cross-border transaction requires additional monitoring',
          amount: transaction.amount,
          riskLevel: RiskLevel.medium,
          reportingRequired: transaction.amount >= 10000.00,
        ));
      }

      final calculatedRiskScore = _calculateRiskScore(suspiciousActivities);

      _logger.info('AML compliance validation completed', {
        'user_id': userId,
        'transaction_amount': transaction.amount,
        'suspicious_activities': suspiciousActivities.length,
        'risk_score': calculatedRiskScore,
      });

      return AMLValidationResult(
        isCompliant: calculatedRiskScore < 0.7,
        suspiciousActivities: suspiciousActivities,
        riskScore: calculatedRiskScore,
        requiresReporting: suspiciousActivities.any((a) => a.reportingRequired),
        requiresManualReview: calculatedRiskScore >= 0.5,
      );
    } catch (e) {
      _logger.error('AML validation error', e);
      return AMLValidationResult(
        isCompliant: false,
        suspiciousActivities: [],
        riskScore: 1.0,
        requiresReporting: true,
        requiresManualReview: true,
      );
    }
  }

  /// Validates payout compliance with Malaysian banking regulations
  Future<PayoutComplianceResult> validatePayoutCompliance(PayoutRequest request) async {
    final violations = <ComplianceViolation>[];
    final requirements = <ComplianceRequirement>[];

    try {
      // Malaysian Banking Regulation 1: Minimum payout amount
      if (request.amount < 10.00) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_001',
          description: 'Minimum payout amount is RM 10.00',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.medium,
        ));
      }

      // Malaysian Banking Regulation 2: Maximum daily payout
      final dailyPayouts = await _calculateDailyPayoutTotal(request.walletId);
      if (dailyPayouts + request.amount > 50000.00) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_002',
          description: 'Daily payout limit of RM 50,000 exceeded',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.high,
        ));
      }

      // Malaysian Banking Regulation 3: Bank account validation
      if (!_isValidMalaysianBankAccount(request.bankAccountNumber, request.bankName)) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_003',
          description: 'Invalid Malaysian bank account format',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.high,
        ));
      }

      // Compliance Requirements
      if (request.amount >= 10000.00) {
        requirements.add(ComplianceRequirement(
          type: 'ENHANCED_DUE_DILIGENCE',
          description: 'Enhanced due diligence required for payouts ≥ RM 10,000',
          mandatory: true,
        ));
      }

      if (request.swiftCode != null) {
        requirements.add(ComplianceRequirement(
          type: 'INTERNATIONAL_TRANSFER_APPROVAL',
          description: 'International transfer requires additional approval',
          mandatory: true,
        ));
      }

      _logger.info('Payout compliance validation completed', {
        'payout_id': request.id,
        'amount': request.amount,
        'violations': violations.length,
        'requirements': requirements.length,
      });

      return PayoutComplianceResult(
        isCompliant: violations.isEmpty,
        violations: violations,
        requirements: requirements,
        requiresApproval: violations.isNotEmpty || requirements.any((r) => r.mandatory),
      );
    } catch (e) {
      _logger.error('Payout compliance validation error', e);
      return PayoutComplianceResult(
        isCompliant: false,
        violations: [
          ComplianceViolation(
            code: 'PAYOUT_SYSTEM_ERROR',
            description: 'Payout compliance validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        requirements: [],
        requiresApproval: true,
      );
    }
  }

  /// Generates compliance report for regulatory submission
  Future<ComplianceReport> generateComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
    ComplianceReportType type = ComplianceReportType.monthly,
  }) async {
    try {
      final transactions = await _getTransactionsForPeriod(startDate, endDate);
      final payouts = await _getPayoutsForPeriod(startDate, endDate);
      
      final summary = ComplianceReportSummary(
        totalTransactions: transactions.length,
        totalTransactionAmount: transactions.fold(0.0, (sum, t) => sum + t.amount),
        totalPayouts: payouts.length,
        totalPayoutAmount: payouts.fold(0.0, (sum, p) => sum + p.amount),
        suspiciousActivities: await _getSuspiciousActivitiesForPeriod(startDate, endDate),
        complianceViolations: await _getComplianceViolationsForPeriod(startDate, endDate),
      );

      _logger.info('Compliance report generated', {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'type': type.toString(),
        'total_transactions': summary.totalTransactions,
      });

      return ComplianceReport(
        id: _generateReportId(),
        type: type,
        startDate: startDate,
        endDate: endDate,
        summary: summary,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Compliance report generation error', e);
      rethrow;
    }
  }

  // Private helper methods

  Future<double> _calculateDailyTransactionTotal(String walletId) async {
    // Implementation would query database for daily transaction total
    return 0.0; // Placeholder
  }

  Future<double> _calculateMonthlyTransactionTotal(String walletId) async {
    // Implementation would query database for monthly transaction total
    return 0.0; // Placeholder
  }

  Future<double> _calculateDailyPayoutTotal(String walletId) async {
    // Implementation would query database for daily payout total
    return 0.0; // Placeholder
  }

  Future<List<WalletTransaction>> _getRecentTransactions(String userId, Duration period) async {
    // Implementation would query database for recent transactions
    return []; // Placeholder
  }

  Future<TransactionPatternAnalysis> _analyzeTransactionPattern(String userId, WalletTransaction transaction) async {
    // Implementation would analyze transaction patterns
    return TransactionPatternAnalysis(
      isUnusual: false,
      description: 'Normal transaction pattern',
      riskLevel: RiskLevel.low,
    );
  }

  double _calculateRiskScore(List<SuspiciousActivity> activities) {
    if (activities.isEmpty) return 0.0;
    
    final totalRisk = activities.fold(0.0, (sum, activity) {
      switch (activity.riskLevel) {
        case RiskLevel.low:
          return sum + 0.1;
        case RiskLevel.medium:
          return sum + 0.3;
        case RiskLevel.high:
          return sum + 0.6;
      }
    });
    
    return (totalRisk / activities.length).clamp(0.0, 1.0);
  }

  bool _isValidMalaysianBankAccount(String accountNumber, String bankName) {
    // Malaysian bank account validation logic
    final cleaned = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Basic validation - different banks have different formats
    final malayBanks = ['Maybank', 'CIMB', 'Public Bank', 'RHB', 'Hong Leong Bank'];
    final isRecognizedBank = malayBanks.any((bank) => 
        bankName.toLowerCase().contains(bank.toLowerCase()));
    
    return cleaned.length >= 8 && cleaned.length <= 20 && isRecognizedBank;
  }

  Future<List<WalletTransaction>> _getTransactionsForPeriod(DateTime start, DateTime end) async {
    // Implementation would query database
    return []; // Placeholder
  }

  Future<List<PayoutRequest>> _getPayoutsForPeriod(DateTime start, DateTime end) async {
    // Implementation would query database
    return []; // Placeholder
  }

  Future<List<SuspiciousActivity>> _getSuspiciousActivitiesForPeriod(DateTime start, DateTime end) async {
    // Implementation would query database
    return []; // Placeholder
  }

  Future<List<ComplianceViolation>> _getComplianceViolationsForPeriod(DateTime start, DateTime end) async {
    // Implementation would query database
    return []; // Placeholder
  }

  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'compliance_report_$timestamp';
  }
}

/// Provider for Malaysian compliance service
final malaysianComplianceServiceProvider = Provider<MalaysianComplianceService>((ref) {
  final logger = ref.watch(loggerProvider);
  return MalaysianComplianceService(logger);
});

// Data classes for compliance validation

class ComplianceValidationResult {
  final bool isCompliant;
  final List<ComplianceViolation> violations;
  final List<String> warnings;
  final bool requiresApproval;

  const ComplianceValidationResult({
    required this.isCompliant,
    required this.violations,
    required this.warnings,
    required this.requiresApproval,
  });
}

class ComplianceViolation {
  final String code;
  final String description;
  final String regulation;
  final ComplianceSeverity severity;

  const ComplianceViolation({
    required this.code,
    required this.description,
    required this.regulation,
    required this.severity,
  });
}

enum ComplianceSeverity { low, medium, high }

class AMLValidationResult {
  final bool isCompliant;
  final List<SuspiciousActivity> suspiciousActivities;
  final double riskScore;
  final bool requiresReporting;
  final bool requiresManualReview;

  const AMLValidationResult({
    required this.isCompliant,
    required this.suspiciousActivities,
    required this.riskScore,
    required this.requiresReporting,
    required this.requiresManualReview,
  });
}

class SuspiciousActivity {
  final SuspiciousActivityType type;
  final String description;
  final double amount;
  final RiskLevel riskLevel;
  final bool reportingRequired;

  const SuspiciousActivity({
    required this.type,
    required this.description,
    required this.amount,
    required this.riskLevel,
    required this.reportingRequired,
  });
}

enum SuspiciousActivityType {
  largeTransaction,
  rapidTransactions,
  unusualPattern,
  crossBorder,
}

enum RiskLevel { low, medium, high }

class PayoutComplianceResult {
  final bool isCompliant;
  final List<ComplianceViolation> violations;
  final List<ComplianceRequirement> requirements;
  final bool requiresApproval;

  const PayoutComplianceResult({
    required this.isCompliant,
    required this.violations,
    required this.requirements,
    required this.requiresApproval,
  });
}

class ComplianceRequirement {
  final String type;
  final String description;
  final bool mandatory;

  const ComplianceRequirement({
    required this.type,
    required this.description,
    required this.mandatory,
  });
}

class TransactionPatternAnalysis {
  final bool isUnusual;
  final String description;
  final RiskLevel riskLevel;

  const TransactionPatternAnalysis({
    required this.isUnusual,
    required this.description,
    required this.riskLevel,
  });
}

class ComplianceReport {
  final String id;
  final ComplianceReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final ComplianceReportSummary summary;
  final DateTime generatedAt;

  const ComplianceReport({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.generatedAt,
  });
}

enum ComplianceReportType { daily, weekly, monthly, quarterly, annual }

class ComplianceReportSummary {
  final int totalTransactions;
  final double totalTransactionAmount;
  final int totalPayouts;
  final double totalPayoutAmount;
  final List<SuspiciousActivity> suspiciousActivities;
  final List<ComplianceViolation> complianceViolations;

  const ComplianceReportSummary({
    required this.totalTransactions,
    required this.totalTransactionAmount,
    required this.totalPayouts,
    required this.totalPayoutAmount,
    required this.suspiciousActivities,
    required this.complianceViolations,
  });
}
