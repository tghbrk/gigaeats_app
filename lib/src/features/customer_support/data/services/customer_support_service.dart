import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket.dart';
import '../models/support_message.dart';
import '../models/faq_item.dart';
import '../models/support_category.dart';
import '../../../../core/utils/logger.dart';

/// Customer support service for managing tickets, chat, and FAQ
class CustomerSupportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Get all support categories
  Future<List<SupportCategory>> getSupportCategories() async {
    try {
      _logger.info('CustomerSupportService: Getting support categories');

      final response = await _supabase
          .from('support_categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      return response.map<SupportCategory>((data) => SupportCategory.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerSupportService: Error getting support categories', e);
      rethrow;
    }
  }

  /// Get all FAQ categories with items
  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      _logger.info('CustomerSupportService: Getting FAQ categories');

      final response = await _supabase
          .from('faq_categories')
          .select('''
            *,
            faq_items!inner(*)
          ''')
          .eq('is_active', true)
          .eq('faq_items.is_active', true)
          .order('sort_order');

      return response.map<FAQCategory>((data) => FAQCategory.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerSupportService: Error getting FAQ categories', e);
      rethrow;
    }
  }

  /// Search FAQ items
  Future<List<FAQItem>> searchFAQ(String query) async {
    try {
      _logger.info('CustomerSupportService: Searching FAQ with query: $query');

      final response = await _supabase
          .from('faq_items')
          .select('''
            *,
            faq_categories!inner(name)
          ''')
          .eq('is_active', true)
          .or('question.ilike.%$query%,answer.ilike.%$query%,keywords.cs.{$query}')
          .order('helpful_count', ascending: false)
          .limit(20);

      return response.map<FAQItem>((data) => FAQItem.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerSupportService: Error searching FAQ', e);
      rethrow;
    }
  }

  /// Create a new support ticket
  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String description,
    required String categoryId,
    String? orderId,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('CustomerSupportService: Creating support ticket');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('support_tickets')
          .insert({
            'customer_id': user.id,
            'category_id': categoryId,
            'order_id': orderId,
            'subject': subject,
            'description': description,
            'customer_email': customerEmail,
            'customer_phone': customerPhone,
            'metadata': metadata ?? {},
          })
          .select('''
            *,
            support_categories(name, icon),
            orders(order_number, vendor_name)
          ''')
          .single();

      _logger.info('CustomerSupportService: Support ticket created successfully');
      return SupportTicket.fromJson(response);
    } catch (e) {
      _logger.error('CustomerSupportService: Error creating support ticket', e);
      rethrow;
    }
  }

  /// Get customer's support tickets
  Future<List<SupportTicket>> getCustomerTickets() async {
    try {
      _logger.info('CustomerSupportService: Getting customer tickets');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('support_tickets')
          .select('''
            *,
            support_categories(name, icon),
            orders(order_number, vendor_name)
          ''')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      return response.map<SupportTicket>((data) => SupportTicket.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerSupportService: Error getting customer tickets', e);
      rethrow;
    }
  }

  /// Get support ticket details
  Future<SupportTicket> getTicketDetails(String ticketId) async {
    try {
      _logger.info('CustomerSupportService: Getting ticket details for $ticketId');

      final response = await _supabase
          .from('support_tickets')
          .select('''
            *,
            support_categories(name, icon),
            orders(order_number, vendor_name)
          ''')
          .eq('id', ticketId)
          .single();

      return SupportTicket.fromJson(response);
    } catch (e) {
      _logger.error('CustomerSupportService: Error getting ticket details', e);
      rethrow;
    }
  }

  /// Get messages for a support ticket
  Future<List<SupportMessage>> getTicketMessages(String ticketId) async {
    try {
      _logger.info('CustomerSupportService: Getting messages for ticket $ticketId');

      final response = await _supabase
          .from('support_messages')
          .select('''
            *,
            users!sender_id(
              id,
              email,
              raw_user_meta_data
            )
          ''')
          .eq('ticket_id', ticketId)
          .eq('is_internal', false) // Only show non-internal messages to customers
          .order('created_at');

      return response.map<SupportMessage>((data) => SupportMessage.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerSupportService: Error getting ticket messages', e);
      rethrow;
    }
  }

  /// Send a message in a support ticket
  Future<SupportMessage> sendTicketMessage({
    required String ticketId,
    required String content,
    String messageType = 'text',
    List<String>? attachments,
  }) async {
    try {
      _logger.info('CustomerSupportService: Sending message to ticket $ticketId');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('support_messages')
          .insert({
            'ticket_id': ticketId,
            'sender_id': user.id,
            'sender_type': 'customer',
            'message_type': messageType,
            'content': content,
            'attachments': attachments ?? [],
          })
          .select('''
            *,
            users!sender_id(
              id,
              email,
              raw_user_meta_data
            )
          ''')
          .single();

      // Update ticket status to indicate customer response
      await _supabase
          .from('support_tickets')
          .update({
            'status': 'open',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);

      _logger.info('CustomerSupportService: Message sent successfully');
      return SupportMessage.fromJson(response);
    } catch (e) {
      _logger.error('CustomerSupportService: Error sending message', e);
      rethrow;
    }
  }

  /// Stream real-time messages for a ticket
  Stream<List<SupportMessage>> streamTicketMessages(String ticketId) {
    _logger.info('CustomerSupportService: Starting real-time message stream for ticket $ticketId');

    // TODO: Fix Supabase stream API - .eq() method issue
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        // .eq('ticket_id', ticketId)
        // .eq('is_internal', false)
        .order('created_at')
        .asyncMap((data) async {
          // Fetch user details for each message
          final messages = <SupportMessage>[];
          for (final messageData in data) {
            try {
              final userResponse = await _supabase
                  .from('users')
                  .select('id, email, raw_user_meta_data')
                  .eq('id', messageData['sender_id'])
                  .single();
              
              messageData['users'] = userResponse;
              messages.add(SupportMessage.fromJson(messageData));
            } catch (e) {
              _logger.error('CustomerSupportService: Error fetching user for message', e);
              // Add message without user details
              messages.add(SupportMessage.fromJson(messageData));
            }
          }
          return messages;
        });
  }

  /// Submit feedback for a support ticket
  Future<void> submitTicketFeedback({
    required String ticketId,
    required int rating,
    String? feedbackText,
  }) async {
    try {
      _logger.info('CustomerSupportService: Submitting feedback for ticket $ticketId');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('support_feedback')
          .insert({
            'ticket_id': ticketId,
            'customer_id': user.id,
            'rating': rating,
            'feedback_text': feedbackText,
          });

      _logger.info('CustomerSupportService: Feedback submitted successfully');
    } catch (e) {
      _logger.error('CustomerSupportService: Error submitting feedback', e);
      rethrow;
    }
  }

  /// Mark FAQ item as helpful
  Future<void> markFAQHelpful(String faqItemId, bool isHelpful) async {
    try {
      _logger.info('CustomerSupportService: Marking FAQ item as ${isHelpful ? 'helpful' : 'not helpful'}');

      final column = isHelpful ? 'helpful_count' : 'not_helpful_count';
      
      await _supabase.rpc('increment_faq_count', params: {
        'faq_id': faqItemId,
        'column_name': column,
      });

      _logger.info('CustomerSupportService: FAQ feedback recorded');
    } catch (e) {
      _logger.error('CustomerSupportService: Error recording FAQ feedback', e);
      rethrow;
    }
  }

  /// Get emergency contact information
  Map<String, dynamic> getEmergencyContacts() {
    return {
      'phone': '+60 3-1234 5678',
      'email': 'support@gigaeats.com',
      'whatsapp': '+60 12-345 6789',
      'hours': 'Available 24/7 for urgent issues',
      'response_time': 'Within 15 minutes for urgent matters',
    };
  }
}
