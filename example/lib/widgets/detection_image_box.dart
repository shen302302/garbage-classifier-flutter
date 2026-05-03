import 'package:flutter/material.dart';
import 'dart:io';
import '../services/yolo_service.dart';

/// 显示带检测框的图片组件
class DetectionImageBox extends StatelessWidget {
  final File? imageFile;
  final Size? originalImageSize;
  final List<YoloDetection> detections;
  final bool isLoading;

  const DetectionImageBox({
    super.key,
    required this.imageFile,
    this.originalImageSize,
    required this.detections,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
        maxWidth: double.infinity,
      ),
      child: Stack(
        children: [
          // 显示原始图片
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              imageFile!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // 在图片上绘制检测框
          if (detections.isNotEmpty && originalImageSize != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: DetectionBoxPainter(
                      detections,
                      originalImageSize!,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),
          // 加载状态
          if (isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '正在处理...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 绘制检测框的画笔 — 自动适配 BoxFit.contain 的缩放与居中
class DetectionBoxPainter extends CustomPainter {
  final List<YoloDetection> detections;
  final Size originalImageSize;
  final Size containerSize;

  DetectionBoxPainter(this.detections, this.originalImageSize, this.containerSize);

  /// 计算 BoxFit.contain 模式下图片在容器内的实际显示区域
  Rect _containDisplayRect() {
    if (originalImageSize.isEmpty || containerSize.isEmpty) {
      return Rect.zero;
    }

    final imageAspect = originalImageSize.width / originalImageSize.height;
    final containerAspect = containerSize.width / containerSize.height;

    double displayWidth, displayHeight;
    if (imageAspect > containerAspect) {
      // 图片比容器更宽 → 按宽度适配
      displayWidth = containerSize.width;
      displayHeight = containerSize.width / imageAspect;
    } else {
      // 图片比容器更高 → 按高度适配
      displayHeight = containerSize.height;
      displayWidth = containerSize.height * imageAspect;
    }

    final offsetX = (containerSize.width - displayWidth) / 2;
    final offsetY = (containerSize.height - displayHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, displayWidth, displayHeight);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final displayRect = _containDisplayRect();
    if (displayRect.isEmpty) return;

    final scaleX = displayRect.width / originalImageSize.width;
    final scaleY = displayRect.height / originalImageSize.height;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final detection in detections) {
      final box = detection.boundingBox;

      // 从原图坐标变换到显示坐标
      final displayLeft = displayRect.left + box.left * scaleX;
      final displayTop = displayRect.top + box.top * scaleY;
      final displayWidth = box.width * scaleX;
      final displayHeight = box.height * scaleY;

      paint.color = _getBoxColor(detection.className);

      canvas.drawRect(
        Rect.fromLTWH(displayLeft, displayTop, displayWidth, displayHeight),
        paint,
      );

      // 绘制类别标签
      final labelText =
          '${detection.className} ${(detection.confidence * 100).toStringAsFixed(1)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      double textX = displayLeft;
      double textY = displayTop - textPainter.height;

      if (textY < 0) {
        textY = displayTop + displayHeight + 2;
      }
      if (textX + textPainter.width > size.width) {
        textX = size.width - textPainter.width - 4;
      }

      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color _getBoxColor(String className) {
    final recyclable = [
      '塑料器皿', '塑料玩具', '塑料衣架', '饮料瓶', '食用油桶',
      '易拉罐', '金属食品罐', '金属器皿', '金属厨具',
      '玻璃器皿', '酒瓶',
      '纸盒纸箱', '快递纸袋', '书籍纸张',
      '插头电线', '充电宝',
      '旧衣服', '毛绒玩具', '鞋', '包', '枕头',
      '锅', '调料瓶'
    ];
    final hazardous = ['过期药物', '软膏', '干电池'];
    final kitchen = [
      '剩饭剩菜', '果皮果肉', '菜帮菜叶', '茶叶渣',
      '蛋壳', '鱼骨', '大骨头', '筷子'
    ];
    final other = [
      '陶瓷器皿', '花盆', '垃圾桶',
      '污损塑料', '污损用纸',
      '烟蒂', '牙签',
      '一次性快餐盒', '砧板',
      '洗护用品'
    ];

    if (recyclable.contains(className)) return Colors.blue;
    if (hazardous.contains(className)) return Colors.red;
    if (kitchen.contains(className)) return Colors.green;
    if (other.contains(className)) return Colors.orange;
    return Colors.purple;
  }
}
