// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/foundation.dart';
import 'logger_manager.dart';

/// 日志级别枚举（保持向后兼容）
enum YOLOLogLevel {
  debug,
  info,
  warning,
  error,
}

/// 旧版日志工具（保持向后兼容）
class YOLOLogger {
  /// 记录调试信息
  static void logDebug(String message) {
    if (kDebugMode) {
      print('[YOLO DEBUG] $message');
    }
    logger.d('YOLO: $message');
  }

  /// 记录信息
  static void logInfo(String message) {
    if (kDebugMode) {
      print('[YOLO INFO] $message');
    }
    logger.i('YOLO: $message');
  }

  /// 记录警告
  static void logWarning(String message) {
    if (kDebugMode) {
      print('[YOLO WARNING] $message');
    }
    logger.w('YOLO: $message');
  }

  /// 记录错误
  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[YOLO ERROR] $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
    }
    logger.e('YOLO: $message', error: error, stackTrace: stackTrace);
  }
}

/// 向后兼容的函数
void logInfo(String message) {
  YOLOLogger.logInfo(message);
}
