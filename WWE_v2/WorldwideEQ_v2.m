% Plot earthquakes in real-time using USGS webservices.
%
%   REQUIREMENTS
%   1. Internet access
%   2. m_map (version since 2019) at 
%   (https://www.eoas.ubc.ca/~rich/map.html)
%   3. borders
%   (https://www.mathworks.com/matlabcentral/fileexchange/50390-borders)
%   4. etopo1_ice_g_i2 - Required for m_map
%   (https://www.eoas.ubc.ca/~rich/mapug.html#p9.3)
%
%   OPTIONAL
%   1. Download (or internet access) GEM Active faults shapefile
%   (https://github.com/GEMScienceTools/gem-global-active-faults)
%   
%
%   Version 2.0
%   - World map using 'borders'
%   - GEM global active fault map
%   - Plotting earthquakes using m_map
%   - Includes viewing table
%   - Improved titles and annotations
%   - Inside selection of earthquakes from USGS
%
%
%   Last modified on 28-Apr-2020
%   by Jeng Hann, Chong
%__________________________________________________________________________

clear all
clc
close all

% Change/addpath for 'm_map' and 'border'. 
addpath(genpath([pwd,'/m_map'])) 
addpath(genpath([pwd,'/borders']))
addpath(genpath([pwd,'/etopo1_ice_g_i2/']))

%%% Past duration of earthquakes - choose only one between (hour, day, week, month)
dur = 'hour'; % e.g: 'day'

%%% Minumum magnitude - choose only one between (significant, 1.0, 2.5, 4.5) 
siz = '1.0'; % e.g: '2.5'

%%% Do you want a table? 
Tablecheck = 1; % 1 = yes; 0 = no

%%% Do you want an inset?
Insetcheck = 1; % 1 = yes; 0 = no

%%% What do you want to see? [1: recent earthquake or 2: largest magnitude]
sorttype = 1;


tStart = tic; % starting stopwatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. Load EQ data
    % This is the website to select the earthquake parameters 
    % https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  close all
    
% Download feed from USGS here
options = weboptions('Timeout',15); % timeout after 15 seconds
% quakeDataJSON = webread('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.geojson',options);
quakeDataJSON = webread(['http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/',siz,'_',dur,'.geojson'], options);


quakeDataInfo = [quakeDataJSON.features.properties];
quakeDataLocation = [quakeDataJSON.features.geometry];

quakeTable = struct2table(quakeDataInfo);

eqproperties = [quakeDataLocation.coordinates]';
quakeTable.Lon = eqproperties(:,1);
quakeTable.Lat = eqproperties(:,2);
quakeTable.depth = eqproperties(:,3);
eqproperties(:,4) = quakeTable.mag ;

%%% Sort types based on [1: recent or 2: magnitude]

% Sorting here to get the largest magnitude or recent time
for sort = sorttype;
    fprintf('Starting to plot ... ')

    if sorttype == 2; % based on the magnitude
    eqproperties = sortrows(eqproperties,4); 
    slc_prop = eqproperties(end,:);
    fprintf('Largest magnitude\n')
    title_main = 'Largest';

    elseif sorttype == 1; % based on time
        slc_prop = eqproperties(1,:);% already from recent to oldest
        fprintf('Most recent earthquake\n')
        title_main = 'Most recent';

    end 
    
end 

% Set the range (bounding box) size
x1 = slc_prop(:,1)-2.55; 
x2 = slc_prop(:,1)+2.55;
y1 = slc_prop(:,2)+2.55;
y2 = slc_prop(:,2)-2.55;

% Bounding box
tl = [x1, y1];
tr = [x2, y1];
bl = [x1, y2];
br = [x2, y2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2.  Set up mapping and load some basemap files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

range                       = [x1+360 x2+360 y2 y1]; % longitude and latitude range for the map (adjust this to your preferred area)
mp                          = 'm_proj(''mercator'', ''long'', range(1:2) ,''lat'', range(3:4));';
mg                          = 'm_grid(''li  asxcvbnmnestyle'', ''none'', ''tickdir'', ''out'', ''yaxislocation'', ''left'', ''xaxislocation'', ''bottom'', ''ticklen'', 0.01, ''FontSize'', fs);';
mc                          = 'm_coast(''patch'',''r'')';
me                          = 'm_elev(''shadedrelief'',''gradient'',.5);' ;
% mr                          = 'm_ruler([.65 .95],.92,''tickdir'',''out'',''ticklen'',[.007 .007]);'; % Scale bar
mg2                         = 'm_grid(''box'',''fancy'',''tickdir'',''in'')';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. Set some defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

fs                          = 18; % fontsize
cmax                        = 50; % fault slip rate saturation value
patchmax                    = 50; % mesh slip rate saturation value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. Start mapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

h = figure('Position',[100 100 1600 800]);
A1 = axes('Position',[0.08 0.1 0.4 0.8]); %[x, y, width, height]

hold on;
eval(mp); eval(mg);% eval(mr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot Topo map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c1 = -3000:50:0; % color interval sea-based
c2 = 0:50:3000; % color interval land-based

[CS, CH]=m_etopo2('contourf',[c1 c2],'edgecolor','none');

% b = grayscale(256);
% b = b(50:end,:);
% 
% aa = colormap(b);

aa = colormap([ m_colmap('blues',length(c2)); m_colmap('gland',length(c2))]);

ax=m_contfbar([1.15],[.5 .8],CS,CH,'edgecolor','none'); % [x position, [size x size y]...]

title(ax,{'Elevation (meters)',''}); % Move up by inserting a blank line

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 6. Map coastlines and state lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

borders('countries','k')
borders('states','k','linewidth',0.2)

al = m_etopo2('shadedrelief','lightangle',-45,'gradient',70); % plot the hillshade

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Map faults using shape file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Global fault map from GEM
% The larger the area, the longer it takes to read and plot. 
% Internet accessed GEM fault will take a longer time to load

while 1

if isfile('gem_active_faults.shp') 

    S = shaperead('gem_active_faults.shp');
    
    fprintf('Using pre-downloaded GEM faults shapefile\n');
    
    %%% Finding faults one by one using pre-downloaded shapefile
    for ii = 1:numel(S)

    % Only plot faults within the bounding box
        if S(ii).BoundingBox(1,1)  >= range(1)-360 & S(ii).BoundingBox(2,1) <= range(2)-360 & ...
                S(ii).BoundingBox(1,2) >=range(3) & S(ii).BoundingBox(2,2) <= range(4)

            mx = S(ii).X; % get longitude of faults 
            my = S(ii).Y; % get latitude of faults

            hold on
            m_line(mx+360, my, 'color', 0*[1 1 1], 'linewidth', 1.2); % Plots fault lines individually
            hold on
        else
            continue
            break
        end
    end
    break
else
    
    % Using the webservices
    S2 = jsondecode(webread('https://raw.githubusercontent.com/GEMScienceTools/gem-global-active-faults/master/geojson/gem_active_faults.geojson',options));

    faultDataInfo = {S2.features.properties};
    faultDataLocation = [S2.features.geometry];

    fprintf('Using internet accessed GEM faults shapefile\n');
    
    %%% Finding faults one by one using internet accessed shapefile
    for ii = 1:numel(faultDataLocation)
    S = faultDataLocation(ii).coordinates;

    % Only plot faults within the bounding box
          if min(S(:,1)) >= range(1)-360 & max(S(:,1)) <= range(2)-360 & ...
                  min(S(:,2)) >= range(3) & max(S(:,2)) <= range(4)
              
            mx = S(:,1); % get longitude of faults 
            my = S(:,2); % get latitude of faults

            hold on
            m_line(mx+360, my, 'color', 0*[1 1 1], 'linewidth', 1.2); % Plots fault lines individually
            hold on
        else
            continue
        end

    end

    end
    break
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. Plot earthquake data within boundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find earthquakes within bounding box
format short
% Create table here
in_lon = quakeTable.Lon(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_lat = quakeTable.Lat(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));

in_dep = quakeTable.depth(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_mag = quakeTable.mag(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));

in_time = quakeTable.time(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_time = string(datetime(in_time/1000, 'convertfrom','posixtime')); % convert interger (millisec) to date and time

in_tsu = quakeTable.tsunami(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_place = quakeTable.place(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));

in_properties = [in_mag in_place in_time in_lon in_lat in_dep in_tsu];

hold on

%%% Plot earthquakes here
for iii = 1:numel(in_lon)

h3= m_line(in_lon(iii)+360,in_lat(iii),'marker','o','color','[0.0 0.0 0.0]','linewi',0.2,...
          'linest','none','markersize',round(in_mag(iii))*6,'markerfacecolor','[0.8500 0.3250 0.0980]');
end

%%% Plot the selected (latest/largest magnitude) earthquake
h4 = m_line(slc_prop(:,1)+360,slc_prop(:,2),'marker','o','color','[0 0 0]','linewi',0.2,...
          'linest','none','markersize',round(slc_prop(:,4))*6,'markerfacecolor','[0.1350 0.9780 0.1840]');

      
%%% Other figure properties
% Title of main figure
title([title_main, ' ', siz, '+ earthquakes in the past ', dur]) % make sure this is change accordingly based on the USGS data

% Annotation/Notes
dim = [.86 .5 .8 .46]; % [x,y,width,height]
str = ['Last refreshed on ', string(datetime)];
annotation('textbox',dim,'String',str,'FitBoxToText','on');

% Plotting legend
% h4 = m_line(in_lon(iii)+361,in_lat(iii)-91,'marker','o','color','[0.0 0.5 0.5]','linewi',0.1,...
%           'linest','none','markersize',1*7,'markerfacecolor','[0.9 0.0 0.0]');
% h5 = m_line(in_lon(iii)+361,in_lat(iii)-91,'marker','o','color','[0.0 0.5 0.5]','linewi',0.1,...
%           'linest','none','markersize',3*7,'markerfacecolor','[0.9 0.0 0.0]');
% h6 = m_line(in_lon(iii)+361,in_lat(iii)-91,'marker','o','color','[0.0 0.5 0.5]','linewi',0.1,...
%           'linest','none','markersize',6*7,'markerfacecolor','[0.9 0.0 0.0]');
% legend
% hleg = legend([h4 h5 h6],'1','3','6')
% title(hleg, 'Magnitude')set(gca,'Fontsize',16)

% Plot north arrow
% m_northarrow(range(1)-360+0.24,range(3)+0.25,.5,'type',4);

set(gca,'Fontsize',15)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Plot table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while 1
    if Tablecheck == 1 % only plots the inset if this is allowed 
    fprintf('Plotting table ... ')
    hold on
    uit = uitable(h,'Data',cellstr(in_properties),'Position',[970 420 505 250]);
    uit.RowName = 'numbered';
    uit.ColumnName = {'Magnitude','Place','Time','Lat','Lon','Depth','Tsunami'};
    uit.FontSize = 14;

    % The title of table
    txt_title_1 = uicontrol('Style', 'text', 'Position', [1150 670 200 20], 'Fontsize',15,'FontWeight','bold',...
        'String', 'Earthquakes in the region');
    
        fprintf('done\n')

    break 
    elseif Tablecheck == 0
        fprintf('Plotting table ... skipped\n')
        break 
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 10. Plot inset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Plot inset here
while 1
    if Insetcheck == 1 % only plots the inset if this is allowed 
    fprintf(['Plotting inset ... '])
    axes('parent',h,'position',[0.605 0.15 0.315 0.315]); % [x,y,width,height];

%%% Plotting borders
    borders('countries','facecolor','[0.7 0.7 0.7]')
    
    hold on
    borders('states','color','[0.4 0.4 0.4]','linewidth',0.2)
    xlim([-181 181])
    ylim([-91 91])
    
    h7= plot([x1 x1 x2 x2 x1],[y2 y1 y1 y2 y2], ...
    'linewi',1.5,'color','r'); % plot boundary of area of interest in inset
        
%         h8 = plot(slc_prop(:,1),slc_prop(:,2),'marker','x','color','[1
%         0...
%         0 ]','markersize',15); % marker

    % The title of the map
    txt_title_2 = uicontrol('Style', 'text', 'Position', [1150 380 200 20], 'Fontsize',15,'FontWeight','bold',...
        'String', 'World map view');
    
    fprintf('done\n')
    
        break
    elseif Insetcheck == 0
        fprintf('Plotting inset ... skipped\n')
        break
    end
end

set(gca,'Fontsize',15)

tEnd = toc(tStart); % Stopping stopwatch
disp(['Completed plot in ', num2str(tEnd),' s']);

refreshdata
