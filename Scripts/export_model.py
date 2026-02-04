
import warnings
warnings.filterwarnings("ignore")

from ultralytics import YOLO
import torch

def export_model():
    print("🚀 Starting YOLO-World export process...")
    
    # 1. Load the pre-trained YOLO-Worldv2 model
    # 'yolov8s-worldv2.pt' is a good balance between speed and accuracy for mobile
    model_name = "yolov8s-worldv2.pt"
    print(f"📥 Loading model: {model_name}...")
    try:
        model = YOLO(model_name)
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return

    # 2. Define Custom Vocabulary (Offline Mode)
    # Since Core ML export typically freezes the classes, we define a rich set of common objects.
    print("📝 Setting custom vocabulary...")
    
    # Basic Objects (COCO + Common)
    base_objects = [
        # COCO
        "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light",
        "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
        "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
        "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard",
        "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
        "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
        "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone",
        "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
        "hair drier", "toothbrush",
        # Common
        "keys", "wallet", "credit card", "money", "pen", "pencil", "paper", "notebook",
        "glasses", "sunglasses", "hat", "cap", "shoes", "sneakers", "boots", "watch", "ring", "necklace", "earrings",
        "water bottle", "coffee mug", "headphones", "charger", "power bank", "cable", "door", "window", "floor", "ceiling",
        # Small Items
        "toothpick", "napkin", "tissue", "lighter", "matchbox", "stapler", "tape", "glue", "battery",
        "usb drive", "sd card", "sim card", "coin", "button", "zipper", "mask", "glove", "sock"
    ]

    # Colors
    colors = ["red", "green", "blue", "yellow", "orange", "purple", "pink", "black", "white", "gray", "brown"]

    # Objects that make sense to have colors
    colored_target_objects = [
        "person", # special case
        "car", "bicycle", "motorcycle", "bus", "truck", "boat",
        "backpack", "umbrella", "handbag", "suitcase", "tie",
        "sports ball", "bottle", "cup", "bowl", "chair", "couch", "bed",
        "laptop", "mouse", "keyboard", "cell phone",
        "book", "clock", "vase", "scissors", "teddy bear", "toothbrush",
        "keys", "wallet", "pen", "pencil", "notebook",
        "glasses", "hat", "cap", "shoes", "sneakers", "boots", "watch",
        "water bottle", "coffee mug", "headphones", "charger", "cable",
        "lighter", "mask", "glove", "sock"
    ]

    # Generate Combinations
    generated_objects = []
    
    # Add base objects first
    generated_objects.extend(base_objects)
    
    for obj in colored_target_objects:
        for color in colors:
            if obj == "person":
                generated_objects.append(f"person in {color}") # person in white
                generated_objects.append(f"person in {color} clothes") # person in white clothes
            else:
                generated_objects.append(f"{color} {obj}") # red car
    
    # Remove duplicates just in case
    final_vocabulary = sorted(list(set(generated_objects)))
    
    print(f"📊 Total classes: {len(final_vocabulary)}")
    print(f"👀 Sample classes: {final_vocabulary[:10]}")
    
    # Set classes in the model
    model.set_classes(final_vocabulary)
    
    # Save the custom model first (optional, but good for verification)
    custom_model_path = "custom_yolov8s_world.pt"
    model.save(custom_model_path)
    print(f"✅ Saved custom model with {len(final_vocabulary)} classes to {custom_model_path}")
    
    # 3. Export to Core ML
    print("⚙️  Exporting to Core ML (nms=True, int8=True)...")
    # We use int8 quantization to make it smaller and faster on ANE
    # nms=True adds Non-Maximum Suppression layers to the model, so we get final boxes directly
    try:
        model.export(
            format="coreml", 
            nms=True, 
            int8=True, # Enable Int8 Quantization for mobile efficiency
            features=False # We don't need intermediate features
        )
        print("🎉 Export successful! Model should be 'custom_yolov8s_world.mlpackage'")
    except Exception as e:
        print(f"❌ Export failed: {e}")
        # Retry without int8 if it fails (sometimes int8 calibration requires data)
        print("🔄 Retrying without Int8 quantization...")
        try:
            model.export(format="coreml", nms=True)
            print("🎉 Export successful (Float16)!")
        except Exception as e2:
            print(f"❌ Retry failed: {e2}")

if __name__ == "__main__":
    export_model()
