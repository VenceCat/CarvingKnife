import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'auth_flow_service.dart';
import 'supabase_service.dart';

abstract final class AuthService {
  static User? get currentUser =>
      SupabaseService.isReady ? SupabaseService.client.auth.currentUser : null;

  static Stream<User?> get authStateChanges {
    if (!SupabaseService.isReady) {
      return Stream<User?>.value(null);
    }

    return SupabaseService.client.auth.onAuthStateChange
        .map((data) => data.session?.user);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _ensureReady();
    final trimmedDisplayName = displayName?.trim();

    final response = await SupabaseService.client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseConfig.emailConfirmRedirectTo.isEmpty
          ? null
          : SupabaseConfig.emailConfirmRedirectTo,
      data: trimmedDisplayName == null || trimmedDisplayName.isEmpty
          ? null
          : {'display_name': trimmedDisplayName},
    );

    // When email confirmation is enabled, Supabase can obfuscate duplicate
    // registrations by returning a user-shaped response instead of an error.
    if (_isObfuscatedDuplicateSignUp(response)) {
      throw const AuthException('User already registered');
    }

    if (response.session == null) {
      await AuthFlowService.markEmailConfirmationPending();
    } else {
      await AuthFlowService.clearEmailConfirmationPending();
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _ensureReady();

    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await AuthFlowService.clearEmailConfirmationPending();
    return response;
  }

  static Future<void> signOut() async {
    _ensureReady();
    await SupabaseService.client.auth.signOut();
  }

  static Future<void> resendSignupConfirmation(String email) async {
    _ensureReady();
    await SupabaseService.client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
    await AuthFlowService.markEmailConfirmationPending();
  }

  static Future<void> sendPasswordReset(String email) async {
    _ensureReady();

    await SupabaseService.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseConfig.passwordResetRedirectTo.isEmpty
          ? null
          : SupabaseConfig.passwordResetRedirectTo,
    );
  }

  static Future<UserResponse> updatePassword(String password) async {
    _ensureReady();
    return SupabaseService.client.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  static Future<UserResponse> updateDisplayName(String displayName) async {
    _ensureReady();
    final response = await SupabaseService.client.auth.updateUser(
      UserAttributes(
        data: {'display_name': displayName.trim()},
      ),
    );

    final user = response.user ?? currentUser;
    if (user != null) {
      try {
        await SupabaseService.client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': displayName.trim(),
        });
      } catch (_) {
        // Keep auth metadata updates working even before profiles SQL is applied.
      }
    }

    return response;
  }

  static String readableMessage(Object error) {
    late final String rawMessage;
    if (error is AuthException) {
      rawMessage = error.message.trim();
    } else if (error is StateError) {
      rawMessage = error.message.trim();
    } else {
      rawMessage = error.toString().trim();
    }

    if (rawMessage.isEmpty) {
      return '操作失败，请稍后再试。';
    }
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(rawMessage)) {
      return rawMessage;
    }

    final message = rawMessage.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return '邮箱或密码错误。';
    }
    if (message.contains('email not confirmed')) {
      return '邮箱尚未验证，请先完成邮箱验证。';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return '该邮箱已注册，请直接登录。';
    }
    if (message.contains('password should be at least') ||
        message.contains('password must be at least')) {
      return '密码至少需要 6 位。';
    }
    if (message.contains('unable to validate email address') ||
        message.contains('invalid email')) {
      return '邮箱格式不正确。';
    }
    if (message.contains('rate limit') ||
        message.contains('security purposes you can only request this after')) {
      return '请求过于频繁，请稍后再试。';
    }
    if (message.contains('network request failed') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('connection closed before full header')) {
      return '网络连接失败，请检查网络后重试。';
    }
    if (message.contains('same password') ||
        message.contains('should be different from the old password')) {
      return '新密码不能与旧密码相同。';
    }
    if (message.contains('user not found')) {
      return '该邮箱尚未注册。';
    }
    if (message.contains('supabase is not configured')) {
      return '账户服务暂不可用，请稍后再试。';
    }

    return '操作失败，请稍后再试。';
  }

  static void _ensureReady() {
    if (!SupabaseService.isReady) {
      throw StateError('Supabase is not configured yet.');
    }
  }

  static bool _isObfuscatedDuplicateSignUp(AuthResponse response) {
    if (response.session != null) return false;

    final identities = response.user?.identities;
    return identities != null && identities.isEmpty;
  }
}
