import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:developer' as developer;

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable web debugging
  if (kIsWeb && kDebugMode) {
    developer.log('🌐 Flutter Web Debug Mode Enabled', name: 'GigaEats');
    // Force debug prints to console in web
    debugPrint = (String? message, {int? wrapWidth}) {
      developer.log(message ?? '', name: 'GigaEats-Debug');
    };
  }

  // Initialize Supabase (Primary Authentication & Backend)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: kDebugMode, // Enable debug mode in development
      // Web-specific configuration
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    if (kIsWeb && kDebugMode) {
      developer.log('✅ Supabase initialized successfully for web', name: 'GigaEats');
      developer.log('🔗 Supabase URL: ${SupabaseConfig.url}', name: 'GigaEats');
      developer.log('🔑 Using anon key: ${SupabaseConfig.anonKey.substring(0, 20)}...', name: 'GigaEats');
    } else {
      debugPrint('Supabase initialized successfully for ${kIsWeb ? 'web' : 'mobile'}');
      debugPrint('Supabase URL: ${SupabaseConfig.url}');
    }
  } catch (e) {
    if (kIsWeb && kDebugMode) {
      developer.log('❌ Supabase initialization failed: $e', name: 'GigaEats-Error');
    } else {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  // Initialize Stripe
  try {
    // Using the correct Stripe publishable key
    const stripeKey = 'pk_test_51RXohtPCN6tLb5FzbEFGMeZ1aU5FJ3owQEoiwUMxcAqro6AsETh7Vs8aQgDxj0eSHWLYXwy2sgvcY3hqURz17Zgj00mGOBYIMn';
    debugPrint('🔑 Setting Stripe publishable key: ${stripeKey.substring(0, 20)}...');
    debugPrint('🔑 Full key length: ${stripeKey.length}');
    debugPrint('🔑 Key ends with: ${stripeKey.substring(stripeKey.length - 10)}');

    Stripe.publishableKey = stripeKey;
    await Stripe.instance.applySettings();

    if (kIsWeb && kDebugMode) {
      developer.log('✅ Stripe initialized successfully with key: ${stripeKey.substring(0, 20)}...', name: 'GigaEats');
    } else {
      debugPrint('✅ Stripe initialized successfully with key: ${stripeKey.substring(0, 20)}...');
    }
  } catch (e) {
    if (kIsWeb && kDebugMode) {
      developer.log('❌ Stripe initialization failed: $e', name: 'GigaEats-Error');
    } else {
      debugPrint('❌ Stripe initialization failed: $e');
    }
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Set preferred orientations (only for mobile platforms)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const GigaEatsApp(),
    ),
  );
}

class GigaEatsApp extends ConsumerWidget {
  const GigaEatsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization Configuration
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'MY'), // English (Malaysia)
        Locale('ms', 'MY'), // Bahasa Malaysia
        Locale('zh', 'CN'), // Chinese Simplified
      ],
      locale: const Locale('en', 'MY'), // Default locale

      // Router Configuration
      routerConfig: router,

      // Builder for additional configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break the UI
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}


