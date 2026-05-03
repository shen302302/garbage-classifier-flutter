#!/usr/bin/env python3
"""
简单直接的 PyTorch 到 TFLite 转换脚本
"""

import os
import sys
import shutil
from pathlib import Path

def convert_model():
    # 设置路径
    pt_model_path = r"D:\GarbageClassify\product\garbage.pt"
    output_dir = "assets/models"
    output_tflite_path = os.path.join(output_dir, "garbage.tflite")

    print(f"原始模型路径: {pt_model_path}")
    print(f"输出路径: {output_tflite_path}")

    # 检查原始模型文件
    if not os.path.exists(pt_model_path):
        print(f"❌ 错误：原始模型文件不存在：{pt_model_path}")
        return False

    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)

    try:
        # 尝试使用 Ultralytics 的导出功能
        print("🔄 正在尝试使用 Ultralytics YOLO 导出模型...")

        # 直接使用命令行工具
        from ultralytics import YOLO

        # 加载模型
        print("📂 加载 YOLO 模型...")
        model = YOLO(pt_model_path)

        # 导出为 TFLite
        print("🔄 导出为 TFLite 格式...")
        model.export(format="tflite", imgsz=640)

        # 查找导出的文件
        tflite_files = list(Path().glob("*.tflite"))
        if not tflite_files:
            print("❌ 未找到导出的 TFLite 文件")
            return False

        # 通常导出的是 yolov8n_float32.tflite 或类似的文件名
        converted_file = None
        for f in tflite_files:
            if f.suffix == '.tflite':
                converted_file = f
                break

        if not converted_file:
            print("❌ 未找到有效的 TFLite 文件")
            return False

        # 移动到目标位置
        print(f"📁 将 {converted_file} 移动到 {output_tflite_path}")
        shutil.move(str(converted_file), output_tflite_path)

        # 验证转换结果
        if os.path.exists(output_tflite_path):
            file_size = os.path.getsize(output_tflite_path)
            print(f"✅ 转换成功！")
            print(f"📊 文件大小: {file_size / (1024*1024):.2f} MB")
            print(f"📍 保存位置: {output_tflite_path}")
            return True
        else:
            print("❌ 转换失败：文件未保存到指定位置")
            return False

    except ImportError as e:
        print(f"❌ 导入错误: {e}")
        print("请确保已安装 ultralytics: pip install ultralytics")
        return False
    except Exception as e:
        print(f"❌ 转换过程中发生错误: {e}")
        return False
    finally:
        # 清理临时文件
        temp_files = list(Path().glob("*.tflite"))
        for f in temp_files:
            if str(f) != output_tflite_path:
                try:
                    f.unlink()
                    print(f"🧹 清理临时文件: {f}")
                except:
                    pass

if __name__ == "__main__":
    print("=" * 50)
    print("PyTorch 到 TFLite 模型转换器")
    print("=" * 50)

    success = convert_model()

    if success:
        print("\n✅ 转换完成！")
        print("\n📋 后续步骤：")
        print("1. 运行: flutter clean && flutter pub get")
        print("2. 运行: flutter build apk --debug")
        print("3. 使用新编译的 APK 进行测试")
    else:
        print("\n❌ 转换失败！")
        print("\n💡 可能的解决方案：")
        print("1. 检查 Python 版本 (推荐 3.8+)")
        print("2. 安装依赖: pip install ultralytics tensorflow")
        print("3. 确保原始模型文件存在且完整")