import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperData {
  final String path;
  final Color dominantColor;
  final Color? vibrantColor;
  final Color? mutedColor;
  final List<Color> paletteColors;

  WallpaperData({
    required this.path,
    required this.dominantColor,
    this.vibrantColor,
    this.mutedColor,
    this.paletteColors = const [],
  });
}

class WallpaperService {
  static const String _wallpaperPathKey = 'wallpaper_path';
  static const String _dominantColorKey = 'dominant_color';
  static const String _vibrantColorKey = 'vibrant_color';
  static const String _useWallpaperKey = 'use_wallpaper';

  /// 选择并裁切图片
  static Future<File?> pickAndCropImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // 选择图片来源
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text("选择壁纸来源",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context,
                    icon: Icons.photo_library_outlined,
                    label: "相册",
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  _buildSourceOption(
                    context,
                    icon: Icons.camera_alt_outlined,
                    label: "相机",
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    // 选择图片
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );

    if (pickedFile == null) return null;

    // 获取屏幕尺寸用于裁切比例
    final screenSize = MediaQuery.of(context).size;

    // 裁切图片
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: CropAspectRatio(
        ratioX: screenSize.width,
        ratioY: screenSize.height,
      ),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '调整壁纸',
          toolbarColor: Colors.black87,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: Colors.blue,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: '调整壁纸',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return null;

    // 保存到应用目录
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final wallpaperPath = '${directory.path}/wallpaper_$timestamp.jpg';

    // 删除旧壁纸
    await _deleteOldWallpapers(directory.path);

    final savedFile = await File(croppedFile.path).copy(wallpaperPath);

    // 保存路径
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperPathKey, wallpaperPath);

    return savedFile;
  }

  static Widget _buildSourceOption(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  /// 从图片提取颜色
  static Future<WallpaperData?> extractColors(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) return null;

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(imageFile),
        size: const Size(200, 200),
        maximumColorCount: 16,
      );

      final dominantColor =
          paletteGenerator.dominantColor?.color ?? Colors.blue;
      final vibrantColor = paletteGenerator.vibrantColor?.color;
      final mutedColor = paletteGenerator.mutedColor?.color;
      final paletteColors =
      paletteGenerator.paletteColors.map((c) => c.color).take(6).toList();

      // 保存颜色
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dominantColorKey, dominantColor.value);
      if (vibrantColor != null) {
        await prefs.setInt(_vibrantColorKey, vibrantColor.value);
      }
      await prefs.setBool(_useWallpaperKey, true);

      return WallpaperData(
        path: imagePath,
        dominantColor: dominantColor,
        vibrantColor: vibrantColor,
        mutedColor: mutedColor,
        paletteColors: paletteColors,
      );
    } catch (e) {
      debugPrint('提取颜色失败: $e');
      return null;
    }
  }

  /// 获取保存的壁纸数据
  static Future<WallpaperData?> getSavedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_wallpaperPathKey);
    final useWallpaper = prefs.getBool(_useWallpaperKey) ?? false;

    if (path == null || !useWallpaper || !File(path).existsSync()) {
      return null;
    }

    final dominantColorValue = prefs.getInt(_dominantColorKey);
    final vibrantColorValue = prefs.getInt(_vibrantColorKey);

    return WallpaperData(
      path: path,
      dominantColor:
      dominantColorValue != null ? Color(dominantColorValue) : Colors.blue,
      vibrantColor:
      vibrantColorValue != null ? Color(vibrantColorValue) : null,
    );
  }

  /// 清除壁纸
  static Future<void> clearWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_wallpaperPathKey);

    if (path != null && File(path).existsSync()) {
      await File(path).delete();
    }

    await prefs.remove(_wallpaperPathKey);
    await prefs.remove(_dominantColorKey);
    await prefs.remove(_vibrantColorKey);
    await prefs.setBool(_useWallpaperKey, false);
  }

  /// 删除旧壁纸文件
  static Future<void> _deleteOldWallpapers(String directoryPath) async {
    final directory = Directory(directoryPath);
    final files = directory.listSync();

    for (var file in files) {
      if (file is File && file.path.contains('wallpaper_')) {
        await file.delete();
      }
    }
  }

  /// 生成协调的背景色
  static Color generateBackgroundColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withSaturation(0.08).withLightness(0.97).toColor();
  }
}