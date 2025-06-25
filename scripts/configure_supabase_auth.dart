import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Script to configure Supabase authentication settings for email verification
/// This script updates the redirect URLs and email templates in Supabase
void main() async {
  const projectRef = 'abknoalhfltlhhdbclpv';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM0MjE5MSwiZXhwIjoyMDYzOTE4MTkxfQ.c9U38XFDf8f4ngCNDp2XlSOLSlIaPI-Utg1GgaHwmSY';
  
  debugPrint('🔧 Configuring Supabase authentication settings...');
  
  try {
    // Configure redirect URLs
    await configureRedirectUrls(projectRef, serviceKey);
    
    // Configure email templates
    await configureEmailTemplates(projectRef, serviceKey);
    
    debugPrint('✅ Supabase authentication configuration completed successfully!');
  } catch (e) {
    debugPrint('❌ Error configuring Supabase: $e');
    exit(1);
  }
}

/// Configure redirect URLs for the project
Future<void> configureRedirectUrls(String projectRef, String serviceKey) async {
  debugPrint('📱 Configuring redirect URLs...');
  
  final redirectUrls = [
    'gigaeats://auth/callback',
    'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback',
    'http://localhost:3000/auth/callback',
    'https://localhost:3000/auth/callback',
  ];
  
  final url = 'https://api.supabase.com/v1/projects/$projectRef/config/auth';
  
  final response = await http.patch(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $serviceKey',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'SITE_URL': 'gigaeats://auth/callback',
      'ADDITIONAL_REDIRECT_URLS': redirectUrls.join(','),
    }),
  );
  
  if (response.statusCode == 200) {
    debugPrint('✅ Redirect URLs configured successfully');
  } else {
    debugPrint('❌ Failed to configure redirect URLs: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to configure redirect URLs');
  }
}

/// Configure email templates
Future<void> configureEmailTemplates(String projectRef, String serviceKey) async {
  debugPrint('📧 Configuring email templates...');
  
  final url = 'https://api.supabase.com/v1/projects/$projectRef/config/auth';
  
  final emailTemplate = '''
<h2>Confirm your signup</h2>
<p>Follow this link to confirm your user:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your mail</a></p>
<p>If the button doesn't work, copy and paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
''';
  
  final response = await http.patch(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $serviceKey',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'MAILER_TEMPLATES_CONFIRMATION_CONTENT': emailTemplate,
      'MAILER_URLPATHS_CONFIRMATION': '/auth/v1/verify?token={{ .TokenHash }}&type=signup',
    }),
  );
  
  if (response.statusCode == 200) {
    debugPrint('✅ Email templates configured successfully');
  } else {
    debugPrint('❌ Failed to configure email templates: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to configure email templates');
  }
}
