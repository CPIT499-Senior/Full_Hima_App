
import json
import heapq
import numpy as np
import os

# Grid configuration
GRID_SIZE = (2000, 2000)           # Number of cells (rows, columns)
CELL_SIZE_M = 2                    # Cell size in meters
METERS_PER_DEGREE = 111320         # Approx. meters per degree of latitude

# Converts GPS coordinates to grid coordinates.
def gps_to_grid(lat, lon, origin_lat, origin_lon):
    x = round((lat - origin_lat) * METERS_PER_DEGREE / CELL_SIZE_M)
    y = round((lon - origin_lon) * METERS_PER_DEGREE / (CELL_SIZE_M * np.cos(np.radians(origin_lat))))
    x = max(0, min(x, GRID_SIZE[0] - 1))    # Clamp to grid size
    y = max(0, min(y, GRID_SIZE[1] - 1))
    return x, y

# Converts grid coordinates back to GPS coordinates.
def grid_to_gps(x, y, origin_lat, origin_lon):
    lat = origin_lat + (x * CELL_SIZE_M / METERS_PER_DEGREE)
    lon = origin_lon + (y * CELL_SIZE_M / (METERS_PER_DEGREE * np.cos(np.radians(origin_lat))))
    return lat, lon

class AStarSafePath:
    # A* pathfinding algorithm on a grid with obstacles.
    def __init__(self, grid, start, goal):
        self.grid = np.copy(grid)
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

    # Manhattan distance heuristic.
    def heuristic(self, node, goal):
        return abs(node[0] - goal[0]) + abs(node[1] - goal[1])

    # Reconstructs the path from start to goal.
    def reconstruct_path(self):
        path = []
        current = self.goal
        while current in self.came_from:
            path.append(current)
            current = self.came_from[current]
        path.append(self.start)
        path.reverse()

        # Safety check: make sure the path doesn't go through blocked cells
        for x, y in path:
            if self.grid[x, y] > 0.49:
                raise ValueError(f"❌ A* returned path that enters blocked cell: ({x}, {y}) with value {self.grid[x, y]}")
        return path

    # Runs the A* search to find a safe path.
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
                    self.grid[neighbor] < 0.5 and
                    neighbor not in self.closed_list):
                    tentative_g_score = self.g_score[current] + 1
                    if tentative_g_score < self.g_score[neighbor]:
                        self.came_from[neighbor] = current
                        self.g_score[neighbor] = tentative_g_score
                        self.f_score[neighbor] = tentative_g_score + self.heuristic(neighbor, self.goal)
                        heapq.heappush(self.open_list, (self.f_score[neighbor], neighbor))
        return None

"""
    Main function to generate a safe path avoiding landmines.
    Reads input, runs A*, saves the result.
"""
def generate_safe_path(mission_folder):
    # File paths
    input_path = os.path.join(mission_folder, 'input.json')
    detected_path = os.path.join(mission_folder, 'detected_landmines.json')
    result_path = os.path.join(mission_folder, 'result.json')

    # Load input and detected landmines
    with open(input_path, 'r') as f:
        input_data = json.load(f)
    with open(detected_path, 'r') as f:
        landmines = json.load(f)

    start_lat, start_lon = input_data['start']
    end_lat, end_lon = input_data['end']
    origin_lat = min(start_lat, end_lat)
    origin_lon = min(start_lon, end_lon)

    # Mark danger zones around landmines
    landmine_positions = [(m['lat'], m['lon']) for m in landmines]
    danger_cells = set()
    for lat, lon in landmine_positions:
        x, y = gps_to_grid(lat, lon, origin_lat, origin_lon)
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                nx, ny = x + dx, y + dy
                if 0 <= nx < GRID_SIZE[0] and 0 <= ny < GRID_SIZE[1]:
                    danger_cells.add((nx, ny))

    # Create the grid (0 = free, 1 = danger)
    grid = np.zeros(GRID_SIZE)
    for cell in danger_cells:
        grid[cell] = 1

    # Convert start and goal to grid
    start_grid = gps_to_grid(start_lat, start_lon, origin_lat, origin_lon)
    goal_grid = gps_to_grid(end_lat, end_lon, origin_lat, origin_lon)

    # Run A* search
    astar = AStarSafePath(grid, start_grid, goal_grid)
    path_grid = astar.find_safe_path()
    if path_grid is None:
        raise ValueError("No valid safe path could be found!")
    
    # Convert grid path back to GPS
    safe_path = [grid_to_gps(x, y, origin_lat, origin_lon) for x, y in path_grid]
    grid_path = [(x, y) for x, y in path_grid]

    # Prepare and save result
    result = {
        'safePath': safe_path,
        'gridPath': grid_path,
        'detectedLandmines': landmines,
        'landmineCount': len(landmines)
    }

    with open(result_path, 'w') as f:
        json.dump(result, f, indent=4)

    print(f"✅ Safe path successfully saved to {result_path}")
