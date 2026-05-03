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

/// 设置数据模型
class AppSettings {
  final double confidenceThreshold;
  final String? saveDirectory;
  final LogLevel logLevel;
  final bool isLoggingEnabled;
  final int logDaysToKeep;

  AppSettings({
    this.confidenceThreshold = 0.5,
    this.saveDirectory,
    this.logLevel = LogLevel.info,
    this.isLoggingEnabled = true,
    this.logDaysToKeep = 7,
  });

  AppSettings copyWith({
    double? confidenceThreshold,
    String? saveDirectory,
    LogLevel? logLevel,
    bool? isLoggingEnabled,
    int? logDaysToKeep,
  }) {
    return AppSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      saveDirectory: saveDirectory ?? this.saveDirectory,
      logLevel: logLevel ?? this.logLevel,
      isLoggingEnabled: isLoggingEnabled ?? this.isLoggingEnabled,
      logDaysToKeep: logDaysToKeep ?? this.logDaysToKeep,
    );
  }
}

/// 设置管理服务
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  static const String _confidenceThresholdKey = 'confidence_threshold';
  static const String _saveDirectoryKey = 'save_directory';
  static const String _logLevelKey = 'log_level';
  static const String _isLoggingEnabledKey = 'is_logging_enabled';
  static const String _logDaysToKeepKey = 'log_days_to_keep';

  /// 初始化设置服务
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取置信度阈值
  double getConfidenceThreshold() {
    return _prefs?.getDouble(_confidenceThresholdKey) ?? 0.5;
  }

  /// 设置置信度阈值
  Future<bool> setConfidenceThreshold(double value) async {
    if (_prefs == null) await init();
    return await _prefs!.setDouble(_confidenceThresholdKey, value);
  }

  /// 获取保存目录
  String? getSaveDirectory() {
    return _prefs?.getString(_saveDirectoryKey);
  }

  /// 设置保存目录
  Future<bool> setSaveDirectory(String path) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_saveDirectoryKey, path);
  }

  /// 获取所有设置
  AppSettings getSettings() {
    return AppSettings(
      confidenceThreshold: getConfidenceThreshold(),
      saveDirectory: getSaveDirectory(),
    );
  }

  /// 保存所有设置
  Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) await init();
    await setConfidenceThreshold(settings.confidenceThreshold);
    if (settings.saveDirectory != null) {
      await setSaveDirectory(settings.saveDirectory!);
    }
    await setLogLevel(settings.logLevel);
    await setIsLoggingEnabled(settings.isLoggingEnabled);
    await setLogDaysToKeep(settings.logDaysToKeep);
  }

  /// 获取日志级别
  LogLevel getLogLevel() {
    final levelIndex = _prefs?.getInt(_logLevelKey) ?? 2; // 默认 INFO
    return LogLevel.values[levelIndex];
  }

  /// 设置日志级别
  Future<bool> setLogLevel(LogLevel level) async {
    if (_prefs == null) await init();
    return await _prefs!.setInt(_logLevelKey, level.index);
  }

  /// 获取是否启用日志
  bool getIsLoggingEnabled() {
    return _prefs?.getBool(_isLoggingEnabledKey) ?? true;
  }

  /// 设置是否启用日志
  Future<bool> setIsLoggingEnabled(bool enabled) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_isLoggingEnabledKey, enabled);
  }

  /// 获取日志保留天数
  int getLogDaysToKeep() {
    return _prefs?.getInt(_logDaysToKeepKey) ?? 7;
  }

  /// 设置日志保留天数
  Future<bool> setLogDaysToKeep(int days) async {
    if (_prefs == null) await init();
    return await _prefs!.setInt(_logDaysToKeepKey, days);
  }
}
