classdef visualizer < matlab.System ...
        & matlab.system.mixin.CustomIcon
    % Visualizer Creates and updates a bird's-eye plot.
    % The Visualization block is for display purposes and you will have
    % to disable it to set the model in 'Rapid Accelerator' mode.
    %
    % See also: birdsEyePlot
    % Copyright 2017-2018 The MathWorks, Inc.
    
    properties(Access=private)
        %pXLim Minimum and maximum distance in the longitudinal axis
        pXLim = [0 1000]
        
        %pYLim Minimum and maximum distance in the lateral axis
        pYLim = [-30 30]
        
        %pHasActors Display actors data
        pHasActors = true
        
        %pHasRoads Display road boundary data
        pHasRoads = true
        
        %pHasStats Display Statistics data
        pHasStats = true
        
        pFig
        pBEP
        pActorPlotter
        pActorProfile
        pLaneBoundaryPlotter
        pSimulinkUIToolbar
        pBlockName
        pIsLegendOn
        pBoundaryPlotters
        pBoundaryInputIndex
        pTableHandle
    end
    
    methods
        function obj = visualizer(varargin)
            % Constructor
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access=protected)
        
        function setupImpl(obj,varargin)
            wasFigureClosed = (isempty(obj.pFig) || ~ishghandle(obj.pFig));
            obj.pBlockName = gcb;
            if wasFigureClosed
                % Find the hidden figure handle
                root = groot;
                shh = get(root,'ShowHiddenHandles');
                set(root,'ShowHiddenHandles','on');
                hfig = findobj('Tag',obj.pBlockName);
                set(root,'ShowHiddenHandles',shh);
                if isempty(hfig)
                    hfig = figure('Name','Visualization','Tag',obj.pBlockName, ...
                        'Visible','off','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
                    obj.pIsLegendOn = true;
                else % Hide the figure while we build the bird's-eye plot
                    set(hfig,'Visible','off')
                    obj.pIsLegendOn = ~isempty(get(hfig.CurrentAxes,'Legend'));
                end
                obj.pFig = hfig;
            end
            % Create BEP before the toolbar because clf clears toolbars
            isBEPNeeded = (isempty(obj.pBEP) || wasFigureClosed);
            if isBEPNeeded
                clf(obj.pFig);
                hax = axes(obj.pFig);
                obj.pBEP = birdsEyePlot('Parent',hax,'XLim',obj.pXLim,'YLim',obj.pYLim);
                obj.pBEP.Parent.View = [0 90];
                if obj.pHasActors
                    obj.pActorPlotter = outlinePlotter(obj.pBEP);
                    obj.pActorProfile = struct( ...
                        'Length', 10, ...
                        'Width',5, ...
                        'OriginOffset', [-1.35 0]);
                end
                
                if obj.pHasRoads
                    grey = 0.3*ones(1,3);
                    obj.pLaneBoundaryPlotter = laneBoundaryPlotter(obj.pBEP,'DisplayName','Roads', 'Color', grey);
                end
                
            end
            
            % creating a table to display statistics
            if obj.pHasStats
                obj.pTableHandle = uitable(obj.pFig,'ColumnWidth',{'auto' 'auto' 620 'auto' 'auto'},'FontSize',12.5,'Units','normalized');
                obj.pTableHandle.ColumnName = {'Truck ID','Platoon Status','Reason','In Platoon with','Anticipated Fuel Savings(%)'};
                obj.pTableHandle.Position = [0.2500 0.6500 0.1651 0.0892];
                obj.pTableHandle.RowName = [];
                obj.pTableHandle.RowStriping = 'off';
            end
        end
        
        function resetImpl(obj)
            modelName = bdroot;
            
            % Create scope toolbar
            if isempty(obj.pFig.UserData) % Toolbar got cleared
                if isempty(obj.pSimulinkUIToolbar) % Toolbar was never created
                    t = findall(obj.pFig,'Type','uitoolbar');
                    if isempty(t)
                        t = uitoolbar(obj.pFig);
                    end
                    obj.pSimulinkUIToolbar = driving.internal.SimulinkUIToolbar(...
                        'Toolbar', t,...
                        'ModelName', modelName, ...
                        'BlockName', obj.pBlockName);
                else % Make sure that the toolbar is registered to model events
                    registerToModelButtonEvents(obj.pSimulinkUIToolbar);
                end
                userData.SimulinkUIToolbar = obj.pSimulinkUIToolbar;
                obj.pFig.UserData  = userData;
            else
                obj.pSimulinkUIToolbar = obj.pFig.UserData.SimulinkUIToolbar;
                registerToModelButtonEvents(obj.pSimulinkUIToolbar);
            end
            
            % Turn off the legend if it was off earlier
            if ~obj.pIsLegendOn
                legend(obj.pFig.CurrentAxes,'off')
            end
            
            % Bring the figure to front, set it to visible
            isDirty = get_param(bdroot,'Dirty');
            set_param(obj.pBlockName,'UserData',obj.pFig)
            set_param(obj.pBlockName,'OpenFcn','helperOpenFcn');
            set_param(bdroot,'Dirty',isDirty);
            set(obj.pFig,'Visible','on','HandleVisibility','off');
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            if ~isempty(obj.pFig.UserData)
                modelName = bdroot;
                isFastRestart = strcmp(get_param(modelName,'FastRestart'),'on');
                if isFastRestart %In fast restart mode, SimulationStatus is still 'running' at the end
                    setStoppedIcon(obj.pFig.UserData.SimulinkUIToolbar);
                else
                    update(obj.pFig.UserData.SimulinkUIToolbar);
                end
                release(obj.pFig.UserData.SimulinkUIToolbar);
            end
            dirtyFlag = get_param(bdroot,'Dirty');
            set_param(obj.pBlockName,'OpenFcn','');
            set_param(bdroot,'Dirty',dirtyFlag);
        end
        
        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            
            if isLocked(obj)
                s.pFig = obj.pFig;
                s.pBEP = obj.pBEP;
                s.pActorPlotter         = obj.pActorPlotter;
                s.pActorProfile         = obj.pActorProfile;
                s.pLaneBoundaryPlotter  = obj.pLaneBoundaryPlotter;
                s.pIsLegendOn           = obj.pIsLegendOn;
                s.pSimulinkUIToolbar    = saveobj(obj.pSimulinkUIToolbar);
            end
        end
        
        function loadObjectImpl(obj,s,wasLocked)
            if wasLocked
                obj.pFig = s.pFig;
                obj.pBEP = s.pBEP;
                obj.pActorPlotter           = s.pActorPlotter;
                obj.pActorProfile           = s.pActorProfile;
                obj.pLaneBoundaryPlotter    = s.pLaneBoundaryPlotter;
                obj.pIsLegendOn             = s.pIsLegendOn;
                obj.pSimulinkUIToolbar      = loadobj(s.pSimulinkUIToolbar);
                
                s = rmfield(s,{'pFig','pBEP','pActorPlotter','pActorProfile',...
                    'pLaneBoundaryPlotter','pSimulinkUIToolbar'});
            end
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end
        
        function stepImpl(obj,varargin)
            %Update the Simulink control toolbar
            update(obj.pFig.UserData.SimulinkUIToolbar);
            
            % Update the bird's-eye plot if it is visible
            if strcmp(get(obj.pFig, 'Visible'), 'on')
                idx = 1;
                
                if obj.pHasActors
                    actors = varargin{idx};
                    idx = idx+1;
                end
                
                if obj.pHasRoads
                    % Road boundaries are in global view by default
                    rbTruck = varargin{idx};
                    plotLanes(obj, rbTruck);
                    idx = idx+1;
                end
                
                if obj.pHasStats
                    stats = varargin{idx};
                    plotActors(obj, actors, stats);
                else
                    plotActors(obj, actors, 'null');
                end
            end
        end
    end
    
    methods(Access=private)
        function plotActors(obj, actorsBus,statsBus)
            
            if (isnumeric(actorsBus) && actorsBus == 0)
                % Input is disconnected, so return
                return
            end
            
            numActors = size(actorsBus,1);
            actorPoses = actorsBus;
            actorProfile = obj.pActorProfile;
            pos = NaN(numActors, 2);
            yaw = NaN(numActors, 1);
            
            % Global View of actors
            for m = 1 : numActors
                pos(m, :) = actorPoses(m).Position(1 : 2);
                yaw(m) = actorPoses(m).Yaw;
            end
            
            % To find the vehicle moving just ahead of origin
            min = inf;
            for m = 1 : numActors
                if min > pos(m, 1) && statsBus(m).PlatoonStatus ~= 2
                    min = pos(m, 1);
                end
            end
            
            % Dimensions of all the actors in visualization
            actorProfileLength = actorProfile.Length * ones(numActors, 1);
            actorProfileWidth = actorProfile.Width * ones(numActors, 1);
            
            % Generate the color vector for the actors
            rng(0,'v5uniform')
            actorColor = rand(numActors,3);
            
            % To display description for the table
            uicontrol(obj.pFig, 'Style', 'text', 'Position', [500 700 700 20], 'FontSize',12.5, 'String', '* Color of the row content matches the corresponding truck color');
            
            % Plot the statistics
            if obj.pHasStats
                plotStats(obj, statsBus, actorColor);
            end
            
            plotOutline(obj.pActorPlotter, pos, yaw, ...
                actorProfileLength, ...
                actorProfileWidth, ...
                'OriginOffset', ones(numActors, 1) * actorProfile.OriginOffset, 'Color', actorColor);
            
        end
        
        function plotLanes(obj, rbTruck)
            if (isnumeric(rbTruck) && isscalar(rbTruck) && rbTruck == 0)
                % Input is disconnected, so return
                return
            end
            plotLaneBoundary(obj.pLaneBoundaryPlotter, {rbTruck});
        end
        
        function plotStats(obj, stats, color)
            if (isnumeric(stats) && stats == 0)
                % Input is disconnected, so return
                return
            end
            
            numActors = size(stats, 1);
            data = cell(numActors, 3);
            hex = repmat('F',[1 7]);
            
            for i = 1 : numActors
                % To match the table row content color with the actor color
                rgb = round(color(i, :) * 255);
                hex(1, 2 : 7) = reshape(sprintf('%02X', rgb.'), 6, []).';
                hex(1,1) = '#';
                s1 = strcat(strcat('<html><body><table><tr><td><font color="', hex), '">');
                s2 = '</font></td></tr></table></body></html>';
                
                data(i, 1) = {strcat(strcat(s1, num2str(stats(i).ActorID)), s2)};
                data(i, 2) = {strcat(strcat(s1, 'No'), s2)};
                data(i, 4) = {strcat(strcat(s1, '-'), s2)};
                if stats(i).PlatoonStatus == 1
                    data(i, 2) = {strcat(strcat(s1, 'Yes'), s2)};
                    data(i, 3) = {strcat(strcat(s1, 'Anticipated to give better fuel efficiency'), s2)};
                    data(i, 4) = {strcat(strcat(s1, num2str(stats(i).VehicleAheadID)), s2)};
                elseif stats(i).PlatoonStatus == 2
                    data(i, 3) = {strcat(strcat(s1, 'Truck has reached the destination'), s2)};
                elseif stats(i).PlatoonStatus == 3
                    data(i, 3) = {strcat(strcat(s1, 'No truck ahead'), s2)};
                elseif stats(i).PlatoonStatus == 4
                    data(i, 3) = {strcat(strcat(s1, 'Truck cannot match up to the velocity of truck ahead'), s2)};
                elseif stats(i).PlatoonStatus == 5
                    data(i, 3) = {strcat(strcat(s1, 'Small overlapping journey'), s2)};
                elseif stats(i).PlatoonStatus == 6
                    data(i, 3) = {strcat(strcat(s1, 'The truck cannot cover the excess gap'), s2)};
                elseif stats(i).PlatoonStatus == 7
                    data(i, 3) = {strcat(strcat(s1, 'Anticipated to be more fuel consuming'), s2)};
                elseif stats(i).PlatoonStatus == 8
                    data(i, 3) = {strcat(strcat(s1, 'One of the trucks is anticipated to reach the destination before forming the platoon'), s2)};
                else
                    data(i, 2) = {strcat(strcat(s1, ''), s2)};
                end
                data(i,5) = {strcat(strcat(s1, num2str(stats(i).FuelSavings)), s2)};
            end
            
            obj.pTableHandle.Data = data;
            obj.pTableHandle.Position(3 : 4) = obj.pTableHandle.Extent(3 : 4);
        end
    end
    % Simulink interface
    methods(Access=protected)
        function str = getIconImpl(~)
            str = sprintf('Visualizer');
        end
        
        function num = getNumInputsImpl(obj)
            num = 0;
            
            if obj.pHasActors
                num = num+1;
            end
            if obj.pHasRoads
                num = num+1;
            end
            if obj.pHasStats
                num = num + 1;
            end
        end
        function varargout = getInputNamesImpl(obj)
            varargout = {};
            
            if obj.pHasActors
                varargout = {varargout{:} 'Actors'};
            end
            if obj.pHasRoads
                varargout = {varargout{:} 'Roads'};
            end
            if obj.pHasStats
                varargout = {varargout{:} 'Statistics'};
            end
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl
            % Define header panel for System block dialog
            header = matlab.system.display.Header(...
                'Title', 'Visualization',...
                'Text', getHeaderText());
        end
        
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
    end
end

function str = getHeaderText
str = sprintf('The Visualization block creates and maintains a bird''s-eye plot.');
end