import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// YOLO 检测结果
class YoloDetection {
  final String className;
  final double confidence;
  final Rect boundingBox;

  YoloDetection({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });
}

/// YOLO 预测服务
class YoloService {
  YOLO? _yolo;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化 YOLO 模型
  Future<bool> initialize({bool useGpu = true}) async {
    try {
      _yolo = YOLO(
        modelPath: 'assets/models/garbage.tflite',
        task: YOLOTask.detect,
        useGpu: useGpu,
      );

      final success = await _yolo!.loadModel();
      if (success) {
        // Force lazy predictor initialization so errors surface early
        await _yolo!.predictorInstance();
      }
      _isInitialized = success;
      return success;
    } catch (e) {
      debugPrint('YOLO 初始化失败: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// 对图片进行预测
  Future<List<YoloDetection>> predictImage(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    if (!_isInitialized || _yolo == null) {
      throw Exception('YOLO 模型未初始化');
    }

    try {
      // 将置信度阈值传递给原生层
      final results = await _yolo!.predict(
        imageBytes,
        confidenceThreshold: confidenceThreshold,
      );
      final detections = <YoloDetection>[];

      debugPrint('YOLO 预测结果 keys: ${results.keys.toList()}');

      if (results.containsKey('detections')) {
        final detectionList = results['detections'];
        if (detectionList is List) {
          debugPrint('检测到 ${detectionList.length} 个结果');
          for (final d in detectionList) {
            if (d is Map) {
              try {
                final detection = _parseDetection(d);
                if (detection != null &&
                    detection.confidence >= confidenceThreshold) {
                  detections.add(detection);
                }
              } catch (e) {
                debugPrint('解析检测结果失败: $e');
              }
            }
          }
        }
      } else {
        debugPrint('预测结果中无 detections 字段: ${results.keys.toList()}');
      }

      // 按置信度排序
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));
      debugPrint('过滤后有效检测: ${detections.length} 个');
      return detections;
    } catch (e) {
      debugPrint('预测失败: $e');
      rethrow;
    }
  }

  /// 从检测结果 Map 中解析 YoloDetection，避免 YOLOResult.fromMap 的类型转换问题
  YoloDetection? _parseDetection(Map<dynamic, dynamic> map) {
    final className = _safeGetString(map, 'className');
    final confidence = _safeGetDouble(map, 'confidence');

    Rect boundingBox = Rect.zero;
    final boxData = map['boundingBox'];
    if (boxData is Map) {
      boundingBox = Rect.fromLTRB(
        _safeGetDouble(boxData, 'left'),
        _safeGetDouble(boxData, 'top'),
        _safeGetDouble(boxData, 'right'),
        _safeGetDouble(boxData, 'bottom'),
      );
    }

    if (className.isEmpty && confidence == 0.0) return null;

    return YoloDetection(
      className: className,
      confidence: confidence,
      boundingBox: boundingBox,
    );
  }

  static double _safeGetDouble(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static String _safeGetString(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    return '';
  }

  /// 释放资源
  void dispose() {
    _yolo = null;
    _isInitialized = false;
  }
}
