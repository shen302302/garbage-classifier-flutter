import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../services/settings_service.dart';
import '../services/log_export_service.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();

  double _confidenceThreshold = 0.5;
  String? _saveDirectory;
  bool _isLoading = true;

  // 日志设置
  bool _isLoggingEnabled = true;
  LogLevel _logLevel = LogLevel.info;
  int _logDaysToKeep = 7;
  bool _isExporting = false;
  bool _isClearingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    setState(() {
      _confidenceThreshold = _settingsService.getConfidenceThreshold();
      _saveDirectory = _settingsService.getSaveDirectory();
      _isLoggingEnabled = _settingsService.getIsLoggingEnabled();
      _logLevel = _settingsService.getLogLevel();
      _logDaysToKeep = _settingsService.getLogDaysToKeep();
      _isLoading = false;
    });
  }

  Future<void> _saveConfidenceThreshold(double value) async {
    await _settingsService.setConfidenceThreshold(value);
    setState(() {
      _confidenceThreshold = value;
    });
  }

  Future<void> _resetSaveDirectory() async {
    try {
      String? defaultDir;

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        defaultDir = externalDir?.path;
      } else if (Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        defaultDir = appDir.path;
      }

      if (defaultDir != null) {
        await _settingsService.setSaveDirectory(defaultDir);
        setState(() {
          _saveDirectory = defaultDir;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已重置为默认目录')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置目录失败: $e')),
        );
      }
    }
  }

  Future<void> _saveLoggingSettings() async {
    await _settingsService.setLogLevel(_logLevel);
    await _settingsService.setIsLoggingEnabled(_isLoggingEnabled);
    await _settingsService.setLogDaysToKeep(_logDaysToKeep);

    setState(() {
      // 更新状态
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志设置已保存')),
      );
    }
  }

  Future<void> _exportLogs() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final logExportService = LogExportService(context: context);
      await logExportService.exportLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    setState(() {
      _isClearingLogs = true;
    });

    try {
      final logExportService = LogExportService(context: context);
      await logExportService.clearLogs(context: context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已清除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isClearingLogs = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要将所有设置恢复为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.setConfidenceThreshold(0.5);
      await _settingsService.setSaveDirectory('');
      setState(() {
        _confidenceThreshold = 0.5;
        _saveDirectory = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已重置为默认值')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 置信度阈值设置
                _buildSectionTitle('识别设置'),
                _buildConfidenceCard(),
                const SizedBox(height: 24),
                
                // 保存目录设置
                _buildSectionTitle('存储设置'),
                _buildSaveDirectoryCard(),
                const SizedBox(height: 24),
                
                // 日志设置
                _buildSectionTitle('日志设置'),
                _buildLoggingSettingsCard(),
                const SizedBox(height: 24),

                // 日志操作
                _buildLogActionsCard(),
                const SizedBox(height: 24),

                // 重置按钮
                _buildResetButton(),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '置信度阈值',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前值: ${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '调整识别置信度阈值，值越高识别结果越严格',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _confidenceThreshold,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              label: '${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _confidenceThreshold = value;
                });
              },
              onChangeEnd: (value) {
                _saveConfidenceThreshold(value);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  '50%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveDirectoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '保存目录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '识别结果的保存位置',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveDirectory ?? '使用默认目录',
                      style: TextStyle(
                        fontSize: 14,
                        color: _saveDirectory != null ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetSaveDirectory,
                icon: const Icon(Icons.restore),
                label: const Text('重置为默认目录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetToDefault,
        icon: const Icon(Icons.restore),
        label: const Text('恢复默认设置'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggingSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '日志记录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '启用日志记录以帮助调试',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 日志开关
            SwitchListTile(
              title: const Text('启用日志记录'),
              subtitle: const Text('记录应用运行日志'),
              value: _isLoggingEnabled,
              onChanged: (value) {
                setState(() {
                  _isLoggingEnabled = value;
                });
              },
              activeColor: Colors.purple,
            ),
            const SizedBox(height: 16),
            // 日志级别选择
            const Text(
              '日志级别',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LogLevel.values.map((level) {
                final isSelected = _logLevel == level;
                Color color;
                String label;

                switch (level) {
                  case LogLevel.all:
                    color = Colors.teal;
                    label = '全部';
                    break;
                  case LogLevel.verbose:
                    color = Colors.cyan;
                    label = '详细';
                    break;
                  case LogLevel.debug:
                    color = Colors.blue;
                    label = '调试';
                    break;
                  case LogLevel.info:
                    color = Colors.green;
                    label = '信息';
                    break;
                  case LogLevel.warning:
                    color = Colors.orange;
                    label = '警告';
                    break;
                  case LogLevel.error:
                    color = Colors.red;
                    label = '错误';
                    break;
                  case LogLevel.off:
                    color = Colors.grey;
                    label = '关闭';
                    break;
                }

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _logLevel = level;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.grey[700],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 保留天数设置
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '日志保留天数',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _logDaysToKeep.toDouble(),
                              min: 1,
                              max: 30,
                              divisions: 29,
                              label: '$_logDaysToKeep 天',
                              onChanged: (value) {
                                setState(() {
                                  _logDaysToKeep = value.toInt();
                                });
                              },
                              activeColor: Colors.purple,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_logDaysToKeep',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '自动清理超过指定天数的日志',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.file_download,
                    color: Colors.indigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '日志操作',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '导出或清除日志文件',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportLogs,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.share),
                    label: const Text('导出日志'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isClearingLogs ? null : _clearLogs,
                    icon: _isClearingLogs
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('清除日志'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
