import tensorflow as tf
import numpy as np
import os

def validate_model():
    model_path = "assets/models/garbage.tflite"

    print("TFLite 模型验证")
    print("模型路径:", model_path)

    if not os.path.exists(model_path):
        print("错误：模型文件不存在")
        return False

    file_size = os.path.getsize(model_path)
    print("文件大小:", file_size / (1024*1024), "MB")

    try:
        # 加载模型
        print("加载模型...")
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()

        # 获取输入输出信息
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print("输入详情:", input_details)
        print("输出详情:", output_details)

        # 创建测试输入
        input_shape = input_details[0]['shape']
        print("输入形状:", input_shape)

        # 创建测试图像
        height = input_shape[1] if len(input_shape) > 1 else 640
        width = input_shape[2] if len(input_shape) > 2 else 640
        test_image = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)

        # 预处理
        if input_details[0]['dtype'] == np.float32:
            test_image = test_image.astype(np.float32) / 255.0
            if len(input_shape) == 4:
                test_image = np.expand_dims(test_image, axis=0)
        else:
            test_image = np.expand_dims(test_image, axis=0)

        print("测试图像已创建:", test_image.shape)

        # 设置输入
        interpreter.set_tensor(input_details[0]['index'], test_image)

        # 运行推理
        print("执行推理...")
        interpreter.invoke()

        # 获取输出
        output_data = interpreter.get_tensor(output_details[0]['index'])

        print("推理成功!")
        print("输出形状:", output_data.shape)
        print("输出数据类型:", output_data.dtype)
        print("输出值范围:", np.min(output_data), np.max(output_data))

        print("模型验证成功！该TFLite文件可以正常使用。")
        return True

    except Exception as e:
        print("验证失败:", e)
        return False

if __name__ == "__main__":
    validate_model()