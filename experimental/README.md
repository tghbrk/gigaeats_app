# Experimental Directory

This directory contains experimental test files, prototypes, and development utilities for the GigaEats Flutter application.

## Contents

### HTML Test Files
- **`test_auth.html`** - Authentication testing interface
- **`test_flutter_auth.html`** - Flutter-specific authentication tests
- **`test_signin.html`** - Sign-in functionality testing
- **`test_signup_fix.html`** - Sign-up functionality testing and fixes

### Dart Test Files
- **`test_database_connection.dart`** - Database connectivity testing
- **`test_order_functionality.dart`** - Order management functionality tests
- **`test_vendors_fix.dart`** - Vendor-related functionality testing

### Documentation
- **`test_delivery_proof_workflow.md`** - Delivery proof system testing workflow

## Purpose

These files are used for:
- **Rapid Prototyping**: Quick testing of new features
- **Debugging**: Isolated testing of specific functionality
- **Development**: Experimental implementations before integration
- **Testing**: Manual and automated testing scenarios

## Usage Guidelines

⚠️ **Important Notes:**
- Files in this directory are **experimental** and may not be production-ready
- These files are **not included** in the main application build
- Use these files for **development and testing purposes only**
- Some files may have **hardcoded values** or **test credentials**

## Security Considerations

- **Never commit real credentials** to these test files
- Use **test/development environments** only
- **Review and sanitize** before sharing or deploying
- **Remove sensitive data** before committing changes

## Integration

When experimental features are ready for production:
1. **Review and refactor** the experimental code
2. **Move to appropriate feature modules** in `lib/features/`
3. **Update imports and dependencies**
4. **Add proper error handling and validation**
5. **Write unit and integration tests**
6. **Update documentation**

## Cleanup

Periodically review and clean up this directory:
- Remove **obsolete test files**
- Archive **completed experiments**
- Update **documentation** as needed
- Ensure **no sensitive data** remains
