import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== 数据模型 ====================
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

// ==================== 壁纸服务 ====================
class WallpaperService {
  static const String _wallpaperPathKey = 'wallpaper_path';
  static const String _dominantColorKey = 'dominant_color';
  static const String _vibrantColorKey = 'vibrant_color';
  static const String _useWallpaperKey = 'use_wallpaper';

  /// 选择并裁切图片
  static Future<File?> pickAndCropImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // 选择图片来源
    final source = await _showSourcePicker(context);
    if (source == null) return null;

    // 选择图片
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );

    if (pickedFile == null) return null;

    // 打开自定义裁切页面
    final croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomImageCropperPage(
          imagePath: pickedFile.path,
        ),
      ),
    );

    if (croppedFile == null) return null;

    // 保存到应用目录
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final wallpaperPath = '${directory.path}/wallpaper_$timestamp.jpg';

    // 删除旧壁纸
    await _deleteOldWallpapers(directory.path);

    final savedFile = await croppedFile.copy(wallpaperPath);

    // 删除临时文件
    if (croppedFile.existsSync()) {
      await croppedFile.delete();
    }

    // 保存路径
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperPathKey, wallpaperPath);

    return savedFile;
  }

  /// 显示图片来源选择器
  static Future<ImageSource?> _showSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "选择壁纸",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "从相册或相机获取图片",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _SourceOptionCard(
                        icon: Icons.photo_library_rounded,
                        label: "相册",
                        subtitle: "从相册选择",
                        color: Colors.purple,
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SourceOptionCard(
                        icon: Icons.camera_alt_rounded,
                        label: "相机",
                        subtitle: "拍摄照片",
                        color: Colors.orange,
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "取消",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.blue;
      final vibrantColor = paletteGenerator.vibrantColor?.color;
      final mutedColor = paletteGenerator.mutedColor?.color;
      final paletteColors =
      paletteGenerator.paletteColors.map((c) => c.color).take(6).toList();

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
      vibrantColor: vibrantColorValue != null ? Color(vibrantColorValue) : null,
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

// ==================== 来源选项卡片 ====================
class _SourceOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 自定义裁切页面 ====================
class CustomImageCropperPage extends StatefulWidget {
  final String imagePath;

  const CustomImageCropperPage({
    super.key,
    required this.imagePath,
  });

  @override
  State<CustomImageCropperPage> createState() => _CustomImageCropperPageState();
}

class _CustomImageCropperPageState extends State<CustomImageCropperPage> {
  bool _isProcessing = false;
  bool _imageLoaded = false;

  // 原始图片信息
  ui.Image? _originalImage;
  Size _imageSize = Size.zero;

  // 裁切区域（屏幕坐标）
  late Rect _cropRect;

  // 图片变换参数
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;

  // 最小/最大缩放
  double _minScale = 1.0;
  double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      _originalImage = frame.image;
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      setState(() => _imageLoaded = true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCropArea();
      });
    } catch (e) {
      debugPrint('加载图片失败: $e');
    }
  }

  void _initializeCropArea() {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 裁切区域：全屏减去顶部和底部工具栏
    const topBarHeight = 100.0;
    const bottomBarHeight = 120.0;

    _cropRect = Rect.fromLTWH(
      0,
      topBarHeight,
      screenSize.width,
      screenSize.height - topBarHeight - bottomBarHeight,
    );

    // 计算初始缩放：让图片完全覆盖裁切区域
    final scaleX = _cropRect.width / _imageSize.width;
    final scaleY = _cropRect.height / _imageSize.height;
    _minScale = scaleX > scaleY ? scaleX : scaleY;
    _scale = _minScale;
    _maxScale = _minScale * 4;

    // 居中显示
    _offset = Offset(
      _cropRect.center.dx - (_imageSize.width * _scale) / 2,
      _cropRect.center.dy - (_imageSize.height * _scale) / 2,
    );

    setState(() {});
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _startOffset = details.focalPoint - _offset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // 更新缩放
      _scale = (_baseScale * details.scale).clamp(_minScale, _maxScale);

      // 更新位置
      _offset = details.focalPoint - _startOffset * (_scale / _baseScale);

      // 限制边界，确保图片覆盖裁切区域
      _constrainOffset();
    });
  }

  void _constrainOffset() {
    final imageWidth = _imageSize.width * _scale;
    final imageHeight = _imageSize.height * _scale;

    // 限制 X 方向
    if (imageWidth >= _cropRect.width) {
      // 图片比裁切区域宽，限制左右边界
      final minX = _cropRect.right - imageWidth;
      final maxX = _cropRect.left;
      _offset = Offset(_offset.dx.clamp(minX, maxX), _offset.dy);
    } else {
      // 图片比裁切区域窄，居中
      _offset = Offset(
        _cropRect.left + (_cropRect.width - imageWidth) / 2,
        _offset.dy,
      );
    }

    // 限制 Y 方向
    if (imageHeight >= _cropRect.height) {
      // 图片比裁切区域高，限制上下边界
      final minY = _cropRect.bottom - imageHeight;
      final maxY = _cropRect.top;
      _offset = Offset(_offset.dx, _offset.dy.clamp(minY, maxY));
    } else {
      // 图片比裁切区域矮，居中
      _offset = Offset(
        _offset.dx,
        _cropRect.top + (_cropRect.height - imageHeight) / 2,
      );
    }
  }

  void _resetTransform() {
    setState(() {
      _scale = _minScale;
      _offset = Offset(
        _cropRect.center.dx - (_imageSize.width * _scale) / 2,
        _cropRect.center.dy - (_imageSize.height * _scale) / 2,
      );
    });
  }

  Future<void> _cropAndSave() async {
    if (_originalImage == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 计算裁切区域对应原图的位置
      // 屏幕上的裁切区域 -> 原图坐标
      final srcLeft = (_cropRect.left - _offset.dx) / _scale;
      final srcTop = (_cropRect.top - _offset.dy) / _scale;
      final srcWidth = _cropRect.width / _scale;
      final srcHeight = _cropRect.height / _scale;

      // 确保在原图范围内
      final clampedLeft = srcLeft.clamp(0.0, _imageSize.width);
      final clampedTop = srcTop.clamp(0.0, _imageSize.height);
      final clampedWidth = srcWidth.clamp(0.0, _imageSize.width - clampedLeft);
      final clampedHeight = srcHeight.clamp(0.0, _imageSize.height - clampedTop);

      final srcRect = Rect.fromLTWH(
        clampedLeft,
        clampedTop,
        clampedWidth,
        clampedHeight,
      );

      // 输出尺寸与裁切区域相同
      final outputWidth = _cropRect.width.toInt();
      final outputHeight = _cropRect.height.toInt();

      final dstRect = Rect.fromLTWH(
        0,
        0,
        outputWidth.toDouble(),
        outputHeight.toDouble(),
      );

      // 创建裁切后的图片
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 绘制裁切区域
      canvas.drawImageRect(
        _originalImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(outputWidth, outputHeight);

      // 转换为 PNG
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      // 保存临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    } catch (e) {
      debugPrint('裁切失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('裁切失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== 图片层 =====
          if (_imageLoaded)
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: CustomPaint(
                  painter: _ImagePainter(
                    image: _originalImage!,
                    offset: _offset,
                    scale: _scale,
                  ),
                  size: Size.infinite,
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ===== 裁切遮罩层 =====
          if (_imageLoaded)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CropOverlayPainter(cropRect: _cropRect),
                ),
              ),
            ),

          // ===== 顶部栏 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: statusBarHeight,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Text(
                    "调整壁纸",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildTopButton(
                    icon: Icons.refresh,
                    onTap: _resetTransform,
                  ),
                ],
              ),
            ),
          ),

          // ===== 提示文字 =====
          if (_imageLoaded)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "双指缩放 · 拖动调整位置",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ===== 底部操作栏 =====
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 24,
                right: 24,
              ),
              child: Center(
                child: _buildConfirmButton(),
              ),
            ),
          ),

          // ===== 加载遮罩 =====
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("正在处理..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _cropAndSave,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isProcessing
                ? [Colors.grey, Colors.grey]
                : [Colors.blue, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "使用此壁纸",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 图片绘制器 ====================
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final Offset offset;
  final double scale;

  _ImagePainter({
    required this.image,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      image.width * scale,
      image.height * scale,
    );

    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    return offset != oldDelegate.offset || scale != oldDelegate.scale;
  }
}

// ==================== 裁切遮罩绘制器 ====================
class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Color overlayColor;
  final Color borderColor;
  final double cornerLength;
  final double cornerWidth;

  CropOverlayPainter({
    required this.cropRect,
    this.overlayColor = const Color(0x99000000),
    this.borderColor = Colors.white,
    this.cornerLength = 24,
    this.cornerWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // 绘制四周遮罩
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), paint);
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.bottom, size.width, size.height - cropRect.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top, size.width - cropRect.right, cropRect.height),
      paint,
    );

    // 绘制边框
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(cropRect, borderPaint);

    // 绘制网格线（三分法）
    final gridPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    // 纵向网格线
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth * 2, cropRect.top),
      Offset(cropRect.left + thirdWidth * 2, cropRect.bottom),
      gridPaint,
    );

    // 横向网格线
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight * 2),
      Offset(cropRect.right, cropRect.top + thirdHeight * 2),
      gridPaint,
    );

    // 绘制四角装饰
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    // 左上角
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cornerLength),
      Offset(cropRect.left, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top),
      Offset(cropRect.left + cornerLength, cropRect.top),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      Offset(cropRect.right - cornerLength, cropRect.top),
      Offset(cropRect.right, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.top),
      Offset(cropRect.right, cropRect.top + cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom - cornerLength),
      Offset(cropRect.left, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom),
      Offset(cropRect.left + cornerLength, cropRect.bottom),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      Offset(cropRect.right - cornerLength, cropRect.bottom),
      Offset(cropRect.right, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.bottom),
      Offset(cropRect.right, cropRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return cropRect != oldDelegate.cropRect;
  }
}