import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/user_management/presentation/providers/customer_profile_form_provider.dart';
import 'package:gigaeats_app/src/features/user_management/data/repositories/customer_profile_repository.dart';
import 'package:gigaeats_app/src/features/user_management/domain/customer_profile.dart';

import 'customer_profile_form_provider_test.mocks.dart';

@GenerateMocks([CustomerProfileRepository])
void main() {
  group('CustomerProfileFormProvider', () {
    late MockCustomerProfileRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockCustomerProfileRepository();
      container = ProviderContainer(
        overrides: [
          customerProfileRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be correct', () {
      final state = container.read(customerProfileFormProvider);
      
      expect(state.isLoading, false);
      expect(state.isSaving, false);
      expect(state.error, null);
      expect(state.fullName, '');
      expect(state.phoneNumber, '');
      expect(state.hasUnsavedChanges, false);
      expect(state.fieldErrors, {});
    });

    test('updateFullName should update state correctly', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      notifier.updateFullName('John Doe');
      
      final state = container.read(customerProfileFormProvider);
      expect(state.fullName, 'John Doe');
      expect(state.hasUnsavedChanges, true);
    });

    test('updatePhoneNumber should update state correctly', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      notifier.updatePhoneNumber('+60123456789');
      
      final state = container.read(customerProfileFormProvider);
      expect(state.phoneNumber, '+60123456789');
      expect(state.hasUnsavedChanges, true);
    });

    test('validateForm should return true for valid data', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      notifier.updateFullName('John Doe');
      notifier.updatePhoneNumber('+60123456789');
      
      final isValid = notifier.validateForm();
      
      expect(isValid, true);
      final state = container.read(customerProfileFormProvider);
      expect(state.fieldErrors, {});
    });

    test('validateForm should return false for invalid full name', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      notifier.updateFullName('J'); // Too short
      
      final isValid = notifier.validateForm();
      
      expect(isValid, false);
      final state = container.read(customerProfileFormProvider);
      expect(state.fieldErrors['fullName'], isNotNull);
    });

    test('validateForm should return false for invalid phone number', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      notifier.updateFullName('John Doe');
      notifier.updatePhoneNumber('invalid-phone'); // Invalid format
      
      final isValid = notifier.validateForm();
      
      expect(isValid, false);
      final state = container.read(customerProfileFormProvider);
      expect(state.fieldErrors['phoneNumber'], isNotNull);
    });

    test('clearFieldError should remove specific field error', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      // Create an error
      notifier.updateFullName('J'); // Too short
      notifier.validateForm();
      
      // Verify error exists
      var state = container.read(customerProfileFormProvider);
      expect(state.fieldErrors['fullName'], isNotNull);
      
      // Clear the error
      notifier.clearFieldError('fullName');
      
      // Verify error is cleared
      state = container.read(customerProfileFormProvider);
      expect(state.fieldErrors['fullName'], null);
    });

    test('resetForm should reset all fields to original values', () {
      // Create a mock profile
      final mockProfile = CustomerProfile(
        id: '1',
        userId: 'user1',
        fullName: 'Original Name',
        phoneNumber: '+60123456789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getCurrentProfile()).thenAnswer((_) async => mockProfile);

      final notifier = container.read(customerProfileFormProvider.notifier);
      
      // Initialize with mock data
      notifier.initialize();
      
      // Wait for initialization
      container.read(customerProfileFormProvider);
      
      // Make changes
      notifier.updateFullName('Changed Name');
      notifier.updatePhoneNumber('+60987654321');
      
      // Verify changes
      var state = container.read(customerProfileFormProvider);
      expect(state.hasUnsavedChanges, true);
      
      // Reset form
      notifier.resetForm();
      
      // Verify reset
      state = container.read(customerProfileFormProvider);
      expect(state.fullName, 'Original Name');
      expect(state.phoneNumber, '+60123456789');
      expect(state.hasUnsavedChanges, false);
    });

    test('getFieldError should return correct error message', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      // Create an error
      notifier.updateFullName('J'); // Too short
      notifier.validateForm();
      
      // Check error retrieval
      final error = notifier.getFieldError('fullName');
      expect(error, isNotNull);
      expect(error, contains('at least 2 characters'));
    });

    test('hasFieldError should return correct boolean', () {
      final notifier = container.read(customerProfileFormProvider.notifier);
      
      // Initially no errors
      expect(notifier.hasFieldError('fullName'), false);
      
      // Create an error
      notifier.updateFullName('J'); // Too short
      notifier.validateForm();
      
      // Check error existence
      expect(notifier.hasFieldError('fullName'), true);
      expect(notifier.hasFieldError('phoneNumber'), false);
    });
  });
}
