import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import core services
// TODO: Remove unused imports when services are used
// import '../../../core/services/storage_service.dart';
// import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';

// Import constants
import '../../../core/constants/app_constants.dart';

/// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// App Logger Provider
final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

/// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Theme Mode Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const String _key = AppConstants.keyThemeMode;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeModeString = _prefs.getString(_key);
    if (themeModeString != null) {
      switch (themeModeString) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

/// Language Provider
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});

/// Language Notifier
class LanguageNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const String _key = AppConstants.keySelectedLanguage;

  LanguageNotifier(this._prefs) : super(AppConstants.defaultLanguage) {
    _loadLanguage();
  }

  void _loadLanguage() {
    final language = _prefs.getString(_key) ?? AppConstants.defaultLanguage;
    if (AppConstants.supportedLanguages.contains(language)) {
      state = language;
    }
  }

  Future<void> setLanguage(String language) async {
    if (AppConstants.supportedLanguages.contains(language)) {
      state = language;
      await _prefs.setString(_key, language);
    }
  }
}

/// First Launch Provider
final firstLaunchProvider = StateNotifierProvider<FirstLaunchNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FirstLaunchNotifier(prefs);
});

/// First Launch Notifier
class FirstLaunchNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String _key = AppConstants.keyIsFirstLaunch;

  FirstLaunchNotifier(this._prefs) : super(true) {
    _loadFirstLaunch();
  }

  void _loadFirstLaunch() {
    state = _prefs.getBool(_key) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    state = false;
    await _prefs.setBool(_key, false);
  }
}

/// Network Status Provider
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

/// Network Status Model
class NetworkStatus {
  final bool isConnected;
  final String? errorMessage;

  const NetworkStatus({
    required this.isConnected,
    this.errorMessage,
  });

  NetworkStatus copyWith({
    bool? isConnected,
    String? errorMessage,
  }) {
    return NetworkStatus(
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Network Status Notifier
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier() : super(const NetworkStatus(isConnected: true));

  void setConnected(bool isConnected, [String? errorMessage]) {
    state = NetworkStatus(
      isConnected: isConnected,
      errorMessage: errorMessage,
    );
  }
}

/// Loading State Provider
final globalLoadingProvider = StateNotifierProvider<GlobalLoadingNotifier, LoadingState>((ref) {
  return GlobalLoadingNotifier();
});

/// Loading State Model
class LoadingState {
  final bool isLoading;
  final String? message;
  final double? progress;

  const LoadingState({
    this.isLoading = false,
    this.message,
    this.progress,
  });

  LoadingState copyWith({
    bool? isLoading,
    String? message,
    double? progress,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

/// Global Loading Notifier
class GlobalLoadingNotifier extends StateNotifier<LoadingState> {
  GlobalLoadingNotifier() : super(const LoadingState());

  void setLoading(bool isLoading, {String? message, double? progress}) {
    state = LoadingState(
      isLoading: isLoading,
      message: message,
      progress: progress,
    );
  }

  void clearLoading() {
    state = const LoadingState();
  }
}

/// Error State Provider
final globalErrorProvider = StateNotifierProvider<GlobalErrorNotifier, ErrorState?>((ref) {
  return GlobalErrorNotifier();
});

/// Error State Model
class ErrorState {
  final String message;
  final String? title;
  final String? code;
  final DateTime timestamp;

  ErrorState({
    required this.message,
    this.title,
    this.code,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ErrorState copyWith({
    String? message,
    String? title,
    String? code,
    DateTime? timestamp,
  }) {
    return ErrorState(
      message: message ?? this.message,
      title: title ?? this.title,
      code: code ?? this.code,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Global Error Notifier
class GlobalErrorNotifier extends StateNotifier<ErrorState?> {
  GlobalErrorNotifier() : super(null);

  void setError(String message, {String? title, String? code}) {
    state = ErrorState(
      message: message,
      title: title,
      code: code,
    );
  }

  void clearError() {
    state = null;
  }
}

/// App Settings Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(prefs);
});

/// App Settings Model
class AppSettings {
  final bool enableNotifications;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enablePerformanceMonitoring;
  final bool enableDebugLogging;

  const AppSettings({
    this.enableNotifications = true,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.enablePerformanceMonitoring = true,
    this.enableDebugLogging = false,
  });

  AppSettings copyWith({
    bool? enableNotifications,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    bool? enablePerformanceMonitoring,
    bool? enableDebugLogging,
  }) {
    return AppSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      enablePerformanceMonitoring: enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableDebugLogging': enableDebugLogging,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      enableAnalytics: json['enableAnalytics'] ?? true,
      enableCrashReporting: json['enableCrashReporting'] ?? true,
      enablePerformanceMonitoring: json['enablePerformanceMonitoring'] ?? true,
      enableDebugLogging: json['enableDebugLogging'] ?? false,
    );
  }
}

/// App Settings Notifier
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  static const String _key = AppConstants.keySettings;

  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final settingsJson = _prefs.getString(_key);
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json = {};
        // Parse JSON string if needed
        state = AppSettings.fromJson(json);
      } catch (e) {
        // Use default settings if parsing fails
        state = const AppSettings();
      }
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await _prefs.setString(_key, settings.toJson().toString());
  }

  Future<void> toggleNotifications() async {
    final newSettings = state.copyWith(enableNotifications: !state.enableNotifications);
    await updateSettings(newSettings);
  }

  Future<void> toggleAnalytics() async {
    final newSettings = state.copyWith(enableAnalytics: !state.enableAnalytics);
    await updateSettings(newSettings);
  }

  Future<void> toggleCrashReporting() async {
    final newSettings = state.copyWith(enableCrashReporting: !state.enableCrashReporting);
    await updateSettings(newSettings);
  }

  Future<void> togglePerformanceMonitoring() async {
    final newSettings = state.copyWith(enablePerformanceMonitoring: !state.enablePerformanceMonitoring);
    await updateSettings(newSettings);
  }

  Future<void> toggleDebugLogging() async {
    final newSettings = state.copyWith(enableDebugLogging: !state.enableDebugLogging);
    await updateSettings(newSettings);
  }
}

/// Search Provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

/// Search State Model
class SearchState {
  final String query;
  final List<String> recentSearches;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.recentSearches = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<String>? recentSearches,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final recentSearches = List<String>.from(state.recentSearches);
    recentSearches.remove(query); // Remove if already exists
    recentSearches.insert(0, query); // Add to beginning
    
    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    
    state = state.copyWith(recentSearches: recentSearches);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  void clearQuery() {
    state = state.copyWith(query: '');
  }
}
