// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日志级别枚举
enum LogLevel {
  all,
  verbose,
  debug,
  info,
  warning,
  error,
  off,
}

/// 日志管理器
class LoggerManager {
  static final LoggerManager _instance = LoggerManager._internal();
  factory LoggerManager() => _instance;
  LoggerManager._internal();

  late Logger _logger;
  LogLevel _currentLevel = LogLevel.info;
  bool _isFileLoggingEnabled = true;
  String? _logDirectory;
  String? _logFilePath;

  /// 初始化日志管理器
  Future<void> init() async {
    await _ensureLogDirectory();
    await _loadSettings();

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
      level: Level.all,
    );

    // 如果启用了文件日志，安排定期清理
    if (_isFileLoggingEnabled) {
      _scheduleDailyCleanup();
    }
  }

  /// 确保日志目录存在
  Future<void> _ensureLogDirectory() async {
    if (_logDirectory == null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      _logDirectory = '${appDocDir.path}/logs';

      final logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
    }

    _logFilePath = '$_logDirectory/app_${_getTodayDateString()}.log';
  }

  /// 获取今天的日期字符串
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载日志级别
    final levelIndex = prefs.getInt('log_level') ?? 3; // 默认 INFO
    _currentLevel = LogLevel.values[levelIndex];

    // 加载文件日志开关
    _isFileLoggingEnabled = prefs.getBool('file_logging_enabled') ?? true;
  }

  /// 更新日志级别（由 _log() 方法内部过滤，无需操作 Logger 实例）

  /// 记录日志
  void _log(Level level, String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLevel == LogLevel.off) return;
    if (level.index < _currentLevel.index) return;

    // 创建自定义的打印方法，添加文件输出
    if (_isFileLoggingEnabled && _logFilePath != null) {
      _logToFile(level, message, error, stackTrace);
    }

    // 使用原始 logger 打印到控制台
    switch (level) {
      case Level.all:
      case Level.verbose:
        _logger.v(message, error: error, stackTrace: stackTrace);
        break;
      case Level.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
        break;
      case Level.info:
        _logger.i(message, error: error, stackTrace: stackTrace);
        break;
      case Level.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
        break;
      case Level.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
        break;
      case Level.wtf:
        _logger.wtf(message, error: error, stackTrace: stackTrace);
        break;
      case Level.trace:
        _logger.t(message, error: error, stackTrace: stackTrace);
        break;
      case Level.fatal:
        _logger.f(message, error: error, stackTrace: stackTrace);
        break;
      case Level.off:
      case Level.nothing:
        break;
      default:
        _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// 写入日志到文件
  Future<void> _logToFile(Level level, String message, [dynamic error, StackTrace? stackTrace]) async {
    try {
      final timestamp = DateTime.now().toString();
      final levelStr = level.name.toUpperCase();
      final logEntry = '[$timestamp] [$levelStr] $message';

      // 写入日志文件
      await File(_logFilePath!).writeAsString(
        '$logEntry\n',
        mode: FileMode.append,
      );

      // 如果包含错误信息，也写入错误详情
      if (error != null || stackTrace != null) {
        await File(_logFilePath!).writeAsString(
          'Error: ${error.toString()}\n'
          'Stack Trace: ${stackTrace.toString()}\n',
          mode: FileMode.append,
        );
      }

      // 检查日志文件大小，如果超过 5MB 则轮转
      await _checkAndRotateLog();
    } catch (e) {
      // 文件写入失败时不影响应用运行
      print('Failed to write to log file: $e');
    }
  }

  /// 检查并轮转日志文件
  Future<void> _checkAndRotateLog() async {
    if (_logFilePath == null) return;

    final logFile = File(_logFilePath!);
    if (await logFile.exists()) {
      final fileSize = await logFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSize) {
        final archiveName = 'app_${_getTodayDateString()}_${DateTime.now().millisecondsSinceEpoch}.log';
        final archivePath = '$_logDirectory/archive/$archiveName';

        // 创建归档目录
        final archiveDir = Directory('$_logDirectory/archive');
        if (!await archiveDir.exists()) {
          await archiveDir.create(recursive: true);
        }

        // 移动当前日志文件到归档
        await logFile.rename(archivePath);

        // 创建新的日志文件
        _logFilePath = '$_logDirectory/app_${_getTodayDateString()}.log';
        await File(_logFilePath!).create();
      }
    }
  }

  /// 手动清理日志文件
  Future<void> cleanLogs({int? daysToKeep}) async {
    final days = daysToKeep ?? 7; // 默认保留7天
    logger.i('Manually cleaning logs older than $days days');
    await cleanOldLogs(days);
  }

  /// 清理旧日志文件
  Future<void> cleanOldLogs(int daysToKeep) async {
    try {
      if (_logDirectory == null) return;

      final logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      // 清理主日志目录中的旧文件
      final logFiles = logDir.listSync();
      for (final file in logFiles) {
        if (file is File) {
          final fileDate = DateTime.fromMillisecondsSinceEpoch(
            await file.lastModified().then((ms) => ms.millisecondsSinceEpoch),
          );

          if (fileDate.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }

      // 清理归档目录
      final archiveDir = Directory('$_logDirectory/archive');
      if (await archiveDir.exists()) {
        final archiveFiles = archiveDir.listSync();
        for (final file in archiveFiles) {
          if (file is File) {
            final fileDate = DateTime.fromMillisecondsSinceEpoch(
              await file.lastModified().then((ms) => ms.millisecondsSinceEpoch),
            );

            if (fileDate.isBefore(cutoffDate)) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to clean old logs: $e');
    }
  }

  /// 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    if (_logDirectory == null) return [];

    final logDir = Directory(_logDirectory!);
    if (!await logDir.exists()) return [];

    final files = <File>[];

    // 获取当前日志文件
    if (_logFilePath != null) {
      final currentLogFile = File(_logFilePath!);
      if (await currentLogFile.exists()) {
        files.add(currentLogFile);
      }
    }

    // 获取归档日志文件
    final archiveDir = Directory('$_logDirectory/archive');
    if (await archiveDir.exists()) {
      final archiveFiles = archiveDir.listSync()
          .where((file) => file is File)
          .cast<File>()
          .toList();
      files.addAll(archiveFiles);
    }

    return files;
  }

  // 公共方法
  void d(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(Level.debug, message, error, stackTrace);
  }

  void i(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(Level.info, message, error, stackTrace);
  }

  void w(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(Level.warning, message, error, stackTrace);
  }

  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(Level.error, message, error, stackTrace);
  }

  void v(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(Level.verbose, message, error, stackTrace);
  }

  /// 设置日志级别
  Future<void> setLogLevel(LogLevel level) async {
    _currentLevel = level;
    // 日志级别由 _log() 方法内部过滤，无需更新 Logger 实例

    // 保存设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('log_level', level.index);
  }

  /// 设置是否启用文件日志
  Future<void> setFileLoggingEnabled(bool enabled) async {
    _isFileLoggingEnabled = enabled;

    // 保存设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('file_logging_enabled', enabled);
  }

  /// 获取当前日志级别
  LogLevel get currentLevel => _currentLevel;

  /// 是否启用文件日志
  bool get isFileLoggingEnabled => _isFileLoggingEnabled;

  /// 获取日志目录
  String? get logDirectory => _logDirectory;

  /// 安排每日清理
  void _scheduleDailyCleanup() {
    // 在每天凌晨2点执行清理
    final now = DateTime.now();
    final nextCleanup = DateTime(
      now.year,
      now.month,
      now.day,
      2,  // 凌晨2点
      0,
      0,
    );

    // 如果已经过了今天凌晨2点，安排到明天
    if (now.isAfter(nextCleanup)) {
      nextCleanup.add(const Duration(days: 1));
    }

    final duration = nextCleanup.difference(now);

    Future.delayed(duration, () async {
      await cleanOldLogs(7); // 默认保留7天
      _scheduleDailyCleanup(); // 安排下一次清理
    });
  }
}

/// 全局日志实例
final logger = LoggerManager();