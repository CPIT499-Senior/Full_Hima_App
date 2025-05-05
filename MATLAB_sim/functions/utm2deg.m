% utm2deg.m
% Converts UTM coordinates to latitude and longitude
% Source: Open implementation

function [lat, lon] = utm2deg(x, y, zone)
    % Check if the UTM zone is provided as a string; convert to number if needed
    if ischar(zone)
        zone = str2double(zone);
    end

    % WGS84 ellipsoid constants
    sa = 6378137.000000; sb = 6356752.314245;
    e2 = ((sa^2 - sb^2) ^ 0.5) / sb;
    e2cuadrada = e2^2;
    c = (sa^2) / sb;
    
    % Remove false easting (500,000 m) and apply scale factor
    x = x - 500000;
    x = x / 0.9996;
    y = y / 0.9996;

    % Calculate the central meridian for the UTM zone
    S = ((zone * 6) - 183);

    % Initial estimate of latitude (in radians)
    lat = y / (6366197.724 * 0.9996);

    % Calculate radius of curvature in the prime vertical
    v = c / sqrt(1 + (e2cuadrada * (cos(lat))^2));

    % Calculate normalized coordinates
    a = x / v;

    % Compute series expansion terms for meridional arc
    a1 = sin(2 * lat);
    a2 = a1 * (cos(lat))^2;
    j2 = lat + ((a1 / 2));
    j4 = ((3 * j2) + a2) / 4;
    j6 = ((5 * j4) + (a2 * (cos(lat))^2)) / 3;
    % Calculate series expansion coefficients
    alfa = (3 / 4) * e2cuadrada;
    beta = (5 / 3) * alfa^2;
    gama = (35 / 27) * alfa^3;
    % Calculate the meridional arc length
    Bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6);

    % Calculate latitude and longitude corrections
    b = (y - Bm) / v;
    Epsi = ((e2cuadrada * a^2) / 2) * (cos(lat))^2;
    Eps = a * (1 - (Epsi / 3));
    nab = b * (1 - Epsi + (Epsi^2));

    % Calculate longitude in degrees
    lon = S + (Eps * (180 / pi));
    % Calculate latitude in degrees
    lat = lat - ((nab * (180 / pi)));

    % Clamp output if needed
    lat = max(min(lat, 90), -90);
    lon = mod((lon + 180), 360) - 180;
end

