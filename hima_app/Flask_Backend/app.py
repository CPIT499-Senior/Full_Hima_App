from flask import Flask, request, jsonify, send_from_directory
import subprocess
import json
import os
from generate_path import generate_safe_path  # ✅ Import the A* Python path generator

app = Flask(__name__)

# 🛠 Utility: Auto-generate mission names
def get_next_mission_name():
    base_path = os.path.join('..', 'hima_app', 'missions')
    os.makedirs(base_path, exist_ok=True)
    existing = [d for d in os.listdir(base_path) if d.startswith("mission")]
    numbers = [int(d.replace("mission", "")) for d in existing if d.replace("mission", "").isdigit()]
    next_id = max(numbers, default=0) + 1
    return f"mission{next_id}"

# 🚀 Run a new mission
@app.route('/run-mission', methods=['POST'])
def run_mission():
    matlab_path = "/Applications/MATLAB_R2024b.app/bin/matlab"
    matlab_working_dir = "/Users/hebahturki/Full_Hima_App/MATLAB_sim"

    mission_name = get_next_mission_name()
    mission_folder = os.path.join('..', 'hima_app', 'missions', mission_name)
    os.makedirs(mission_folder, exist_ok=True)

    # Save input.json
    mission_data = request.json
    input_json_path = os.path.join(mission_folder, 'input.json')
    with open(input_json_path, 'w') as f:
        json.dump(mission_data, f, indent=4)

    # Run MATLAB (for YOLO detection)
    matlab_command = f"cd('{matlab_working_dir}'); main('{mission_name}')"
    try:
        subprocess.run([matlab_path, "-batch", matlab_command], check=True)
    except subprocess.CalledProcessError as e:
        return jsonify({'status': 'error', 'reason': 'MATLAB script failed'}), 500
    except FileNotFoundError:
        return jsonify({'status': 'error', 'reason': 'MATLAB not found'}), 500

    # ✅ After MATLAB finishes, generate the safe path with Python
    try:
        generate_safe_path(mission_folder)
    except Exception as e:
        return jsonify({'status': 'error', 'reason': f'Python path generation failed: {e}'}), 500

    # Load result.json
    result_path = os.path.join(mission_folder, 'result.json')
    if not os.path.isfile(result_path):
        return jsonify({'status': 'error', 'reason': 'result.json not found'}), 500

    with open(result_path) as f:
        result = json.load(f)

    return jsonify({
        'status': 'success',
        'mission': mission_name,
        'result': result
    }), 200

# 📋 List all missions
@app.route('/missions', methods=['GET'])
def list_missions():
    base_path = os.path.join('..', 'hima_app', 'missions')
    missions = []

    for folder in sorted(os.listdir(base_path)):
        result_file = os.path.join(base_path, folder, 'result.json')
        if os.path.isfile(result_file):
            try:
                with open(result_file, 'r') as f:
                    result = json.load(f)
                missions.append({
                    "id": folder,
                    "landmineCount": result.get("landmineCount", 0),
                    "pathPoints": len(result.get("safePath", []))
                })
            except Exception as e:
                print(f"⚠️ Failed to load {folder}: {e}")
                continue

    return jsonify(missions)

# 🗂️ Serve result.json and other static files
@app.route('/missions/<mission_id>/<filename>', methods=['GET'])
def serve_mission_file(mission_id, filename):
    try:
        base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "hima_app", "missions", mission_id))
        return send_from_directory(base_path, filename)
    except Exception as e:
        return jsonify({"error": f"File not found: {e}"}), 404

if __name__ == '__main__':
    app.run(debug=True)