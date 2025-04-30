# detect_landmine.py

import os
import json
from ultralytics import YOLO
import cv2
import utm

# ✅ Load environment-based mission path
mission_folder = os.environ.get("HIMA_MISSION_FOLDER")
if mission_folder is None:
    raise ValueError("❌ HIMA_MISSION_FOLDER environment variable not set!")

# ✅ Setup paths
scan_region_path = os.path.join(mission_folder, "scan_region.json")
output_json = os.path.join(mission_folder, "detected_landmines.json")
result_json_path = os.path.join(mission_folder, "result.json")

# ✅ Fixed input folder for thermal frames
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
image_dir = os.path.join(base_dir, "MATLAB_sim", "data", "frames_for_detection")

# ✅ Load YOLO model
model = YOLO("models/best.pt")

# ✅ Load region and convert to UTM
with open(scan_region_path, 'r') as f:
    scan_region = json.load(f)

top_left = scan_region.get("topLeft") or scan_region.get("top_left")
bottom_right = scan_region.get("bottomRight") or scan_region.get("bottom_right")

topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)

utmWidth = abs(bottomRightX - topLeftX)
utmHeight = abs(bottomRightY - topLeftY)

# ✅ Run detection
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

# ✅ Save detection results
with open(output_json, "w") as f:
    json.dump(results, f, indent=2)

# ✅ Also save result.json for Flask
result_data = {
    "landmineCount": len(results),
    "landmines": results
}
with open(result_json_path, "w") as f:
    json.dump(result_data, f, indent=2)

print(f"✅ YOLO detected {len(results)} landmines from drone-collected images.")