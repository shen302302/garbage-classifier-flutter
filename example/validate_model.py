import tensorflow as tf
import numpy as np
import cv2
import os

def validate_tflite_model():
    model_path = "assets/models/garbage.tflite"

    print("=== TFLite 模型验证工具 ===")
    print(f"模型路径: {model_path}")

    # 检查文件是否存在
    if not os.path.exists(model_path):
        print("❌ 错误：模型文件不存在")
        return False

    # 检查文件大小
    file_size = os.path.getsize(model_path)
    print(f"📊 文件大小: {file_size / (1024*1024):.2f} MB")

    try:
        # 加载TFLite模型
        print("\n🔄 加载TFLite模型...")
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()

        # 获取输入输出信息
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print(f"📥 输入详情: {input_details}")
        print(f"📤 输出详情: {output_details}")

        # 创建测试输入（使用合理的尺寸，比如640x640）
        input_shape = input_details[0]['shape']
        print(f"\n📏 输入形状: {input_shape}")

        # 创建一个虚拟的测试图像
        height = input_shape[1] if len(input_shape) > 1 else 640
        width = input_shape[2] if len(input_shape) > 2 else 640

        # 创建一个RGB测试图像
        test_image = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)

        # 预处理图像
        if input_details[0]['dtype'] == np.float32:
            # 标准化到0-1
            test_image = test_image.astype(np.float32) / 255.0
            # 如果需要调整形状
            if len(input_shape) == 4:  # [batch, height, width, channels]
                test_image = np.expand_dims(test_image, axis=0)
        else:
            # uint8 格式
            test_image = np.expand_dims(test_image, axis=0)

        print(f"\n✅ 测试图像已创建: {test_image.shape}")
        print(f"✅ 数据类型: {test_image.dtype}")

        # 设置输入
        print("\n⚙️ 设置输入...")
        interpreter.set_tensor(input_details[0]['index'], test_image)

        # 运行推理
        print("\n🚀 执行推理...")
        interpreter.invoke()

        # 获取输出
        output_data = interpreter.get_tensor(output_details[0]['index'])

        print(f"\n✅ 推理成功！")
        print(f"📤 输出形状: {output_data.shape}")
        print(f"📤 输出数据类型: {output_data.dtype}")
        print(f"📤 输出值范围: [{np.min(output_data):.4f}, {np.max(output_data):.4f}]")

        # 如果输出有形状，显示前几个值
        if output_data.size > 0:
            print(f"📤 输出样本（前10个值）: {output_data.flatten()[:10]}")

        print("\n🎉 模型验证成功！该TFLite文件可以正常使用。")
        return True

    except Exception as e:
        print(f"\n❌ 验证失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    validate_tflite_model()