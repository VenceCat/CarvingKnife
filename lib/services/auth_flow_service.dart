import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

enum AuthFlowNotice {
  emailConfirmed,
}

abstract final class AuthFlowService {
  static const String _emailConfirmationPendingKey =
      'auth_email_confirmation_pending';

  static final ValueNotifier<bool> passwordRecoveryPending =
      ValueNotifier<bool>(false);
  static final ValueNotifier<AuthFlowNotice?> notice =
      ValueNotifier<AuthFlowNotice?>(null);

  static StreamSubscription<AuthState>? _subscription;

  static void initialize() {
    if (!SupabaseService.isReady || _subscription != null) return;

    _subscription =
        SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryPending.value = true;
        return;
      }

      if (data.event != AuthChangeEvent.signedIn) return;

      final prefs = await SharedPreferences.getInstance();
      final isEmailConfirmationPending =
          prefs.getBool(_emailConfirmationPendingKey) ?? false;
      if (!isEmailConfirmationPending) return;

      await prefs.remove(_emailConfirmationPendingKey);
      notice.value = AuthFlowNotice.emailConfirmed;
      await SupabaseService.client.auth.signOut();
    });
  }

  static void clearPasswordRecovery() {
    if (passwordRecoveryPending.value) {
      passwordRecoveryPending.value = false;
    }
  }

  static Future<void> markEmailConfirmationPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailConfirmationPendingKey, true);
  }

  static Future<void> clearEmailConfirmationPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailConfirmationPendingKey);
  }

  static void clearNotice() {
    if (notice.value != null) {
      notice.value = null;
    }
  }
}
