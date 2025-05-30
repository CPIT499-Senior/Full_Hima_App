
import unittest
import os
import json
from generate_path import generate_safe_path, gps_to_grid, GRID_SIZE

class TestGenerateSafePath(unittest.TestCase):
# Unit tests for the safe path generation pipeline.
    def setUp(self):
        """
        Setup: create a test mission folder with input and landmine data.
        Runs before each test.
        """
        self.test_mission = 'tests/test_mission'
        os.makedirs(self.test_mission, exist_ok=True)

        # Write input.json (start and end GPS points)
        with open(os.path.join(self.test_mission, 'input.json'), 'w') as f:
            json.dump({
                "start": [21.0, 39.0],
                "end": [21.001, 39.001]
            }, f)

        # Write detected_landmines.json with one landmine
        with open(os.path.join(self.test_mission, 'detected_landmines.json'), 'w') as f:
            json.dump([
                {"lat": 21.0005, "lon": 39.0005}
            ], f)

    # Test: Ensure the result.json file is created after path generation.
    def test_generate_result_json(self):
        generate_safe_path(self.test_mission)
        result_path = os.path.join(self.test_mission, 'result.json')
        self.assertTrue(os.path.exists(result_path))
        print("✅ Result file creation test passed.")

    # Test: Check that the computed path avoids the landmine buffer zone.
    def test_path_avoids_landmine_buffer(self):
        generate_safe_path(self.test_mission)
        with open(os.path.join(self.test_mission, 'result.json')) as f:
            data = json.load(f)

        # Load start/end points to determine origin
        with open(os.path.join(self.test_mission, 'input.json')) as f:
            input_data = json.load(f)
        start_lat, start_lon = input_data["start"]
        end_lat, end_lon = input_data["end"]
        origin_lat = min(start_lat, end_lat)
        origin_lon = min(start_lon, end_lon)

        # Calculate danger zone grid cells (±2 buffer around landmine)
        landmine = (21.0005, 39.0005)
        landmine_x, landmine_y = gps_to_grid(landmine[0], landmine[1], origin_lat, origin_lon)
        buffer = 2
        danger_zone = set()
        for dx in range(-buffer, buffer + 1):
            for dy in range(-buffer, buffer + 1):
                x, y = landmine_x + dx, landmine_y + dy
                if 0 <= x < GRID_SIZE[0] and 0 <= y < GRID_SIZE[1]:
                    danger_zone.add((x, y))

        print("✅ [TEST] Danger zone:", sorted(danger_zone))

        # Ensure all path midpoints avoid the danger zone
        for x, y in data['gridPath'][1:-1]:
            print(f"📍 Grid path: ({x}, {y})")
            self.assertNotIn((x, y), danger_zone)
        print("✅ Grid path midpoints safely avoid landmine buffer.")

    def tearDown(self):
        """
        Cleanup: remove all test files and directory.
        Runs after each test.
        """
        for filename in ['input.json', 'detected_landmines.json', 'result.json']:
            path = os.path.join(self.test_mission, filename)
            if os.path.exists(path):
                os.remove(path)
        os.rmdir(self.test_mission)

if __name__ == '__main__':
    unittest.main()
