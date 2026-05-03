import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限管理服务
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 检查并请求相机权限
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 检查并请求相册权限
  Future<bool> requestPhotoPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 使用 READ_MEDIA_IMAGES (Permission.photos)
      // 先尝试 photos 权限（Android 13+），如果不可用则回退到 storage
      var status = await Permission.photos.status;
      if (status.isGranted) return true;

      status = await Permission.photos.request();
      if (status.isGranted) return true;

      // Android 12 及以下回退到 storage 权限
      status = await Permission.storage.status;
      if (status.isGranted) return true;

      status = await Permission.storage.request();
      return status.isGranted;
    } else {
      // iOS
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  /// 检查相机权限状态
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// 检查相册权限状态
  Future<bool> checkPhotoPermission() async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        status = await Permission.photos.status;
      } else {
        status = await Permission.storage.status;
      }
    } else {
      status = await Permission.photos.status;
    }
    
    return status.isGranted;
  }

  /// 请求所有必要权限
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    results['camera'] = await requestCameraPermission();
    results['photos'] = await requestPhotoPermission();
    
    return results;
  }

  /// 检查是否所有权限都已授予
  Future<bool> hasAllPermissions() async {
    final cameraGranted = await checkCameraPermission();
    final photoGranted = await checkPhotoPermission();
    return cameraGranted && photoGranted;
  }

  /// 显示权限被拒绝的对话框
  void showPermissionDeniedDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限被拒绝'),
        content: Text('需要$permissionName权限才能正常使用应用功能。请在设置中开启权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 判断是否为 Android 13 及以上版本
  Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;
    // 简化判断，实际可以通过 platform channel 获取
    return false;
  }
}
