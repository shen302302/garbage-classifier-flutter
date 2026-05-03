#!/usr/bin/env python3
"""
基础的 PyTorch 到 TFLite 转换脚本
不依赖 Ultralytics，只使用基本的 PyTorch 和 TensorFlow
"""

import os
import torch
import tensorflow as tf
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
        print("🔄 正在加载 PyTorch 模型...")

        # 加载模型
        model = torch.hub.load('ultralytics/yolov5', 'custom', path=pt_model_path)

        # 设置为评估模式
        model.eval()

        # 创建示例输入
        print("📝 创建示例输入...")
        dummy_input = torch.randn(1, 3, 640, 640)

        # 导出为 TorchScript
        print("🔄 转换为 TorchScript...")
        traced_model = torch.jit.trace(model, dummy_input)

        # 临时 TorchScript 文件
        temp_script_path = "temp_scripted.pt"
        traced_model.save(temp_script_path)
        print(f"✅ TorchScript 文件已保存: {temp_script_path}")

        # 转换为 TFLite
        print("🔄 转换为 TFLite 格式...")
        converter = tf.lite.TFLiteConverter.from_torchscript_file(temp_script_path)

        # 优化设置
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

        # 转换
        tflite_model = converter.convert()

        # 保存 TFLite 模型
        with open(output_tflite_path, 'wb') as f:
            f.write(tflite_model)

        # 清理临时文件
        if os.path.exists(temp_script_path):
            os.remove(temp_script_path)

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

    except Exception as e:
        print(f"❌ 转换过程中发生错误: {e}")

        # 清理临时文件
        temp_files = ["temp_scripted.pt"]
        for f in temp_files:
            if os.path.exists(f):
                os.remove(f)

        return False

if __name__ == "__main__":
    print("=" * 50)
    print("基础 PyTorch 到 TFLite 模型转换器")
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
        print("1. 确保已安装 PyTorch: pip install torch torchvision")
        print("2. 确保已安装 TensorFlow: pip install tensorflow")
        print("3. 确保已安装 Ultralytics: pip install ultralytics")