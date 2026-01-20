import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
  });
}

class UpdateService {
  // 替换为你的 Gitee 用户名和仓库名
  static const String _owner = 'VenceCat';
  static const String _repo = 'CarvingKnife';

  /// 检查更新
  static Future<UpdateResult> checkUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://gitee.com/api/v5/repos/$_owner/$_repo/releases/latest'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = tagName.replaceAll('v', '').replaceAll('V', '');
        final changelog = data['body'] as String? ?? '暂无更新说明';

        // 获取APK下载链接
        String? downloadUrl;
        final assets = data['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = asset['name']?.toString() ?? '';
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        // 如果没有找到APK附件，尝试使用Release的源码包或其他链接
        downloadUrl ??= data['html_url'] as String? ?? '';

        // 获取当前版本
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          return UpdateResult(
            hasUpdate: true,
            updateInfo: UpdateInfo(
              version: latestVersion,
              downloadUrl: downloadUrl,
              changelog: changelog,
            ),
            currentVersion: currentVersion,
          );
        } else {
          return UpdateResult(
            hasUpdate: false,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
          );
        }
      } else if (response.statusCode == 404) {
        return UpdateResult(
          hasUpdate: false,
          error: '暂无发布版本',
        );
      } else {
        return UpdateResult(
          hasUpdate: false,
          error: '检查更新失败 (${response.statusCode})',
        );
      }
    } catch (e) {
      return UpdateResult(
        hasUpdate: false,
        error: '网络连接失败，请稍后重试',
      );
    }
  }

  /// 比较版本号，判断是否有新版本
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // 确保两个列表长度一致
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取当前版本号
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}

/// 更新检查结果
class UpdateResult {
  final bool hasUpdate;
  final UpdateInfo? updateInfo;
  final String? currentVersion;
  final String? latestVersion;
  final String? error;

  UpdateResult({
    required this.hasUpdate,
    this.updateInfo,
    this.currentVersion,
    this.latestVersion,
    this.error,
  });
}