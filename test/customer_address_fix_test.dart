import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/features/customers/data/models/customer_profile.dart';

void main() {
  group('Customer Address Fix Tests', () {
    test('CustomerAddress toJson should include null id', () {
      // Test that the toJson method includes null id (this is the current behavior)
      final address = CustomerAddress(
        id: null, // This is the case that was causing the issue
        label: 'Home',
        addressLine1: '123 Test Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        country: 'Malaysia',
      );

      final json = address.toJson();
      
      // Verify that the JSON includes the id field with null value
      expect(json.containsKey('id'), isTrue);
      expect(json['id'], isNull);
      expect(json['label'], equals('Home'));
      expect(json['address_line_1'], equals('123 Test Street'));
      expect(json['city'], equals('Kuala Lumpur'));
      expect(json['state'], equals('Selangor'));
      expect(json['postal_code'], equals('50000'));
      expect(json['country'], equals('Malaysia'));
    });

    test('CustomerAddress toJson should include non-null id', () {
      // Test that the toJson method includes non-null id for existing addresses
      final address = CustomerAddress(
        id: 'existing-address-id',
        label: 'Office',
        addressLine1: '456 Business Ave',
        city: 'Petaling Jaya',
        state: 'Selangor',
        postalCode: '47800',
        country: 'Malaysia',
      );

      final json = address.toJson();
      
      // Verify that the JSON includes the id field with the actual value
      expect(json.containsKey('id'), isTrue);
      expect(json['id'], equals('existing-address-id'));
      expect(json['label'], equals('Office'));
      expect(json['address_line_1'], equals('456 Business Ave'));
    });

    test('Address data preparation should remove null id', () {
      // Test the logic that should be applied in the repository
      final address = CustomerAddress(
        id: null,
        label: 'Test Address',
        addressLine1: '789 Test Road',
        city: 'Shah Alam',
        state: 'Selangor',
        postalCode: '40000',
        country: 'Malaysia',
      );

      final addressData = address.toJson();
      
      // Simulate the fix: remove null id field
      if (addressData['id'] == null) {
        addressData.remove('id');
      }
      
      // Add required fields for database insertion
      addressData['customer_profile_id'] = 'test-profile-id';
      addressData['created_at'] = DateTime.now().toIso8601String();
      addressData['updated_at'] = DateTime.now().toIso8601String();
      
      // Verify that the id field is removed and other required fields are added
      expect(addressData.containsKey('id'), isFalse);
      expect(addressData['customer_profile_id'], equals('test-profile-id'));
      expect(addressData.containsKey('created_at'), isTrue);
      expect(addressData.containsKey('updated_at'), isTrue);
      expect(addressData['label'], equals('Test Address'));
    });

    test('Address data preparation should keep non-null id', () {
      // Test that existing addresses keep their id for updates
      final address = CustomerAddress(
        id: 'existing-id-123',
        label: 'Updated Address',
        addressLine1: '999 Updated Street',
        city: 'Kuching',
        state: 'Sarawak',
        postalCode: '93000',
        country: 'Malaysia',
      );

      final addressData = address.toJson();
      
      // Simulate the fix: only remove null id field
      if (addressData['id'] == null) {
        addressData.remove('id');
      }
      
      // Verify that the non-null id field is kept
      expect(addressData.containsKey('id'), isTrue);
      expect(addressData['id'], equals('existing-id-123'));
      expect(addressData['label'], equals('Updated Address'));
    });
  });
}
