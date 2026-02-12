import warnings
warnings.filterwarnings("ignore")
import os
import shutil
from ultralytics import YOLO

def export_model_variant_direct(model_name, output_path):
    print(f"\n🚀 Starting export process for {model_name}...")
    
    # 1. Load the pre-trained YOLO-Worldv2 model
    print(f"📥 Loading model: {model_name}...")
    try:
        model = YOLO(model_name)
    except Exception as e:
        print(f"❌ Failed to load model {model_name}: {e}")
        
        # Check for corrupted file error
        error_msg = str(e)
        if "PytorchStreamReader failed reading zip archive" in error_msg or "failed finding central directory" in error_msg:
            print(f"⚠️  Detected corrupted model file: {model_name}")
            
            # Try to find the file in current directory
            if os.path.exists(model_name):
                print(f"🗑️  Deleting corrupted file: {model_name}")
                try:
                    os.remove(model_name)
                    print(f"🔄  Retrying download and load for {model_name}...")
                    model = YOLO(model_name)
                except Exception as retry_e:
                    print(f"❌ Retry failed: {retry_e}")
                    return
            else:
                print(f"❓ Model file {model_name} not found in current directory. Please manually delete it from your Ultralytics cache or working directory.")
                return
        else:
            return

    # 2. Define Custom Vocabulary (Offline Mode)
    print("📝 Setting custom vocabulary...")
    
    # Compact Vocabulary List
    # IMPORTANT: Keep this list small (~80 classes) for high confidence scores.
    # YOLO-World distributes confidence across ALL classes. More classes = lower per-class confidence.
    # Do NOT add color combinations (e.g. "red car") — they dilute confidence without improving detection.
    # The iOS app handles keyword matching at runtime.
    base_objects = [
        # --- People ---
        "person", "face", "hand",
        
        # --- Pets (daily life only, no wild animals) ---
        "cat", "dog",
        
        # --- Transport ---
        "bicycle", "car", "motorcycle", "bus", "truck",
        
        # --- Clothing & Accessories ---
        "backpack", "umbrella", "handbag", "tie", "suitcase",
        "hat", "glasses", "sunglasses",
        "shoe", "bag", "belt", "glove", "scarf", "mask",
        "watch", "ring", "necklace",
        
        # --- Kitchen & Dining ---
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl",
        "chopsticks", "plate", "pan", "pot",
        
        # --- Food & Drink ---
        "banana", "apple", "sandwich", "orange", "broccoli", "carrot",
        "pizza", "donut", "cake",
        
        # --- Furniture & Home ---
        "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv",
        "lamp", "clock", "vase", "pillow", "towel", "trash can",
        "mirror", "curtain", "door", "shelf", "box",
        
        # --- Electronics & Gadgets ---
        "laptop", "mouse", "remote", "keyboard", "cell phone", "tablet", "monitor",
        "camera", "headphones", "speaker",
        "charger", "power strip", "router", "printer",
        
        # --- Appliances ---
        "microwave", "oven", "toaster", "sink", "refrigerator",
        "washing machine", "fan", "hair drier",
        
        # --- Office & Stationery ---
        "book", "scissors", "pen", "pencil", "notebook", "ruler",
        "stapler", "tape", "eraser",
        
        # --- Personal Care ---
        "toothbrush", "toothpaste", "soap", "comb", "tissue",
        
        # --- Tools & Daily Misc ---
        "key", "lighter", "wallet",
        
        # --- Toys ---
        "teddy bear"
    ]

    # No color combinations — they severely dilute confidence.
    # The iOS app matches user queries (e.g. "鼠标"/"mouse") against detected base labels at runtime.
    final_vocabulary = sorted(list(set(base_objects)))
    
    print(f"📊 Total classes: {len(final_vocabulary)}")
    
    # Set classes in the model
    model.set_classes(final_vocabulary)
    
    # 3. Export to Core ML
    print("⚙️  Exporting to Core ML...")
    
    exported_filename = model_name.replace(".pt", ".mlpackage")
    
    try:
        # Export with half precision (float16) for best accuracy/size balance.
        # Avoid int8 quantization — it significantly degrades confidence scores.
        model.export(
            format="coreml", 
            nms=True, 
            half=True
        )
        print(f"🎉 Export successful: {exported_filename}")
        
        # Move to target directory
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        target_path = output_path
        
        # Clean existing
        if os.path.exists(target_path):
            shutil.rmtree(target_path)
            
        # Move and rename
        shutil.move(exported_filename, target_path)
        print(f"✅ Moved to: {target_path}")
        
    except Exception as e:
        print(f"❌ Export failed: {e}")
        print("🔄 Retrying with default precision...")
        try:
            model.export(format="coreml", nms=True)
            
            # Move to target directory
            output_dir = os.path.dirname(output_path)
            if output_dir and not os.path.exists(output_dir):
                os.makedirs(output_dir)
                
            target_path = output_path
            
            if os.path.exists(target_path):
                shutil.rmtree(target_path)
                
            shutil.move(exported_filename, target_path)
            print(f"✅ Moved to: {target_path}")
            
        except Exception as e2:
            print(f"❌ Retry failed: {e2}")

def main():
    # Define variants to export
    # Output distinct filenames for easier bundle access: ObjectDetectorS.mlpackage, ObjectDetectorM.mlpackage, etc.
    variants = [
        ("yolov8m-worldv2.pt", "FinderEye/Sources/Models/Resources/ObjectDetectorM.mlpackage"),
        ("yolov8l-worldv2.pt", "FinderEye/Sources/Models/Resources/ObjectDetectorL.mlpackage"),
        ("yolov8s-worldv2.pt", "FinderEye/Sources/Models/Resources/ObjectDetectorS.mlpackage"),
    ]
    
    for model_name, output_path in variants:
        # Note: export_model_variant function needs to be slightly adjusted or called differently 
        # because the original function took output_dir and appended "ObjectDetector.mlpackage"
        # Let's refactor export_model_variant slightly to handle full output path or directory
        export_model_variant_direct(model_name, output_path)

if __name__ == "__main__":
    main()
