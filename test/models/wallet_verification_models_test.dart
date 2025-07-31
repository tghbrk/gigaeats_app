import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/data/models/wallet_verification_models.dart';

void main() {
  group('Wallet Verification Models', () {
    group('WalletVerificationRequest', () {
      test('should create instance with required fields', () {
        final request = WalletVerificationRequest(
          id: 'test-id',
          userId: 'user-id',
          walletId: 'wallet-id',
          method: WalletVerificationMethod.documentUpload,
          status: WalletVerificationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(request.id, 'test-id');
        expect(request.method, WalletVerificationMethod.documentUpload);
        expect(request.status, WalletVerificationStatus.pending);
      });

      test('should serialize to and from JSON', () {
        final now = DateTime.now();
        final request = WalletVerificationRequest(
          id: 'test-id',
          userId: 'user-id',
          walletId: 'wallet-id',
          method: WalletVerificationMethod.documentUpload,
          status: WalletVerificationStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final json = request.toJson();
        final fromJson = WalletVerificationRequest.fromJson(json);

        expect(fromJson.id, request.id);
        expect(fromJson.method, request.method);
        expect(fromJson.status, request.status);
      });

      test('should check if request is expired', () {
        final expiredRequest = WalletVerificationRequest(
          id: 'test-id',
          userId: 'user-id',
          walletId: 'wallet-id',
          method: WalletVerificationMethod.documentUpload,
          status: WalletVerificationStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(expiredRequest.isExpired, true);

        final activeRequest = WalletVerificationRequest(
          id: 'test-id',
          userId: 'user-id',
          walletId: 'wallet-id',
          method: WalletVerificationMethod.documentUpload,
          status: WalletVerificationStatus.pending,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(activeRequest.isExpired, false);
      });
    });

    group('WalletVerificationDocument', () {
      test('should create instance with required fields', () {
        final document = WalletVerificationDocument(
          id: 'doc-id',
          verificationRequestId: 'request-id',
          userId: 'user-id',
          documentType: DocumentType.icCard,
          fileName: 'ic_front.jpg',
          filePath: '/path/to/file.jpg',
          mimeType: 'image/jpeg',
          fileSize: 1024000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(document.documentType, DocumentType.icCard);
        expect(document.fileName, 'ic_front.jpg');
        expect(document.isImage, true);
        expect(document.isPdf, false);
      });

      test('should format file size correctly', () {
        final smallDoc = WalletVerificationDocument(
          id: 'doc-id',
          verificationRequestId: 'request-id',
          userId: 'user-id',
          documentType: DocumentType.icCard,
          fileName: 'small.jpg',
          filePath: '/path/to/small.jpg',
          mimeType: 'image/jpeg',
          fileSize: 512,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(smallDoc.formattedFileSize, '512 B');

        final largeDoc = WalletVerificationDocument(
          id: 'doc-id',
          verificationRequestId: 'request-id',
          userId: 'user-id',
          documentType: DocumentType.icCard,
          fileName: 'large.jpg',
          filePath: '/path/to/large.jpg',
          mimeType: 'image/jpeg',
          fileSize: 2048000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(largeDoc.formattedFileSize, '2.0 MB');
      });
    });

    group('DocumentUploadProgress', () {
      test('should create instance and calculate progress percentage', () {
        final progress = DocumentUploadProgress(
          id: 'progress-id',
          verificationRequestId: 'request-id',
          documentType: DocumentType.icCard,
          fileName: 'ic_front.jpg',
          localFilePath: '/local/path.jpg',
          status: DocumentUploadStatus.uploading,
          progress: 0.75,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(progress.progressPercentage, 75);
        expect(progress.progressText, '75%');
        expect(progress.status.isActive, true);
      });

      test('should calculate upload speed', () {
        final startTime = DateTime.now().subtract(const Duration(seconds: 10));
        final progress = DocumentUploadProgress(
          id: 'progress-id',
          verificationRequestId: 'request-id',
          documentType: DocumentType.icCard,
          fileName: 'ic_front.jpg',
          localFilePath: '/local/path.jpg',
          status: DocumentUploadStatus.uploading,
          progress: 0.5,
          totalBytes: 1024000,
          uploadedBytes: 512000,
          startedAt: startTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final speed = progress.uploadSpeedBytesPerSecond;
        expect(speed, isNotNull);
        expect(speed! > 0, true);
      });
    });

    group('InstantVerificationRequest', () {
      test('should create instance and mask sensitive data', () {
        final request = InstantVerificationRequest(
          id: 'instant-id',
          verificationRequestId: 'request-id',
          userId: 'user-id',
          icNumber: '123456789012',
          fullName: 'John Doe',
          phoneNumber: '0123456789',
          status: InstantVerificationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(request.maskedIcNumber, '123456******');
        expect(request.maskedPhoneNumber, '012345****');
      });

      test('should check confidence levels', () {
        final highConfidenceRequest = InstantVerificationRequest(
          id: 'instant-id',
          verificationRequestId: 'request-id',
          userId: 'user-id',
          icNumber: '123456789012',
          fullName: 'John Doe',
          phoneNumber: '0123456789',
          status: InstantVerificationStatus.verified,
          confidenceScore: 0.95,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(highConfidenceRequest.hasHighConfidence, true);
        expect(highConfidenceRequest.hasMediumConfidence, false);
        expect(highConfidenceRequest.hasLowConfidence, false);
        expect(highConfidenceRequest.confidencePercentage, 95);
      });
    });

    group('WalletVerificationState', () {
      test('should track document completion progress', () {
        final state = WalletVerificationState(
          requiredDocuments: {
            DocumentType.icCard: true,
            DocumentType.selfie: true,
            DocumentType.utilityBill: true,
          },
          completedDocuments: {
            DocumentType.icCard: true,
            DocumentType.selfie: true,
            DocumentType.utilityBill: false,
          },
        );

        expect(state.totalRequiredDocuments, 3);
        expect(state.totalCompletedDocuments, 2);
        expect(state.documentCompletionPercentage, 67);
        expect(state.allRequiredDocumentsCompleted, false);
      });

      test('should check verification status', () {
        final pendingState = WalletVerificationState(
          currentRequest: WalletVerificationRequest(
            id: 'request-id',
            userId: 'user-id',
            walletId: 'wallet-id',
            method: WalletVerificationMethod.documentUpload,
            status: WalletVerificationStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(pendingState.hasActiveRequest, true);
        expect(pendingState.isVerificationCompleted, false);
        expect(pendingState.isVerificationPending, true);
        expect(pendingState.canStartNewVerification, false);
      });
    });

    group('Validation', () {
      test('should validate instant verification form', () {
        final validResult = WalletVerificationValidator.validateInstantVerificationForm(
          icNumber: '123456789012',
          fullName: 'John Doe',
          phoneNumber: '0123456789',
          agreedToTerms: true,
        );

        expect(validResult.isValid, true);
        expect(validResult.errors, isEmpty);

        final invalidResult = WalletVerificationValidator.validateInstantVerificationForm(
          icNumber: '12345', // Too short
          fullName: '', // Empty
          phoneNumber: '123', // Too short
          agreedToTerms: false, // Not agreed
        );

        expect(invalidResult.isValid, false);
        expect(invalidResult.errors.length, greaterThan(0));
      });
    });
  });
}
