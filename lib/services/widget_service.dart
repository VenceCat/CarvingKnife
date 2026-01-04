import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.example.carvingknife/widget');

  static Future<void> initialize() async {
    // 空实现
  }

  /// 通知小组件更新
  static Future<void> updateWidget(List<dynamic> habits) async {
    try {
      await _channel.invokeMethod('updateWidget');
      print('=== Widget update triggered ===');
    } catch (e) {
      print('=== Widget update error: $e ===');
    }
  }
}