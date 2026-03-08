import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

abstract final class SupabaseService {
  static bool _initialized = false;
  static Object? _initializationError;

  static bool get isConfigured => SupabaseConfig.isConfigured;
  static bool get isReady => _initialized;
  static bool get hasInitializationError => _initializationError != null;
  static String? get initializationErrorMessage => _initializationError?.toString();

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      _initializationError = null;
    } catch (error, stackTrace) {
      _initializationError = error;
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase has not been initialized.');
    }
    return Supabase.instance.client;
  }
}
