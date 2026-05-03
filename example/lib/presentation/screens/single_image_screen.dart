// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/utils/map_converter.dart';
import 'package:ultralytics_yolo/utils/error_handler.dart';
import '../../services/model_manager.dart';
import '../../models/models.dart';
import '../../services/garbage_classification_service.dart';
import 'package:extended_image/extended_image.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/garbage_info_card.dart';

/// A screen that demonstrates YOLO inference on a single image.
///
/// This screen allows users to:
/// - Pick an image from the gallery
/// - Run YOLO inference on the selected image
/// - View detection results and annotated image
class SingleImageScreen extends StatefulWidget {
  const SingleImageScreen({super.key});

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _detections = [];
  Uint8List? _imageBytes;
  Uint8List? _annotatedImage;
  late YOLO _yolo;
  String? _modelPath;
  bool _isModelReady = false;
  late final ModelManager _modelManager;
  late final GarbageClassificationService _classificationService;

  // 多选相关变量
  List<XFile> _selectedImages = [];
  List<Uint8List> _imageBytesList = [];
  List<Uint8List> _annotatedImages = [];
  List<List<Map<String, dynamic>>> _detectionsList = [];
  bool _isMultiSelectMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _modelManager = ModelManager();
    _classificationService = GarbageClassificationService();
    _initializeYOLO();
  }

  /// Initializes the YOLO model for inference
  Future<void> _initializeYOLO() async {
    _modelPath = await _modelManager.getModelPath(ModelType.segment);
    if (_modelPath == null) return;
    _yolo = YOLO(modelPath: _modelPath!, task: YOLOTask.segment);
    try {
      await _yolo.loadModel();
      if (mounted) setState(() => _isModelReady = true);
    } catch (e) {
      if (mounted) {
        final error = YOLOErrorHandler.handleError(
          e,
          'Failed to load model $_modelPath for task ${YOLOTask.segment.name}',
        );
        _showSnackBar('Error loading model: ${error.message}');
      }
    }
  }

  /// Picks images from the gallery and runs inference
  Future<void> _pickAndPredict({bool multiSelect = false}) async {
    if (!_isModelReady) {
      return _showSnackBar('Model is loading, please wait...');
    }

    if (multiSelect) {
      _startMultiSelect();
    } else {
      _startSingleSelect();
    }
  }

  /// Starts single image selection
  Future<void> _startSingleSelect() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    _isLoading = true;
    if (mounted) setState(() {});

    try {
      final bytes = await file.readAsBytes();
      final result = await _yolo.predict(bytes);

      if (mounted) {
        setState(() {
          _detections = result['boxes'] is List
              ? MapConverter.convertBoxesList(result['boxes'] as List)
              : [];
          _annotatedImage = result['annotatedImage'] as Uint8List?;
          _imageBytes = bytes;
          _selectedImages = [file];
          _imageBytesList = [bytes];
          _annotatedImages = [_annotatedImage!];
          _detectionsList = [_detections];
        });
      }
    } catch (e) {
      _showSnackBar('Prediction failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  /// Starts multi-image selection
  Future<void> _startMultiSelect() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;

    _isLoading = true;
    if (mounted) setState(() {});

    try {
      _selectedImages = files;
      _imageBytesList = [];
      _annotatedImages = [];
      _detectionsList = [];

      for (final file in files) {
        final bytes = await file.readAsBytes();
        final result = await _yolo.predict(bytes);

        _imageBytesList.add(bytes);
        _annotatedImages.add(result['annotatedImage'] as Uint8List?);
        _detectionsList.add(result['boxes'] is List
            ? MapConverter.convertBoxesList(result['boxes'] as List)
            : []);
      }

      if (mounted) {
        setState(() {
          _detections = _detectionsList.isNotEmpty ? _detectionsList.first : [];
          _annotatedImage = _annotatedImages.isNotEmpty ? _annotatedImages.first : null;
          _imageBytes = _imageBytesList.isNotEmpty ? _imageBytesList.first : null;
          _isMultiSelectMode = true;
        });
      }
    } catch (e) {
      _showSnackBar('Prediction failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  /// Toggles multi-select mode
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedImages = [];
        _imageBytesList = [];
        _annotatedImages = [];
        _detectionsList = [];
      }
    });
  }

  void _showSnackBar(String msg) => mounted
      ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)))
      : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单图片推理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _toggleMultiSelectMode,
              tooltip: 'Exit multi-select',
            ),
          if (!_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () => _pickAndPredict(multiSelect: true),
              tooltip: 'Multi-select images',
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _pickAndPredict(multiSelect: false),
                child: const Text('选择单个图片'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _pickAndPredict(multiSelect: true),
                child: const Text('选择多个图片'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 10),
                  Text(
                    Platform.isIOS
                        ? "处理图片中..."
                        : "运行推理中...",
                  ),
                ],
              ),
            ),
          if (_isMultiSelectMode && _selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Selected ${_selectedImages.length} images',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isMultiSelectMode && _selectedImages.isNotEmpty)
                    _buildImageGrid(),
                  if (_annotatedImage != null || _imageBytes != null)
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: DetectionOverlay(
                        image: _annotatedImage ?? _imageBytes!,
                        detections: _detections,
                        onDetectionTap: (detection) {
                          // Handle detection tap
                          _showSnackBar('检测到: ${detection.className}');
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text('检测结果：'),
                  Text(_detections.toString()),
                  if (_detections.isNotEmpty)
                    GarbageInfoCard(
                      detection: _detections.first,
                      classificationService: _classificationService,
                      onDetectionTap: (detection) {
                        // Handle detection tap
                        _showSnackBar('Detected: ${detection.className}');
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the image grid for multi-select mode
  Widget _buildImageGrid() {
    return Column(
      children: [
        const Text('已选择的图片：'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            return Card(
              child: Column(
                children: [
                  Expanded(
                    child: Image.memory(
                      _annotatedImages[index] ?? _imageBytesList[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Image ${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Detections: ${_detectionsList[index].length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
