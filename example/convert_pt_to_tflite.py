#!/usr/bin/env python3
"""
将 PyTorch (.pt) 模型转换为 TFLite 格式
用于垃圾分类识别应用
"""

import torch
import tensorflow as tf
from ultralytics import YOLO
import os

def convert_to_tflite():
    # 设置路径
    pt_model_path = r"D:\GarbageClassify\product\garbage.pt"
    output_tflite_path = "assets/models/garbage.tflite"

    print("开始转换 PyTorch 模型到 TFLite 格式...")

    # 检查原始模型文件
    if not os.path.exists(pt_model_path):
        print(f"错误：原始模型文件不存在：{pt_model_path}")
        return False

    try:
        # 方法1：使用 Ultralytics YOLO 直接导出
        print("使用 Ultralytics YOLO 导出模型...")

        # 加载 YOLO 模型
        model = YOLO(pt_model_path)

        # 导出为 TFLite 格式
        model.export(format="tflite", imgsz=640)

        # 默认导出位置
        default_output = "yolov8n_float32.tflite"  # 假设是 YOLOv8n

        # 复制文件到目标位置
        if os.path.exists(default_output):
            os.makedirs(os.path.dirname(output_tflite_path), exist_ok=True)
            import shutil
            shutil.move(default_output, output_tflite_path)
            print(f"模型已成功转换并保存到：{output_tflite_path}")

            # 验证转换后的文件
            if os.path.exists(output_tflite_path):
                file_size = os.path.getsize(output_tflite_path)
                print(f"转换后文件大小：{file_size / (1024*1024):.2f} MB")
                return True
            else:
                print("错误：转换后的文件不存在")
                return False
        else:
            print(f"错误：导出的文件不存在：{default_output}")
            return False

    except Exception as e:
        print(f"使用 Ultralytics 导出失败：{e}")

        # 方法2：使用 PyTorch 和 TensorFlow 转换
        try:
            print("尝试使用 PyTorch + TensorFlow 转换...")

            # 加载 PyTorch 模型
            print("加载 PyTorch 模型...")
            model = torch.hub.load('ultralytics/yolov5', 'custom', path=pt_model_path)

            # 转换为 TensorFlow 模型
            print("转换为 TensorFlow 格式...")
            dummy_input = torch.randn(1, 3, 640, 640)
            traced_model = torch.jit.trace(model, dummy_input)

            # 保存为 TorchScript 格式
            torch_script_path = "models/garbage_scripted.pt"
            os.makedirs(os.path.dirname(torch_script_path), exist_ok=True)
            traced_model.save(torch_script_path)

            # 使用 TensorFlow Lite 转换器
            print("转换为 TFLite 格式...")

            # 加载 TorchScript 模型
            converter = tf.lite.TFLiteConverter.from_torchscript_file(torch_script_path)

            # 优化转换
            converter.optimizations = [tf.lite.Optimize.DEFAULT]

            # 转换
            tflite_model = converter.convert()

            # 保存 TFLite 模型
            with open(output_tflite_path, 'wb') as f:
                f.write(tflite_model)

            print(f"模型已成功转换并保存到：{output_tflite_path}")

            # 验证转换后的文件
            if os.path.exists(output_tflite_path):
                file_size = os.path.getsize(output_tflite_path)
                print(f"转换后文件大小：{file_size / (1024*1024):.2f} MB")
                return True
            else:
                print("错误：转换后的文件不存在")
                return False

        except Exception as e2:
            print(f"转换失败：{e2}")
            return False

if __name__ == "__main__":
    success = convert_to_tflite()
    if success:
        print("✅ 转换成功！")
    else:
        print("❌ 转换失败！")