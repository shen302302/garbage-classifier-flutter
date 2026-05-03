import 'package:ultralytics_yolo/models/yolo_result.dart';

/// Garbage classification information
class GarbageClassification {
  final String className;
  final String category; // 可回收物、有害垃圾、厨余垃圾、其他垃圾
  final String description;
  final String disposalMethod;
  final String tips;

  const GarbageClassification({
    required this.className,
    required this.category,
    required this.description,
    required this.disposalMethod,
    required this.tips,
  });
}

/// Service to classify garbage based on YOLO results
class GarbageClassificationService {
  /// Map YOLO detection result to garbage classification
  Future<GarbageClassification> classify(YOLOResult detection) async {
    final className = detection.className?.toLowerCase() ?? '';
    final confidence = detection.confidence;

    // Simple mapping from YOLO classes to garbage categories
    final classification = _getGarbageClassification(className, confidence);

    return classification;
  }

  /// Get garbage classification based on class name
  GarbageClassification _getGarbageClassification(String className, double confidence) {
    // Default classification
    if (className.isEmpty) {
      return const GarbageClassification(
        className: '未知',
        category: '其他垃圾',
        description: '无法识别的垃圾类型',
        disposalMethod: '请按照当地垃圾分类指南处理',
        tips: '建议咨询当地环卫部门',
      );
    }

    // Map common garbage types
    if (className.contains('plastic') || className.contains('bottle')) {
      return GarbageClassification(
        className: className,
        category: '可回收物',
        description: '塑料制品，包括塑料瓶、塑料袋等',
        disposalMethod: '清洗干净后投放至可回收物垃圾桶',
        tips: '塑料瓶请压扁后投放，提高回收效率',
      );
    } else if (className.contains('paper') || className.contains('cardboard')) {
      return GarbageClassification(
        className: className,
        category: '可回收物',
        description: '纸张类物品，包括报纸、纸箱等',
        disposalMethod: '平整投放至可回收物垃圾桶',
        tips: '保持干燥，避免受潮',
      );
    } else if (className.contains('glass') || className.contains('bottle')) {
      return GarbageClassification(
        className: className,
        category: '可回收物',
        description: '玻璃制品，包括玻璃瓶、玻璃杯等',
        disposalMethod: '轻放至可回收物垃圾桶',
        tips: '避免破碎，小心投放',
      );
    } else if (className.contains('metal') || className.contains('can')) {
      return GarbageClassification(
        className: className,
        category: '可回收物',
        description: '金属制品，包括易拉罐、金属容器等',
        disposalMethod: '清洗干净后投放至可回收物垃圾桶',
        tips: '压扁后投放，节省空间',
      );
    } else if (className.contains('organic') || className.contains('food')) {
      return GarbageClassification(
        className: className,
        category: '厨余垃圾',
        description: '有机废物，包括食物残渣、果皮等',
        disposalMethod: '投放至厨余垃圾处理器或专用垃圾桶',
        tips: '沥干水分后投放，避免异味',
      );
    } else if (className.contains('battery') || className.contains('electronic')) {
      return GarbageClassification(
        className: className,
        category: '有害垃圾',
        description: '有害废弃物，包括电池、电子产品等',
        disposalMethod: '投放至有害垃圾专用收集点',
        tips: '请勿随意丢弃，避免环境污染',
      );
    } else if (className.contains('medical') || className.contains('needle')) {
      return GarbageClassification(
        className: className,
        category: '有害垃圾',
        description: '医疗废弃物，包括药品、针头等',
        disposalMethod: '投放至医疗废物专用收集点',
        tips: '需要专业处理，请勿混入其他垃圾',
      );
    } else {
      return GarbageClassification(
        className: className,
        category: '其他垃圾',
        description: '其他无法归类的生活垃圾',
        disposalMethod: '投放至其他垃圾垃圾桶',
        tips: '请按照当地垃圾分类指南处理',
      );
    }
  }

  /// Get category color for UI display
  Color getCategoryColor(String category) {
    switch (category) {
      case '可回收物':
        return Colors.blue;
      case '有害垃圾':
        return Colors.red;
      case '厨余垃圾':
        return Colors.green;
      case '其他垃圾':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}