function main(missionName)
    clc; close all;

    if nargin < 1
        error("❌ No mission name provided. Usage: main('mission1')");
    end

    % ✅ Robust path handling (supports folders with spaces)
    thisScriptDir = string(fileparts(mfilename('fullpath')));
    missionFolder = fullfile(thisScriptDir, "..", "hima_app", "missions", missionName);
    inputFile = fullfile(missionFolder, "input.json");

    disp("📍 Mission folder resolved to: " + missionFolder);
    disp("📄 Looking for input file at: " + inputFile);

    if ~isfile(inputFile)
        error("❌ input.json not found at: " + inputFile);
    end

    try
        inputData = jsondecode(fileread(inputFile));
        disp("✅ Input data loaded:");
        disp(inputData);

        % ✅ Auto-generate scan_region.json from input
        if isfield(inputData, "region")
            regionData = inputData.region;
            regionFilePath = fullfile(missionFolder, "scan_region.json");
            fid = fopen(regionFilePath, "w");
            fwrite(fid, jsonencode(regionData, "PrettyPrint", true));
            fclose(fid);
            disp("✅ scan_region.json auto-generated from input.");
        else
            error("❌ 'region' field not found in input.json. Cannot generate scan_region.json.");
        end

    catch
        error("❌ Failed to decode input.json. Check JSON format.");
    end

    % ✅ Clean setup
    clearvars -except missionName missionFolder thisScriptDir inputData
    addpath(fullfile(thisScriptDir, "functions"));
    addpath(fullfile(thisScriptDir, "scripts"));

    disp("🚀 Starting HIMA Simulation Pipeline...");

    %% Check required folders
    regionPath = fullfile(missionFolder, 'scan_region.json');
    if ~isfile(regionPath)
        error("❌ scan_region.json not found.");
    end

    imageFolder = fullfile(thisScriptDir, 'data', 'images');
    if ~isfolder(imageFolder)
        error("❌ data/images folder missing. Place thermal landmine images.");
    end

    %% Step 1: Create scan region
    disp("📍 Creating scan region...");
    try
        run(fullfile('scripts', 'create_sample_region.m'));
    catch ME
        error("❌ Failed to create region: " + ME.message);
    end

    %% Step 2: Download satellite map
    disp("🗺️ Downloading satellite map...");
    try
        run(fullfile('scripts', 'download_map_tiles.m'));
    catch ME
        error("❌ Satellite map error: " + ME.message);
    end

    %% Step 3: Place landmines
    disp("💣 Placing 10 landmines...");
    try
        run(fullfile('scripts', 'place_landmines.m'));
    catch ME
        error("❌ Landmine placement error: " + ME.message);
    end

    %% Step 4: Simulate drone flight
    disp("🚁 Simulating drone flight...");
    try
        run(fullfile('scripts', 'simulate_flight_3D.m'));
    catch ME
        error("❌ Drone simulation failed: " + ME.message);
    end

    %% Step 5: Run YOLO detection
    disp("🧠 Running YOLO detection...");
    try
        % Set mission folder path as an environment variable for Python
        setenv("HIMA_MISSION_FOLDER", missionFolder);

        % Call YOLO script
        py.runpy.run_path(fullfile(thisScriptDir, 'python', 'detect_landmine.py'));
    catch ME
        error("❌ YOLO detection failed: " + ME.message);
    end

    disp("✅ HIMA full simulation completed.");
end