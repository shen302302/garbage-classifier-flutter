import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/models/yolo_result.dart';
import '../../services/garbage_classification_service.dart';

/// A card that displays detailed garbage classification information
class GarbageInfoCard extends StatelessWidget {
  final YOLOResult detection;
  final GarbageClassificationService classificationService;
  final Function(YOLOResult)? onDetectionTap;

  const GarbageInfoCard({
    super.key,
    required this.detection,
    required this.classificationService,
    this.onDetectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GarbageClassification>(
      future: classificationService.classify(detection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('分类失败'));
        }

        final classification = snapshot.data!;
        final categoryColor = classificationService.getCategoryColor(classification.category);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => onDetectionTap?.call(detection),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        classification.className,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: categoryColor),
                        ),
                        child: Text(
                          classification.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '置信度: ${detection.confidence.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    classification.description,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '处理方法:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    classification.disposalMethod,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '小贴士:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    classification.tips,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}