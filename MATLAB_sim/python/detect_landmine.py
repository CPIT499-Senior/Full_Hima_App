# detect_landmine.py

import os
import json
from ultralytics import YOLO
import cv2
import utm

# --- CONFIG ---

# 🔥 NEW: dynamically get the mission folder from environment variable
mission_folder = os.environ.get("HIMA_MISSION_FOLDER")
if mission_folder is None:
    raise ValueError("❌ HIMA_MISSION_FOLDER environment variable not set!")

scan_region_path = os.path.join(mission_folder, "scan_region.json")
output_json = os.path.join(mission_folder, "detected_landmines.json")
result_json = os.path.join(mission_folder, "result.json")

# Image frames folder (still fixed)
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
image_dir = os.path.join(base_dir, "MATLAB_sim", "data", "frames_for_detection")

# --- Load Region ---
with open(scan_region_path, 'r') as f:
    scan_region = json.load(f)

top_left = scan_region["top_left"]
bottom_right = scan_region["bottom_right"]

topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)

utmWidth = abs(bottomRightX - topLeftX)
utmHeight = abs(bottomRightY - topLeftY)

# --- Run Detection ---
model = YOLO("models/best.pt")
results = []

for fname in sorted(os.listdir(image_dir)):
    if not fname.lower().endswith(".jpg"):
        continue

    path = os.path.join(image_dir, fname)
    img = cv2.imread(path)
    h, w = img.shape[:2]

    detections = model(path)[0].boxes.xywh.cpu().numpy()

    for (cx, cy, _, _) in detections:
        relX = cx / w
        relY = cy / h
        utm_x = topLeftX + relX * utmWidth
        utm_y = topLeftY + relY * utmHeight
        lat, lon = utm.to_latlon(utm_x, utm_y, zone, northern=True)
        results.append({
            "lat": lat,
            "lon": lon,
            "source": fname
        })

# --- Save Outputs ---
with open(output_json, "w") as f:
    json.dump(results, f, indent=2)

# Remove writing empty "result.json" because MATLAB generates it properly

print(f"✅ YOLO detected {len(results)} landmines from drone-collected images:\n")
for r in results:
    print(f"- {r['source']}: ({r['lat']:.6f}, {r['lon']:.6f})")