# detect_landmine.py

import os
import json
from ultralytics import YOLO
import cv2
import utm

# --- Reusable Function for Unit Testing ---
def detect_landmines_in_image(image_path, model, topLeftX, topLeftY, utmWidth, utmHeight, zone):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")

    h, w = img.shape[:2]
    detections = model(image_path)[0].boxes.xywh.cpu().numpy()

    results = []
    for (cx, cy, _, _) in detections:
        relX = cx / w
        relY = cy / h
        utm_x = topLeftX + relX * utmWidth
        utm_y = topLeftY + relY * utmHeight
        lat, lon = utm.to_latlon(utm_x, utm_y, zone, northern=True)
        results.append({
            "lat": lat,
            "lon": lon,
            "source": os.path.basename(image_path)
        })

    return results

# --- Main Script Execution ---

if __name__ == "__main__":
    # 🔥 Get mission folder from environment variable
    mission_folder = os.environ.get("HIMA_MISSION_FOLDER")
    if mission_folder is None:
        raise ValueError("❌ HIMA_MISSION_FOLDER environment variable not set!")

    # File paths
    scan_region_path = os.path.join(mission_folder, "scan_region.json")
    output_json = os.path.join(mission_folder, "detected_landmines.json")

    # Image directory
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    image_dir = os.path.join(base_dir, "MATLAB_sim", "data", "frames_for_detection")

    # Load scan region GPS bounds
    with open(scan_region_path, 'r') as f:
        scan_region = json.load(f)

    top_left = scan_region["top_left"]
    bottom_right = scan_region["bottom_right"]

    topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
    bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)

    utmWidth = abs(bottomRightX - topLeftX)
    utmHeight = abs(bottomRightY - topLeftY)

    # Load YOLOv8 model
    model = YOLO("models/best.pt")
    all_results = []

    # Run detection on all .jpg images
    for fname in sorted(os.listdir(image_dir)):
        if not fname.lower().endswith((".jpg", ".png")):
            continue

        img_path = os.path.join(image_dir, fname)
        detections = detect_landmines_in_image(
            img_path, model,
            topLeftX, topLeftY,
            utmWidth, utmHeight,
            zone
        )
        all_results.extend(detections)

    # Save results to JSON
    with open(output_json, "w") as f:
        json.dump(all_results, f, indent=2)

    # Print summary
    print(f"✅ YOLO detected {len(all_results)} landmines from drone-collected images:\n")
    for r in all_results:
        print(f"- {r['source']}: ({r['lat']:.6f}, {r['lon']:.6f})")
