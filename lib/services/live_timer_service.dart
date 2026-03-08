import 'package:flutter/services.dart';

typedef LiveTimerActionCallback = Future<void> Function(
  String action,
  int totalSeconds,
  int remainingSeconds,
);

class LiveTimerService {
  static const MethodChannel _channel =
      MethodChannel('com.example.carvingknife/live_timer');

  static LiveTimerActionCallback? _actionCallback;

  static Future<void> startTimer({
    required String title,
    required int totalSeconds,
    required int remainingSeconds,
  }) async {
    try {
      await _channel.invokeMethod('startLiveTimer', <String, dynamic>{
        'title': title,
        'totalSeconds': totalSeconds,
        'remainingSeconds': remainingSeconds,
      });
    } catch (_) {}
  }

  static Future<void> updateTimer({
    required int totalSeconds,
    required int remainingSeconds,
  }) async {
    try {
      await _channel.invokeMethod('updateLiveTimer', <String, dynamic>{
        'totalSeconds': totalSeconds,
        'remainingSeconds': remainingSeconds,
      });
    } catch (_) {}
  }

  static Future<void> stopTimer() async {
    try {
      await _channel.invokeMethod('stopLiveTimer');
    } catch (_) {}
  }

  static Future<bool> canPostPromotedNotifications() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('canPostPromotedNotifications');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  static Future<bool> isFluidCloudSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFluidCloudSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isFlashViewsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFlashViewsEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static void registerActionCallback(LiveTimerActionCallback? callback) {
    _actionCallback = callback;
    if (callback == null) {
      _channel.setMethodCallHandler(null);
    } else {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'timerAction') return;
    final args = (call.arguments as Map?) ?? const {};
    final action = args['action'] as String? ?? '';
    final totalSeconds = args['totalSeconds'] as int? ?? 0;
    final remainingSeconds = args['remainingSeconds'] as int? ?? 0;
    final cb = _actionCallback;
    if (cb != null && action.isNotEmpty) {
      await cb(action, totalSeconds, remainingSeconds);
    }
  }
}
