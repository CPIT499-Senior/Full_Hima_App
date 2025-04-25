function generate_path(missionFolder)
    %% Load inputs
    input = jsondecode(fileread(fullfile(missionFolder, 'input.json')));
    mines = jsondecode(fileread(fullfile(missionFolder, 'detected_landmines.json')));

    start_gps = input.start;  % [lat, lon]
    end_gps = input.end;      % [lat, lon]

    %% Convert start and end GPS to UTM
    resolution = 2; % meters per cell
    [sx, sy, utmZoneFull] = deg2utm(start_gps(1), start_gps(2));
    [ex, ey, ~] = deg2utm(end_gps(1), end_gps(2));
    
    utmZone = extractBefore(utmZoneFull, 3);  
    
    start_xy = round([sx, sy] / resolution);
    end_xy = round([ex, ey] / resolution);


    % Compute offset to align grid
    offset = floor(min([start_xy; end_xy], [], 1)) - 100;
    start_xy = start_xy - offset;
    end_xy = end_xy - offset;

    %% Create obstacle grid
    grid_size = 2000;
    obstacle_map = false(grid_size, grid_size);

    for i = 1:length(mines)
        [mx, my] = deg2utm(mines(i).lat, mines(i).lon);
        mxy = round([mx, my] / resolution) - offset;
        try
            obstacle_map(mxy(2)-2:mxy(2)+2, mxy(1)-2:mxy(1)+2) = true;
        catch
            continue
        end
    end

    %% Run A* pathfinding
    path_grid = astar(obstacle_map, start_xy, end_xy);

    if isempty(path_grid)
        error("❌ A* failed to generate a path. Path is empty.");
    end

    %% Convert path to GPS
    path_gps = [];
    for i = 1:size(path_grid,1)
        col = path_grid(i,1); % x
        row = path_grid(i,2); % y
        easting = (col + offset(1)) * resolution;
        northing = (row + offset(2)) * resolution;

        disp("Step " + i + ": col=" + col + ", row=" + row);
        disp("Easting: " + easting + ", Northing: " + northing + ", UTM Zone: " + utmZone);

        [lat, lon] = utm2deg(easting, northing, utmZone);

        if isempty(lon) || isempty(lat) || isnan(lat) || isnan(lon)
            error("❌ Invalid GPS point at step " + i);
        end

        path_gps(end+1,:) = [lat, lon];
    end

    %% Save result
    result.safePath = path_gps;
    result.landmineCount = length(mines);
    result.detectedLandmines = mines;

    outFile = fullfile(missionFolder, 'result.json');
    disp("💾 Writing result.json to: " + outFile);
    fid = fopen(outFile, 'w');
    fwrite(fid, jsonencode(result, 'PrettyPrint', true));
    fclose(fid);

    disp("✅ Safe path saved to mission folder.");
end