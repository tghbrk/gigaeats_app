import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/driver_workflow_notification_templates.dart';

/// Service to initialize notification templates for the driver workflow
/// This ensures all required templates are available in the database
class NotificationTemplateInitializationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize all driver workflow notification templates
  Future<void> initializeDriverWorkflowTemplates() async {
    try {
      debugPrint('📧 [TEMPLATE-INIT] Initializing driver workflow notification templates');

      final templates = DriverWorkflowNotificationTemplates.getAllTemplates();
      int successCount = 0;
      int skipCount = 0;
      int errorCount = 0;

      for (final template in templates) {
        try {
          final result = await _createOrUpdateTemplate(template);
          if (result) {
            successCount++;
          } else {
            skipCount++;
          }
        } catch (e) {
          errorCount++;
          debugPrint('❌ [TEMPLATE-INIT] Failed to create template ${template['template_key']}: $e');
        }
      }

      debugPrint('✅ [TEMPLATE-INIT] Template initialization complete:');
      debugPrint('   - Created/Updated: $successCount');
      debugPrint('   - Skipped (existing): $skipCount');
      debugPrint('   - Errors: $errorCount');

    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to initialize templates: $e');
      rethrow;
    }
  }

  /// Create or update a notification template
  Future<bool> _createOrUpdateTemplate(Map<String, dynamic> templateData) async {
    try {
      final templateKey = templateData['template_key'];

      // Check if template already exists
      final existingTemplate = await _supabase
          .from('notification_templates')
          .select('id, updated_at')
          .eq('template_key', templateKey)
          .limit(1);

      if (existingTemplate.isNotEmpty) {
        // Template exists, update it
        await _supabase
            .from('notification_templates')
            .update({
              ...templateData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('template_key', templateKey);

        debugPrint('🔄 [TEMPLATE-INIT] Updated template: $templateKey');
        return true;
      } else {
        // Template doesn't exist, create it
        await _supabase
            .from('notification_templates')
            .insert({
              ...templateData,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

        debugPrint('✅ [TEMPLATE-INIT] Created template: $templateKey');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Error with template ${templateData['template_key']}: $e');
      return false;
    }
  }

  /// Validate that all required templates exist
  Future<bool> validateTemplatesExist() async {
    try {
      final requiredTemplates = DriverWorkflowNotificationTemplates.getAllTemplates()
          .map((t) => t['template_key'] as String)
          .toList();

      final existingTemplates = await _supabase
          .from('notification_templates')
          .select('template_key')
          .inFilter('template_key', requiredTemplates);

      final existingKeys = existingTemplates
          .map((t) => t['template_key'] as String)
          .toSet();

      final missingTemplates = requiredTemplates
          .where((key) => !existingKeys.contains(key))
          .toList();

      if (missingTemplates.isNotEmpty) {
        debugPrint('⚠️ [TEMPLATE-INIT] Missing templates: $missingTemplates');
        return false;
      }

      debugPrint('✅ [TEMPLATE-INIT] All required templates exist');
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to validate templates: $e');
      return false;
    }
  }

  /// Get template by key
  Future<Map<String, dynamic>?> getTemplate(String templateKey) async {
    try {
      final response = await _supabase
          .from('notification_templates')
          .select('*')
          .eq('template_key', templateKey)
          .eq('is_active', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to get template $templateKey: $e');
      return null;
    }
  }

  /// Test template rendering with sample variables
  Future<Map<String, String>?> testTemplateRendering(
    String templateKey,
    Map<String, dynamic> variables,
  ) async {
    try {
      final template = await getTemplate(templateKey);
      if (template == null) {
        debugPrint('❌ [TEMPLATE-INIT] Template not found: $templateKey');
        return null;
      }

      String title = template['title_template'] as String;
      String message = template['message_template'] as String;

      // Simple variable substitution
      variables.forEach((key, value) {
        title = title.replaceAll('{{$key}}', value.toString());
        message = message.replaceAll('{{$key}}', value.toString());
      });

      return {
        'title': title,
        'message': message,
      };
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to test template rendering: $e');
      return null;
    }
  }

  /// Initialize templates on app startup (call this during app initialization)
  static Future<void> initializeOnStartup() async {
    try {
      final service = NotificationTemplateInitializationService();
      
      // Check if templates exist
      final templatesExist = await service.validateTemplatesExist();
      
      if (!templatesExist) {
        debugPrint('📧 [TEMPLATE-INIT] Templates missing, initializing...');
        await service.initializeDriverWorkflowTemplates();
      } else {
        debugPrint('✅ [TEMPLATE-INIT] All templates already exist');
      }
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to initialize on startup: $e');
      // Don't fail app startup if template initialization fails
    }
  }

  /// Test all templates with sample data
  Future<void> testAllTemplates() async {
    try {
      debugPrint('🧪 [TEMPLATE-INIT] Testing all templates...');

      final sampleVariables = {
        'order_id': 'ORD-12345',
        'vendor_name': 'Test Restaurant',
        'vendor_address': '123 Test Street, Kuala Lumpur',
        'delivery_address': '456 Customer Street, Kuala Lumpur',
        'total_amount': '25.50',
      };

      final templates = DriverWorkflowNotificationTemplates.getAllTemplates();
      
      for (final template in templates) {
        final templateKey = template['template_key'] as String;
        final result = await testTemplateRendering(templateKey, sampleVariables);
        
        if (result != null) {
          debugPrint('✅ [TEMPLATE-INIT] $templateKey: ${result['title']} - ${result['message']}');
        } else {
          debugPrint('❌ [TEMPLATE-INIT] Failed to test template: $templateKey');
        }
      }

      debugPrint('🧪 [TEMPLATE-INIT] Template testing complete');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INIT] Failed to test templates: $e');
    }
  }
}

/// Provider for notification template initialization service
final notificationTemplateInitializationServiceProvider = Provider<NotificationTemplateInitializationService>((ref) {
  return NotificationTemplateInitializationService();
});
