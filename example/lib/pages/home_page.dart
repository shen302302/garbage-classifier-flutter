import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/permission_service.dart';
import '../services/yolo_service.dart';
import '../services/settings_service.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/detection_image_box.dart';
import '../widgets/result_list.dart';
import 'settings_page.dart';

/// 主页面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PermissionService _permissionService = PermissionService();
  final YoloService _yoloService = YoloService();
  final SettingsService _settingsService = SettingsService();

  File? _selectedImage;
  Size? _selectedImageSize;
  List<YoloDetection> _detections = [];
  bool _isLoading = false;
  bool _isModelLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始化设置服务
    await _settingsService.init();

    // 请求权限
    await _permissionService.requestAllPermissions();

    // 初始化 YOLO 模型
    final success = await _yoloService.initialize();
    setState(() {
      _isModelLoading = false;
      if (!success) {
        _errorMessage = '模型加载失败，请重启应用';
      }
    });
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerBottomSheet(
        onGalleryTap: () => _pickImage(ImageSource.gallery),
        onCameraTap: () => _pickImage(ImageSource.camera),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // 检查权限
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _permissionService.requestCameraPermission();
        if (!hasPermission) {
          _permissionService.showPermissionDeniedDialog(context, '相机');
          return;
        }
      } else {
        hasPermission = await _permissionService.requestPhotoPermission();
        if (!hasPermission) {
          _permissionService.showPermissionDeniedDialog(context, '相册');
          return;
        }
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedImageSize = null;
        _detections = [];
      });

      // Decode image to get native dimensions for box coordinate mapping
      final bytes = await _selectedImage!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _selectedImageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      codec.dispose();

      // 进行预测
      await _predictImage(bytes);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '选择图片失败: $e';
      });
    }
  }

  Future<void> _predictImage([Uint8List? preloadedBytes]) async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = preloadedBytes ?? await _selectedImage!.readAsBytes();
      final threshold = _settingsService.getConfidenceThreshold();

      final detections = await _yoloService.predictImage(
        imageBytes,
        confidenceThreshold: threshold,
      );

      setState(() {
        _detections = detections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '识别失败: $e';
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedImage = null;
      _detections = [];
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('垃圾分类识别'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.recycling,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '垃圾分类识别',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '智能识别垃圾类别',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('首页'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('垃圾分类识别应用'),
            SizedBox(height: 8),
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('基于 YOLO 深度学习模型'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isModelLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载模型...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initialize,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 检测图片显示
            if (_selectedImage != null)
              DetectionImageBox(
                imageFile: _selectedImage,
                originalImageSize: _selectedImageSize,
                detections: _detections,
                isLoading: _isLoading,
              )
            else
              ImagePickerBox(
                imageFile: _selectedImage,
                isLoading: _isLoading,
                onTap: _showImagePickerBottomSheet,
              ),
            const SizedBox(height: 20),
            // 重新选择按钮（仅在已选择图片后显示）
            if (_selectedImage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetSelection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('点击此处重新选择图片'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // 检测结果列表
            if (_selectedImage != null)
              ResultList(
                detections: _detections,
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
