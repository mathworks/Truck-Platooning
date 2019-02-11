
% Copyright 2018 The MathWorks, Inc.

%% Initialization of parameters to be used by various model blocks
numTrucks = 0; % Number of trucks.It gets updated for each truck created
% and will have the total number of trucks, before model
% starts running.

% X-Pos of introduced trucks in the scenario. It is populated by trucks during initialization
% using their respective 'Initial X-position' mask  parameters.
truckXPosition = 0;
% X-Vel of introduced trucks in the scenario. It is populated by trucks during initialization
% using their respective 'Initial X-velocity' mask  parameters.
truckVelocity = 0;
% To store destination of actors. It is populated by trucks during initialization
% using their respective 'Destination X-Position' mask  parameters.
actorDest = 0;

% Lane Specification
laneSpecification = lanespec(1, 'Width', 50);
laneWidth = laneSpecification.Width;
roadInfoFileName = 'roadInfo';
% Workaround for passing string to MATLAB function
roadInfoFileNameU = uint8(roadInfoFileName);

%% Configurable parameters
maxVehicles = 25;
standStillGap = 10;
safeTimeGap = 1.4; % Vehicles must maintain atleast this time-gap (in seconds) w.r.t vehicle ahead for safety.
% Actor IDs trucks to start 'truckIdBase+1' onwards
truckIdBase = 0;
sensorRange = 600; % Vicinity range that trucks monitors around.
numPlans = 2; % Number of Plans. Must match with number of implemented plans in plan-library
minOverlapJourney = 200; % Trucks must have at least this much overlapping journey
% to even considering platooning
platoonFuelSavings = 20; % Percentage of fuel saved by a truck when it moves
% behind another as part of platoon. This saving is largely due to reduced aerodynamic drag.
simTime = 100;
scenario = drivingScenario('StopTime', simTime);
roadLength = 5000;
% Y-pos of the truck in the scenario.
initYPos = 0;
roadCenters = [5 initYPos 0;
    roadLength initYPos 0];
road(scenario, roadCenters, 'Lanes', laneSpecification);
RoadBoundaries = cell2struct(scenario.roadBoundaries, 'RoadBoundaries', 1);
save(roadInfoFileName,'-struct','RoadBoundaries','RoadBoundaries');
clear scenario laneSpecification RoadBoundaries;