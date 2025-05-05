# test_detect_landmine.py
#python -m unittest test_detect_landmine

import unittest  # Python's built-in testing framework
from detect_landmine import detect_landmines_in_image  
from ultralytics import YOLO  # YOLOv8 model

class TestYOLOLandmineDetection(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Load your trained model
        cls.model = YOLO("../models/best.pt")

        # Set up dummy UTM region values for conversion calculations
        cls.topLeftX = 400000
        cls.topLeftY = 5000000
        cls.utmWidth = 100
        cls.utmHeight = 100
        cls.zone = 36  # Typical for Saudi Arabia

    # Test 1: Ensure a known landmine image produces detections
    def test_valid_image_detection(self):
        image_path = "landmine.jpg"
        results = detect_landmines_in_image(
            image_path, self.model,
            self.topLeftX, self.topLeftY,
            self.utmWidth, self.utmHeight,
            self.zone
        )
        self.assertIsInstance(results, list)
        self.assertGreaterEqual(len(results), 1)  # Expect at least one detection

    # Test 2: Ensure empty (non-landmine) image produces few or zero detections
    def test_empty_image_detection(self):
        image_path = "empty.png"
        results = detect_landmines_in_image(
            image_path, self.model,
            self.topLeftX, self.topLeftY,
            self.utmWidth, self.utmHeight,
            self.zone
        )
        self.assertIsInstance(results, list)
        self.assertLessEqual(len(results), 1)  # Allow one false positive max

# Entry point to run the tests
if __name__ == '__main__':
    unittest.main()
