# detect_landmine.py

from ultralytics import YOLO
import cv2
import utm
import os
import json
import sys

def detect_landmines_in_image(image_path, model, topLeftX, topLeftY, utmWidth, utmHeight, zone):
    image = cv2.imread(image_path)
    img_h, img_w = image.shape[:2]
    results = model(image)

    detections = []
    for box in results[0].boxes.xyxy:
        x_center = float((box[0] + box[2]) / 2)
        y_center = float((box[1] + box[3]) / 2)

        # Normalize coordinates to [0,1]
        x_ratio = x_center / img_w
        y_ratio = y_center / img_h

        # Scale to UTM range
        utm_x = topLeftX + x_ratio * utmWidth
        utm_y = topLeftY - y_ratio * utmHeight

        # Convert to lat/lon
        lat, lon = utm.to_latlon(utm_x, utm_y, zone, northern=True)
        detections.append({"lat": lat, "lon": lon})

    return detections

def main_script():
    mission_folder = os.environ.get("HIMA_MISSION_FOLDER")
    if mission_folder is None:
        raise ValueError("❌ HIMA_MISSION_FOLDER environment variable not set!")

    scan_region_path = os.path.join(mission_folder, "scan_region.json")
    output_json = os.path.join(mission_folder, "detected_landmines.json")

    with open(scan_region_path, 'r') as f:
        region = json.load(f)

    top_left = region["top_left"]
    bottom_right = region["bottom_right"]

    topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
    bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)
    utmWidth = abs(bottomRightX - topLeftX)
    utmHeight = abs(topLeftY - bottomRightY)

    model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'models', 'best.pt'))
    model = YOLO(model_path)

    image_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'frames_for_detection'))
    all_detections = []
    for image_file in os.listdir(image_dir):
        image_path = os.path.join(image_dir, image_file)
        detections = detect_landmines_in_image(
            image_path, model, topLeftX, topLeftY, utmWidth, utmHeight, zone
        )
        all_detections.extend(detections)

    with open(output_json, 'w') as f:
        json.dump(all_detections, f, indent=2)

def run():
    main_script()

if __name__ == "__main__":
    main_script()