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
    
    # Expanded Vocabulary List
    base_objects = [
        # --- People & Demographics ---
        "person", "man", "woman", "child", "boy", "girl", "baby", "elderly person",
        "face", "head", "eye", "hand", "foot",
        
        # --- Transport & Vehicles ---
        "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
        "scooter", "van", "suv", "taxi", "police car", "ambulance", "fire truck",
        "train door", "open train door", "closed train door",
        "wheelchair", "stroller", "skateboard", "surfboard",
        
        # --- Traffic & Street ---
        "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
        "street light", "crosswalk", "road sign",
        
        # --- Animals ---
        "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe",
        "rabbit", "mouse", "chicken", "duck", "goose", "pig", "monkey", "squirrel", "deer",
        "fish", "insect", "spider", "snake", "lizard", "turtle",
        
        # --- Accessories & Personal Items ---
        "backpack", "umbrella", "handbag", "tie", "suitcase", "wallet", "purse",
        "glasses", "sunglasses", "hat", "cap", "helmet", "mask", "glove", "scarf",
        "belt", "watch", "ring", "necklace", "earrings", "bracelet",
        "shoes", "sneakers", "boots", "sandals", "slippers", "flip flops", "high heels", "socks",
        
        # --- Sports & Recreation ---
        "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
        "tennis racket", "badminton racket", "ping pong paddle",
        "basketball", "soccer ball", "football", "tennis ball", "baseball", "volleyball",
        
        # --- Kitchen & Dining ---
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "plate", "dish",
        "chopsticks", "mug", "thermos", "kettle", "pot", "pan", "tray",
        
        # --- Food & Drink ---
        "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
        "fruit", "vegetable", "bread", "egg", "meat", "fish", "rice", "noodle",
        "candy", "cookie", "chocolate", "ice cream", "drink", "coffee", "tea", "water", "juice", "beer", "wine",
        
        # --- Furniture & Home ---
        "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv",
        "desk", "sofa", "armchair", "stool", "cabinet", "shelf", "wardrobe",
        "lamp", "mirror", "carpet", "curtain", "door handle", "door knob",
        "pillow", "blanket", "towel", "trash can", "box", "basket", "clock", "vase",
        "outlet", "power strip", "garbage bag",
        
        # --- Electronics & Gadgets ---
        "laptop", "mouse", "remote", "keyboard", "cell phone", "tablet", "monitor",
        "camera", "lens", "tripod", "headphones", "earbuds", "speaker", "microphone",
        "printer", "scanner", "router", "game controller", "console",
        "charger", "power bank", "cable", "usb drive", "sd card", "battery",
        "smart watch", "calculator",
        
        # --- Appliances ---
        "microwave", "oven", "toaster", "sink", "refrigerator", "washing machine", "dryer",
        "dishwasher", "fan", "air conditioner", "heater", "vacuum cleaner",
        "hair drier", "iron", "blender", "coffee maker",
        
        # --- Office & Stationery ---
        "book", "notebook", "paper", "pen", "pencil", "marker", "eraser",
        "stapler", "scissors", "tape", "glue", "clip", "folder", "envelope",
        
        # --- Tools & Hardware ---
        "hammer", "screwdriver", "wrench", "pliers", "saw", "drill",
        "ladder", "flashlight", "lock", "key", "chain", "rope",
        
        # --- Medical & Health ---
        "medicine", "pill", "bottle", "syringe", "thermometer", "bandage",
        "wheelchair", "crutch", "cane", "walker", "glasses",
        
        # --- Small Items & Others ---
        "toothpick", "napkin", "tissue", "lighter", "matchbox", "cigarette",
        "coin", "button", "zipper", "needle", "thread",
        "toy", "doll", "teddy bear", "balloon", "flag",

        # --- Bathroom & Personal Care ---
        "toothbrush", "toothpaste", "soap", "shampoo", "conditioner", "comb", "hairbrush", "razor", 
        "bathtub", "shower", "toilet paper", "towel rack",
        "cosmetics", "lipstick", "perfume", "fragrance", "foundation", "makeup brush", "nail polish",
        "body wash", "facial cleanser", "hand cream", "lotion", "cream", "hair clip", "nail clippers",

        # --- Bedroom & Bedding ---
        "mattress", "sheet", "quilt", "duvet", "nightstand",

        # --- Clothing & Fashion ---
        "shirt", "t-shirt", "pants", "trousers", "jeans", "shorts", "skirt", "dress", 
        "coat", "jacket", "sweater", "vest", "suit", "swimsuit", "pajamas", "underwear", "bra",

        # --- Musical Instruments ---
        "guitar", "violin", "piano", "drum", "flute", "trumpet", "saxophone", "cello",

        # --- Cleaning & Chores ---
        "broom", "mop", "bucket", "dustpan", "sponge", "detergent", "laundry basket",

        # --- Nature & Outdoors ---
        "tree", "grass", "flower", "rock", "stone", "mountain", "cloud", "sun", "moon", "star",
        "river", "lake", "ocean", "beach", "forest"
    ]

    # Colors
    colors = ["red", "green", "blue", "yellow", "orange", "purple", "pink", "black", "white", "gray", "brown", "gold", "silver", "beige"]

    # Objects that make sense to have colors (subset of base_objects)
    # We select objects where color is a primary distinguishing feature
    colored_target_objects = [
        # People
        "person", "man", "woman", "child", "boy", "girl",
        # Vehicles
        "car", "bicycle", "motorcycle", "bus", "truck", "boat", "scooter",
        # Accessories
        "backpack", "umbrella", "handbag", "suitcase", "tie", "hat", "cap", "helmet", "mask", "glove", "shoes", "sneakers", "boots", "socks",
        # Sports
        "sports ball", "basketball", "soccer ball",
        # Kitchen
        "bottle", "cup", "bowl", "plate", "mug",
        # Furniture
        "chair", "couch", "bed", "sofa", "pillow", "blanket", "towel", "curtain",
        # Electronics
        "laptop", "mouse", "keyboard", "cell phone", "tablet", "camera", "headphones", "speaker",
        # Stationery
        "book", "notebook", "pen", "pencil", "scissors",
        # Misc
        "vase", "teddy bear", "toy", "flower", "box", "bag", "clock"
    ]

    # Generate Combinations
    generated_objects = []
    
    # Add base objects first
    generated_objects.extend(base_objects)
    
    for obj in colored_target_objects:
        for color in colors:
            if obj in ["person", "man", "woman", "child", "boy", "girl"]:
                generated_objects.append(f"{obj} in {color}") # person in white
                generated_objects.append(f"{obj} in {color} clothes") # person in white clothes
            else:
                generated_objects.append(f"{color} {obj}") # red car
    
    # Remove duplicates
    final_vocabulary = sorted(list(set(generated_objects)))
    
    print(f"📊 Total classes: {len(final_vocabulary)}")
    
    # Set classes in the model
    model.set_classes(final_vocabulary)
    
    # 3. Export to Core ML
    print("⚙️  Exporting to Core ML...")
    
    exported_filename = model_name.replace(".pt", ".mlpackage")
    
    try:
        # Export
        model.export(
            format="coreml", 
            nms=True, 
            int8=True # Try Int8 first
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
        print("🔄 Retrying without Int8 quantization...")
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
