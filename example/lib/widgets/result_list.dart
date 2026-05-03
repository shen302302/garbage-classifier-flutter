import 'package:flutter/material.dart';
import '../services/yolo_service.dart';

/// 检测结果列表组件
class ResultList extends StatelessWidget {
  final List<YoloDetection> detections;

  const ResultList({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const Center(
        child: Text(
          '未检测到物体',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '检测到 ${detections.length} 个物体',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detections.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final detection = detections[index];
              return _ResultListItem(
                detection: detection,
                index: index + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultListItem extends StatelessWidget {
  final YoloDetection detection;
  final int index;

  const _ResultListItem({
    required this.detection,
    required this.index,
  });

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getCategoryName(String className) {
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

    if (recyclable.contains(className)) return '可回收物';
    if (hazardous.contains(className)) return '有害垃圾';
    if (kitchen.contains(className)) return '厨余垃圾';
    if (other.contains(className)) return '其他垃圾';
    return '待分类';
  }

  Color _getCategoryColor(String category) {
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
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _getCategoryName(detection.className);
    final categoryColor = _getCategoryColor(category);
    final confidenceColor = _getConfidenceColor(detection.confidence);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(detection.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: confidenceColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '置信度',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
