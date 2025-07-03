import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/core/utils/profile_validators.dart';

void main() {
  group('ProfileValidators - Malaysian Address Validation', () {
    group('validateMalaysianPostcode', () {
      test('should accept valid 5-digit postal codes', () {
        expect(ProfileValidators.validateMalaysianPostcode('50450'), isNull);
        expect(ProfileValidators.validateMalaysianPostcode('10200'), isNull);
        expect(ProfileValidators.validateMalaysianPostcode('40000'), isNull);
        expect(ProfileValidators.validateMalaysianPostcode('88000'), isNull);
        expect(ProfileValidators.validateMalaysianPostcode('01000'), isNull);
      });

      test('should reject invalid postal codes', () {
        expect(ProfileValidators.validateMalaysianPostcode(''), isNotNull);
        expect(ProfileValidators.validateMalaysianPostcode('1234'), isNotNull);
        expect(ProfileValidators.validateMalaysianPostcode('123456'), isNotNull);
        expect(ProfileValidators.validateMalaysianPostcode('abcde'), isNotNull);
        expect(ProfileValidators.validateMalaysianPostcode('1234a'), isNotNull);
        expect(ProfileValidators.validateMalaysianPostcode('12-34'), isNotNull);
      });

      test('should handle null input', () {
        expect(ProfileValidators.validateMalaysianPostcode(null), isNotNull);
      });
    });

    group('validateState', () {
      test('should accept valid Malaysian states', () {
        expect(ProfileValidators.validateState('Selangor'), isNull);
        expect(ProfileValidators.validateState('Kuala Lumpur'), isNull);
        expect(ProfileValidators.validateState('Johor'), isNull);
        expect(ProfileValidators.validateState('Penang'), isNull);
        expect(ProfileValidators.validateState('Sabah'), isNull);
        expect(ProfileValidators.validateState('Sarawak'), isNull);
        expect(ProfileValidators.validateState('Putrajaya'), isNull);
        expect(ProfileValidators.validateState('Labuan'), isNull);
      });

      test('should reject invalid states', () {
        expect(ProfileValidators.validateState(''), isNotNull);
        expect(ProfileValidators.validateState('California'), isNotNull);
        expect(ProfileValidators.validateState('New York'), isNotNull);
        expect(ProfileValidators.validateState('Invalid State'), isNotNull);
      });

      test('should handle null input', () {
        expect(ProfileValidators.validateState(null), isNotNull);
      });
    });

    group('validateCity', () {
      test('should accept valid city names', () {
        expect(ProfileValidators.validateCity('Kuala Lumpur'), isNull);
        expect(ProfileValidators.validateCity('Shah Alam'), isNull);
        expect(ProfileValidators.validateCity('Johor Bahru'), isNull);
        expect(ProfileValidators.validateCity('Kota Kinabalu'), isNull);
        expect(ProfileValidators.validateCity('Alor Setar'), isNull);
        expect(ProfileValidators.validateCity('Ipoh'), isNull);
        expect(ProfileValidators.validateCity('Melaka'), isNull);
      });

      test('should reject invalid city names', () {
        expect(ProfileValidators.validateCity(''), isNotNull);
        expect(ProfileValidators.validateCity('A'), isNotNull); // Too short
        expect(ProfileValidators.validateCity('City123'), isNotNull); // Contains numbers
        expect(ProfileValidators.validateCity('City@Name'), isNotNull); // Contains special chars
        expect(ProfileValidators.validateCity('A' * 51), isNotNull); // Too long
      });

      test('should handle null input', () {
        expect(ProfileValidators.validateCity(null), isNotNull);
      });
    });

    group('validateAddress', () {
      test('should accept valid addresses', () {
        expect(ProfileValidators.validateAddress('123 Jalan Bukit Bintang'), isNull);
        expect(ProfileValidators.validateAddress('No. 45, Jalan Sultan Ismail'), isNull);
        expect(ProfileValidators.validateAddress('Lot 123, Jalan Ampang, Taman Desa'), isNull);
        expect(ProfileValidators.validateAddress('Block A, Apartment Vista'), isNull);
      });

      test('should reject invalid addresses', () {
        expect(ProfileValidators.validateAddress(''), isNotNull);
        expect(ProfileValidators.validateAddress('Short'), isNotNull); // Too short
        expect(ProfileValidators.validateAddress('A' * 201), isNotNull); // Too long
      });

      test('should handle optional addresses', () {
        expect(ProfileValidators.validateAddress('', required: false), isNull);
        expect(ProfileValidators.validateAddress(null, required: false), isNull);
      });

      test('should handle null input', () {
        expect(ProfileValidators.validateAddress(null), isNotNull);
      });
    });

    group('Malaysian States List', () {
      test('should contain all 16 Malaysian states and territories', () {
        const expectedStates = [
          'Johor', 'Kedah', 'Kelantan', 'Malacca', 'Negeri Sembilan',
          'Pahang', 'Penang', 'Perak', 'Perlis', 'Sabah', 'Sarawak',
          'Selangor', 'Terengganu', 'Kuala Lumpur', 'Labuan', 'Putrajaya'
        ];

        for (final state in expectedStates) {
          expect(ProfileValidators.validateState(state), isNull,
              reason: 'State $state should be valid');
        }
      });
    });

    group('Edge Cases', () {
      test('should handle whitespace in inputs', () {
        expect(ProfileValidators.validateMalaysianPostcode(' 50450 '), isNull);
        expect(ProfileValidators.validateState(' Selangor '), isNull);
        expect(ProfileValidators.validateCity(' Kuala Lumpur '), isNull);
        expect(ProfileValidators.validateAddress(' 123 Jalan Test '), isNull);
      });

      test('should handle case sensitivity', () {
        // State validation is case-insensitive (good UX)
        expect(ProfileValidators.validateState('selangor'), isNull);
        expect(ProfileValidators.validateState('SELANGOR'), isNull);
        // City validation allows different cases
        expect(ProfileValidators.validateCity('kuala lumpur'), isNull);
        expect(ProfileValidators.validateCity('KUALA LUMPUR'), isNull);
      });
    });
  });

  group('ProfileValidators - General Validation', () {
    group('validateEmail', () {
      test('should accept valid email addresses', () {
        expect(ProfileValidators.validateEmail('test@example.com'), isNull);
        expect(ProfileValidators.validateEmail('user.name@domain.co.uk'), isNull);
        expect(ProfileValidators.validateEmail('test+tag@example.org'), isNull);
      });

      test('should reject invalid email addresses', () {
        expect(ProfileValidators.validateEmail(''), isNotNull);
        expect(ProfileValidators.validateEmail('invalid-email'), isNotNull);
        expect(ProfileValidators.validateEmail('@domain.com'), isNotNull);
        expect(ProfileValidators.validateEmail('test@'), isNotNull);
      });
    });

    group('validateMalaysianPhoneNumber', () {
      test('should accept valid Malaysian phone numbers', () {
        expect(ProfileValidators.validateMalaysianPhoneNumber('0123456789'), isNull);
        expect(ProfileValidators.validateMalaysianPhoneNumber('01234567890'), isNull);
        expect(ProfileValidators.validateMalaysianPhoneNumber('+60123456789'), isNull);
      });

      test('should reject invalid phone numbers', () {
        expect(ProfileValidators.validateMalaysianPhoneNumber(''), isNotNull);
        expect(ProfileValidators.validateMalaysianPhoneNumber('123'), isNotNull);
        expect(ProfileValidators.validateMalaysianPhoneNumber('abcdefghij'), isNotNull);
      });
    });

    group('validateFullName', () {
      test('should accept valid names', () {
        expect(ProfileValidators.validateFullName('John Doe'), isNull);
        expect(ProfileValidators.validateFullName('Ahmad bin Abdullah'), isNull);
        expect(ProfileValidators.validateFullName('Siti Nurhaliza'), isNull);
      });

      test('should reject invalid names', () {
        expect(ProfileValidators.validateFullName(''), isNotNull);
        expect(ProfileValidators.validateFullName('A'), isNotNull);
        expect(ProfileValidators.validateFullName('Name123'), isNotNull);
      });
    });
  });
}
