import os
import shutil
from ultralytics import YOLO

def convert_model():
    pt_model_path = r"D:\GarbageClassify\product\garbage.pt"
    output_dir = "assets/models"
    output_tflite_path = os.path.join(output_dir, "garbage.tflite")

    print("原始模型路径:", pt_model_path)
    print("输出路径:", output_tflite_path)

    if not os.path.exists(pt_model_path):
        print("错误：原始模型文件不存在")
        return False

    os.makedirs(output_dir, exist_ok=True)

    try:
        print("加载 YOLO 模型...")
        model = YOLO(pt_model_path)

        print("导出为 TFLite 格式...")
        model.export(format="tflite", imgsz=640)

        tflite_files = list(os.listdir("."))
        tflite_files = [f for f in tflite_files if f.endswith(".tflite")]

        if not tflite_files:
            print("未找到导出的 TFLite 文件")
            return False

        converted_file = tflite_files[0]

        print(f"将 {converted_file} 移动到 {output_tflite_path}")
        shutil.move(converted_file, output_tflite_path)

        if os.path.exists(output_tflite_path):
            file_size = os.path.getsize(output_tflite_path)
            print(f"转换成功！")
            print(f"文件大小: {file_size / (1024*1024):.2f} MB")
            return True
        else:
            print("转换失败：文件未保存到指定位置")
            return False

    except Exception as e:
        print(f"转换过程中发生错误: {e}")
        return False

if __name__ == "__main__":
    print("PyTorch 到 TFLite 模型转换器")
    print("=" * 40)

    success = convert_model()

    if success:
        print("\n转换完成！")
    else:
        print("\n转换失败！")