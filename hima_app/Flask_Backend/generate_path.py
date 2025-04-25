import json
import heapq
import numpy as np
import os

# Constants
GRID_SIZE = (2000, 2000)
CELL_SIZE_M = 2
METERS_PER_DEGREE = 111320

# Helper functions
def gps_to_grid(lat, lon, start_lat, start_lon):
    x = int((lat - start_lat) * METERS_PER_DEGREE / CELL_SIZE_M)
    y = int((lon - start_lon) * METERS_PER_DEGREE / (CELL_SIZE_M * np.cos(np.radians(start_lat))))
    x = max(0, min(x, GRID_SIZE[0] - 1))
    y = max(0, min(y, GRID_SIZE[1] - 1))
    return x, y

def grid_to_gps(x, y, start_lat, start_lon):
    lat = start_lat + (x * CELL_SIZE_M / METERS_PER_DEGREE)
    lon = start_lon + (y * CELL_SIZE_M / (METERS_PER_DEGREE * np.cos(np.radians(start_lat))))
    return lat, lon

# A* Algorithm
class AStarSafePath:
    def __init__(self, grid, start, goal):
        self.grid = grid
        self.start = start
        self.goal = goal
        self.open_list = []
        self.closed_list = set()
        self.came_from = {}
        self.g_score = {node: float('inf') for node in np.ndindex(grid.shape)}
        self.g_score[start] = 0
        self.f_score = {node: float('inf') for node in np.ndindex(grid.shape)}
        self.f_score[start] = self.heuristic(start, goal)
        heapq.heappush(self.open_list, (self.f_score[start], start))

    def heuristic(self, node, goal):
        return abs(node[0] - goal[0]) + abs(node[1] - goal[1])

    def reconstruct_path(self):
        path = []
        current = self.goal
        while current in self.came_from:
            path.append(current)
            current = self.came_from[current]
        path.append(self.start)
        path.reverse()
        return path

    def find_safe_path(self):
        directions = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]
        while self.open_list:
            _, current = heapq.heappop(self.open_list)
            if current == self.goal:
                return self.reconstruct_path()

            self.closed_list.add(current)
            for dx, dy in directions:
                neighbor = (current[0] + dx, current[1] + dy)
                if (0 <= neighbor[0] < self.grid.shape[0] and
                    0 <= neighbor[1] < self.grid.shape[1] and
                    self.grid[neighbor] == 0 and
                    neighbor not in self.closed_list):
                    tentative_g_score = self.g_score[current] + 1
                    if tentative_g_score < self.g_score[neighbor]:
                        self.came_from[neighbor] = current
                        self.g_score[neighbor] = tentative_g_score
                        self.f_score[neighbor] = tentative_g_score + self.heuristic(neighbor, self.goal)
                        heapq.heappush(self.open_list, (self.f_score[neighbor], neighbor))
        return None

# Main function to be called
def generate_safe_path(mission_folder):
    input_path = os.path.join(mission_folder, 'input.json')
    detected_path = os.path.join(mission_folder, 'detected_landmines.json')
    result_path = os.path.join(mission_folder, 'result.json')

    # Load input
    with open(input_path, 'r') as f:
        input_data = json.load(f)

    with open(detected_path, 'r') as f:
        landmines = json.load(f)

    start_lat, start_lon = input_data['start']
    end_lat, end_lon = input_data['end']

    landmine_positions = [(m['lat'], m['lon']) for m in landmines]

    # Build grid
    grid = np.zeros(GRID_SIZE)
    landmine_buffer = 2
    for lat, lon in landmine_positions:
        x, y = gps_to_grid(lat, lon, start_lat, start_lon)
        for dx in range(-landmine_buffer, landmine_buffer + 1):
            for dy in range(-landmine_buffer, landmine_buffer + 1):
                if 0 <= x+dx < GRID_SIZE[0] and 0 <= y+dy < GRID_SIZE[1]:
                    grid[x+dx, y+dy] = 1

    start_grid = gps_to_grid(start_lat, start_lon, start_lat, start_lon)
    goal_grid = gps_to_grid(end_lat, end_lon, start_lat, start_lon)

    # Run A*
    astar = AStarSafePath(grid, start_grid, goal_grid)
    path_grid = astar.find_safe_path()
    if path_grid is None:
        raise ValueError("No valid safe path could be found!")

    safe_path = [grid_to_gps(x, y, start_lat, start_lon) for x, y in path_grid]

    # Save output
    result = {
        'safePath': safe_path,
        'detectedLandmines': landmines,
        'landmineCount': len(landmines)
    }

    with open(result_path, 'w') as f:
        json.dump(result, f, indent=4)

    print(f"✅ Safe path successfully saved to {result_path}")

# If run standalone (optional)
if __name__ == "__main__":
    mission_folder = "../hima_app/missions/mission1"  # Adjust for your setup
    generate_safe_path(mission_folder)