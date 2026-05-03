// 日志导出服务

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:ultralytics_yolo/utils/logger_manager.dart';

/// 日志导出服务
class LogExportService {
  final BuildContext? context;

  LogExportService({this.context});

  /// 导出日志文件
  Future<void> exportLogs() async {
    final loggerManager = logger;

    try {
      // 获取所有日志文件
      final logFiles = await loggerManager.getLogFiles();

      if (logFiles.isEmpty) {
        throw Exception('没有找到日志文件');
      }

      // 创建临时目录
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory('${tempDir.path}/logs_export');
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      await exportDir.create(recursive: true);

      // 复制日志文件到临时目录
      for (final file in logFiles) {
        final fileName = file.uri.pathSegments.last;
        final targetFile = File('${exportDir.path}/$fileName');
        await file.copy(targetFile.path);
      }

      // 创建日志说明文件
      final readmeFile = File('${exportDir.path}/README.txt');
      final readmeContent = '''
日志文件导出说明
================

导出时间: ${DateTime.now().toString()}

日志文件说明:
- app_YYYY-MM-DD.log: 当天的日志文件
- archive/: 归档的日志文件目录

日志级别说明:
- DEBUG: 详细的调试信息
- INFO: 一般信息
- WARNING: 警告信息
- ERROR: 错误信息

请注意:
1. 日志文件可能包含敏感信息，请妥善保管
2. 建议定期清理旧的日志文件
3. 可在设置中配置日志保留天数
''';
      await readmeFile.writeAsString(readmeContent);

      // 打包所有文件
      final archive = Archive();

      // 添加日志文件
      for (final file in await exportDir.list().cast<File>().toList()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes));
      }

      // 创建ZIP文件
      final zipFile = File('${exportDir.path}/logs_export.zip');
      final zipBytes = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipBytes!);

      // 分享ZIP文件
      final box = context?.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(
          zipFile.path,
          name: 'garbage_classifier_logs_${DateTime.now().millisecondsSinceEpoch}.zip',
        )],
        subject: '垃圾分类应用日志文件',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );

      // 清理临时文件
      await exportDir.delete(recursive: true);
    } catch (e) {
      throw Exception('导出日志失败: $e');
    }
  }

  /// 清除所有日志文件
  Future<void> clearLogs({required BuildContext context}) async {
    final loggerManager = logger;

    try {
      // 获取所有日志文件
      final logFiles = await loggerManager.getLogFiles();

      // 删除所有日志文件
      for (final file in logFiles) {
        await file.delete();
      }

      // 清理归档目录
      final logDir = Directory('${loggerManager.logDirectory}/archive');
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('清除日志失败: $e');
    }
  }

  /// 获取日志文件大小统计
  Future<String> getLogSizeInfo() async {
    try {
      final loggerManager = logger;
      final logFiles = await loggerManager.getLogFiles();

      int totalSize = 0;
      int fileCount = 0;

      for (final file in logFiles) {
        if (await file.exists()) {
          totalSize += await file.length();
          fileCount++;
        }
      }

      if (fileCount == 0) {
        return '没有日志文件';
      }

      String formatSize(int bytes) {
        if (bytes < 1024) return '${bytes}B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }

      return '共 $fileCount 个文件，总大小 ${formatSize(totalSize)}';
    } catch (e) {
      return '获取信息失败: $e';
    }
  }

  /// 预览日志内容
  Future<String> previewLogContent({int maxLines = 50}) async {
    try {
      final loggerManager = logger;
      final logFiles = await loggerManager.getLogFiles();

      if (logFiles.isEmpty) {
        return '没有日志文件';
      }

      // 获取最新的日志文件
      final latestFile = logFiles.reduce((a, b) =>
        a.lastModifiedSync().isAfter(b.lastModifiedSync()) ? a : b);

      final lines = await latestFile.readAsLines();
      if (lines.length <= maxLines) {
        return lines.join('\n');
      }

      return [
        '...（显示最近的 $maxLines 行）...',
        ...lines.skip(lines.length - maxLines)
      ].join('\n');
    } catch (e) {
      return '预览失败: $e';
    }
  }
}