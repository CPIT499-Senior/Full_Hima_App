function [x, y, utmzone] = deg2utm(Lat, Lon)
% DEG2UTM Converts geographic coordinates (latitude, longitude) to UTM.
% Converts lat/lon to UTM coordinates
% Source: USGS / Open implementation

% WGS84 ellipsoid constants
sa = 6378137.000000; sb = 6356752.314245; e2 = (((sa^2)-(sb^2))^(0.5))/sb;
e2cuadrada = e2^2; c = (sa^2)/sb; 

% Convert degrees to radians
lat = Lat * pi / 180; lon = Lon * pi / 180;

% Calculate UTM zone number
Huso = fix((Lon / 6) + 31);

% Central meridian of the zone
S = ((Huso * 6) - 183);

% Longitude difference from central meridian
deltaS = Lon - S; 

% Calculate UTM projection parameters
a = cos(lat) * sin(deltaS * pi / 180);
epsilon = 0.5 * log((1 + a) / (1 - a));
nu = atan(tan(lat) / cos(deltaS * pi / 180)) - lat;
v = (c / ((1 + (e2cuadrada * (cos(lat))^2))^0.5)) * 0.9996;
ta = (e2cuadrada / 2) * (epsilon^2) * (cos(lat))^2;
a1 = sin(2 * lat); a2 = a1 * (cos(lat))^2;
j2 = lat + (a1 / 2); j4 = (3 * j2 + a2) / 4;
j6 = (5 * j4 + a2 * (cos(lat))^2) / 3;

% Series expansion constants
alfa = (3 / 4) * e2cuadrada; beta = (5 / 3) * alfa^2;
gama = (35 / 27) * alfa^3;

% Calculate meridian arc length
Bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6);

% Compute UTM easting (x) and northing (y)
x = epsilon * v * (1 + (ta / 3)) + 500000;
y = nu * v * (1 + ta) + Bm;

% Adjust for southern hemisphere
if y < 0
    y = 9999999 + y;
end

% Build UTM zone string (number + latitude letter)
utmzone = [num2str(Huso), utmlatzone(Lat)];
end

function letra = utmlatzone(lat)
% Returns UTM latitude zone letter
zones = 'CDEFGHJKLMNPQRSTUVWXX';
zoneIdx = fix((lat + 80)/8) + 1;
zoneIdx = max(min(zoneIdx, length(zones)), 1);
letra = zones(zoneIdx);
end
