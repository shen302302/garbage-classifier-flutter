import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/models/yolo_result.dart';
import 'package:ultralytics_yolo/utils/map_converter.dart';

/// A widget that overlays detection results on an image
class DetectionOverlay extends StatelessWidget {
  final Uint8List image;
  final List<YOLOResult> detections;
  final Function(YOLOResult)? onDetectionTap;
  final bool showLabels;
  final bool showConfidence;

  const DetectionOverlay({
    super.key,
    required this.image,
    required this.detections,
    this.onDetectionTap,
    this.showLabels = true,
    this.showConfidence = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(image, fit: BoxFit.cover),
        ...detections.map((detection) => DetectionBox(
          detection: detection,
          onTap: onDetectionTap,
          showLabels: showLabels,
          showConfidence: showConfidence,
        )),
      ],
    );
  }
}

/// A widget that displays a single detection box with label and confidence
class DetectionBox extends StatelessWidget {
  final YOLOResult detection;
  final Function(YOLOResult)? onTap;
  final bool showLabels;
  final bool showConfidence;

  const DetectionBox({
    super.key,
    required this.detection,
    this.onTap,
    this.showLabels = true,
    this.showConfidence = true,
  });

  @override
  Widget build(BuildContext context) {
    final box = detection.boundingBox;
    final confidence = detection.confidence;
    final className = detection.className ?? '未知';

    return Positioned(
      left: box.left * MediaQuery.of(context).size.width,
      top: box.top * MediaQuery.of(context).size.height,
      width: (box.right - box.left) * MediaQuery.of(context).size.width,
      height: (box.bottom - box.top) * MediaQuery.of(context).size.height,
      child: GestureDetector(
        onTap: () => onTap?.call(detection),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _getColorForClass(className),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLabels)
                Container(
                  padding: const EdgeInsets.all(4.0),
                  color: _getColorForClass(className).withOpacity(0.8),
                  child: Row(
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (showConfidence)
                        Text(
                          ' ${confidence.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on class name for better visualization
  Color _getColorForClass(String className) {
    // Simple color mapping for common garbage types
    final colorMap = {
      'plastic': Colors.blue,
      'paper': Colors.green,
      'glass': Colors.yellow,
      'metal': Colors.red,
      'organic': Colors.orange,
      'hazardous': Colors.purple,
      'unknown': Colors.grey,
    };

    return colorMap.entries
        .firstWhere(
          (entry) => className.toLowerCase().contains(entry.key),
          orElse: () => const MapEntry('unknown', Colors.grey),
        )
        .value;
  }
}