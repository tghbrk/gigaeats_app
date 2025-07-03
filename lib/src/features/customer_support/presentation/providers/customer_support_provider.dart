import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/customer_support_service.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/support_message.dart';
import '../../data/models/faq_item.dart';
import '../../data/models/support_category.dart';
import '../../../../core/utils/logger.dart';

/// Provider for CustomerSupportService
final customerSupportServiceProvider = Provider<CustomerSupportService>((ref) {
  return CustomerSupportService();
});

/// State for customer support
class CustomerSupportState {
  final List<SupportTicket> tickets;
  final List<SupportCategory> categories;
  final List<FAQCategory> faqCategories;
  final List<FAQItem> searchResults;
  final bool isLoading;
  final String? error;

  const CustomerSupportState({
    this.tickets = const [],
    this.categories = const [],
    this.faqCategories = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerSupportState copyWith({
    List<SupportTicket>? tickets,
    List<SupportCategory>? categories,
    List<FAQCategory>? faqCategories,
    List<FAQItem>? searchResults,
    bool? isLoading,
    String? error,
  }) {
    return CustomerSupportState(
      tickets: tickets ?? this.tickets,
      categories: categories ?? this.categories,
      faqCategories: faqCategories ?? this.faqCategories,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for customer support
class CustomerSupportNotifier extends StateNotifier<CustomerSupportState> {
  final CustomerSupportService _supportService;
  final AppLogger _logger = AppLogger();

  CustomerSupportNotifier(this._supportService) : super(const CustomerSupportState()) {
    _initialize();
  }

  /// Initialize support data
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Load categories and FAQ in parallel
      final futures = await Future.wait([
        _supportService.getSupportCategories(),
        _supportService.getFAQCategories(),
        _supportService.getCustomerTickets(),
      ]);

      state = state.copyWith(
        categories: futures[0] as List<SupportCategory>,
        faqCategories: futures[1] as List<FAQCategory>,
        tickets: futures[2] as List<SupportTicket>,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerSupportNotifier: Error initializing', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search FAQ
  Future<void> searchFAQ(String query) async {
    try {
      if (query.trim().isEmpty) {
        state = state.copyWith(searchResults: []);
        return;
      }

      state = state.copyWith(isLoading: true);
      
      final results = await _supportService.searchFAQ(query);
      
      state = state.copyWith(
        searchResults: results,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerSupportNotifier: Error searching FAQ', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create support ticket
  Future<SupportTicket?> createTicket({
    required String subject,
    required String description,
    required String categoryId,
    String? orderId,
    String? customerEmail,
    String? customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final ticket = await _supportService.createSupportTicket(
        subject: subject,
        description: description,
        categoryId: categoryId,
        orderId: orderId,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        metadata: metadata,
      );

      // Add new ticket to the list
      final updatedTickets = [ticket, ...state.tickets];
      
      state = state.copyWith(
        tickets: updatedTickets,
        isLoading: false,
        error: null,
      );

      return ticket;
    } catch (e) {
      _logger.error('CustomerSupportNotifier: Error creating ticket', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Refresh tickets
  Future<void> refreshTickets() async {
    try {
      final tickets = await _supportService.getCustomerTickets();
      state = state.copyWith(tickets: tickets);
    } catch (e) {
      _logger.error('CustomerSupportNotifier: Error refreshing tickets', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark FAQ as helpful
  Future<void> markFAQHelpful(String faqItemId, bool isHelpful) async {
    try {
      await _supportService.markFAQHelpful(faqItemId, isHelpful);
    } catch (e) {
      _logger.error('CustomerSupportNotifier: Error marking FAQ helpful', e);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for customer support
final customerSupportProvider = StateNotifierProvider<CustomerSupportNotifier, CustomerSupportState>((ref) {
  final supportService = ref.watch(customerSupportServiceProvider);
  return CustomerSupportNotifier(supportService);
});

/// Provider for support categories
final supportCategoriesProvider = Provider<List<SupportCategory>>((ref) {
  final supportState = ref.watch(customerSupportProvider);
  return supportState.categories;
});

/// Provider for FAQ categories
final faqCategoriesProvider = Provider<List<FAQCategory>>((ref) {
  final supportState = ref.watch(customerSupportProvider);
  return supportState.faqCategories;
});

/// Provider for customer tickets
final customerTicketsProvider = Provider<List<SupportTicket>>((ref) {
  final supportState = ref.watch(customerSupportProvider);
  return supportState.tickets;
});

/// Provider for active tickets
final activeTicketsProvider = Provider<List<SupportTicket>>((ref) {
  final tickets = ref.watch(customerTicketsProvider);
  return tickets.where((ticket) => ticket.status.isActive).toList();
});

/// Provider for closed tickets
final closedTicketsProvider = Provider<List<SupportTicket>>((ref) {
  final tickets = ref.watch(customerTicketsProvider);
  return tickets.where((ticket) => ticket.status.isClosed).toList();
});

/// Provider for FAQ search results
final faqSearchResultsProvider = Provider<List<FAQItem>>((ref) {
  final supportState = ref.watch(customerSupportProvider);
  return supportState.searchResults;
});

/// Provider for emergency contacts
final emergencyContactsProvider = Provider<Map<String, dynamic>>((ref) {
  final supportService = ref.watch(customerSupportServiceProvider);
  return supportService.getEmergencyContacts();
});

/// State for support ticket chat
class SupportTicketChatState {
  final SupportTicket? ticket;
  final List<SupportMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const SupportTicketChatState({
    this.ticket,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  SupportTicketChatState copyWith({
    SupportTicket? ticket,
    List<SupportMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return SupportTicketChatState(
      ticket: ticket ?? this.ticket,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Notifier for support ticket chat
class SupportTicketChatNotifier extends StateNotifier<SupportTicketChatState> {
  final CustomerSupportService _supportService;
  final String _ticketId;
  final AppLogger _logger = AppLogger();
  
  StreamSubscription<List<SupportMessage>>? _messagesSubscription;

  SupportTicketChatNotifier(this._supportService, this._ticketId) : super(const SupportTicketChatState()) {
    _initialize();
  }

  /// Initialize ticket chat
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Load ticket details and initial messages
      final futures = await Future.wait([
        _supportService.getTicketDetails(_ticketId),
        _supportService.getTicketMessages(_ticketId),
      ]);

      state = state.copyWith(
        ticket: futures[0] as SupportTicket,
        messages: futures[1] as List<SupportMessage>,
        isLoading: false,
        error: null,
      );

      // Start real-time message stream
      _startMessageStream();
    } catch (e) {
      _logger.error('SupportTicketChatNotifier: Error initializing', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Start real-time message stream
  void _startMessageStream() {
    _messagesSubscription = _supportService.streamTicketMessages(_ticketId).listen(
      (messages) {
        state = state.copyWith(messages: messages);
      },
      onError: (error) {
        _logger.error('SupportTicketChatNotifier: Message stream error', error);
        state = state.copyWith(error: error.toString());
      },
    );
  }

  /// Send message
  Future<void> sendMessage(String content) async {
    try {
      state = state.copyWith(isSending: true);
      
      await _supportService.sendTicketMessage(
        ticketId: _ticketId,
        content: content,
      );
      
      state = state.copyWith(
        isSending: false,
        error: null,
      );
    } catch (e) {
      _logger.error('SupportTicketChatNotifier: Error sending message', e);
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Submit feedback
  Future<void> submitFeedback(int rating, String? feedbackText) async {
    try {
      await _supportService.submitTicketFeedback(
        ticketId: _ticketId,
        rating: rating,
        feedbackText: feedbackText,
      );
    } catch (e) {
      _logger.error('SupportTicketChatNotifier: Error submitting feedback', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for support ticket chat
final supportTicketChatProvider = StateNotifierProvider.family.autoDispose<SupportTicketChatNotifier, SupportTicketChatState, String>((ref, ticketId) {
  final supportService = ref.watch(customerSupportServiceProvider);
  return SupportTicketChatNotifier(supportService, ticketId);
});
