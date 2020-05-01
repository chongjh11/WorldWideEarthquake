% Plot EQ around the largest epicenter from the past 30 days
%
%   REQUIREMENTS
%   - Internet access
%   - mmap suite
%       - m_etopo2 and its DEM
%   - (OPTIONAL) Shapefiles
%
%   HISTORY
%   Version 1.0 
%   - Plotting earthquakes using mmap
%   - has specific range for plotting inset
%   - Manual changing of faults (shapefile only)
%   
%   Last modified on 24-Apr-2020
%   by Jeng Hann, Chong

clear all
clc
close all

addpath(genpath([pwd,'/m_map'])) 
addpath(genpath([pwd,'/borders']))
addpath(genpath([pwd,'/etopo1_ice_g_i2/']))
% addpath(genpath('')) - % add your own shapefile directory if needed

% Do you want an inset? It will take longer if yes.
Insetcheck = 1; % 1 = yes; 0 = no

% What do you want to see? [1: recent earthquake or 2: largest magnitude]
sorttype = 1;
% sorttype = 2;

tStart = tic; % starting stopwatch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. Load EQ data
    % This is the website to select the earthquake parameters 
    % https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    
% Downloading feed from USGS
options = weboptions('Timeout',20);
% quakeDataJSON = webread('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.geojson',options);
% quakeDataJSON = webread('http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson', options);
quakeDataJSON = webread('http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson', options);


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
    if sorttype == 2; % based on the magnitude
    eqproperties = sortrows(eqproperties,4); 
    slc_prop = eqproperties(end,:);

    elseif sorttype == 1; % based on time
        slc_prop = eqproperties(1,:);% already from recent to oldest
    end 
    
end 

% Set the range sizes 
x1 = slc_prop(:,1)-2.55; 
x2 = slc_prop(:,1)+2.55;
y1 = slc_prop(:,2)+2.55;
y2 = slc_prop(:,2)-2.55;


% Boundary box
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


load WorldHiVectors % this is a coastline file that should be included in the Blocks package
states                      = shaperead('usastatehi', 'UseGeoCoords', true, 'BoundingBox', [range(1:2)'-360, range(3:4)']); % loads in state boundaries (built into matlab)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. Set some defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

fs                          = 18; % fontsize
cmax                        = 50; % fault slip rate saturation value
patchmax                    = 50; % mesh slip rate saturation value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. Start mapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

h = figure('Position',[100 100 1400 800]);
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

ax=m_contfbar(1,[.5 .8],CS,CH,'edgecolor','none');

title(ax,{'Level/m',''}); % Move up by inserting a blank line

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 6. Map coastlines and state lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

m_patch(lon-360, lat,[1 1 1], 'EdgeColor', [0 0 0]); % plots coastlines
alpha('clear')


for j = 1:numel(states)
    m_line(states(j).Lon+360, states(j).Lat, 'color', 1*[1 1 1], 'linewidth', 0.5); % Plots state lines

end 


al = m_etopo2('shadedrelief','lightangle',-45,'gradient',70); % plotting the hillshade

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Map faults using shape file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Optional 
S = shaperead('cafaults_dd.shp'); % change shape file here


% Finding faults one by one
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
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. Plot earthquake data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find data within bounding box
format short
in_lon = quakeTable.Lon(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_lat = quakeTable.Lat(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_dep = quakeTable.depth(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_mag = quakeTable.mag(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_time = quakeTable.time(find(quakeTable.Lon >= x1 & quakeTable.Lon <= x2 & quakeTable.Lat >= y2 & quakeTable.Lat <= y1));
in_time = string(datetime(in_time/1000, 'convertfrom','posixtime'));

in_properties = [in_lon in_lat in_mag in_dep in_time];

hold on

%%% Plot earthquakes here
for iii = 1:numel(in_lon)

h3= m_line(in_lon(iii)+360,in_lat(iii),'marker','o','color','[0.0 0.0 0.0]','linewi',0.2,...
          'linest','none','markersize',round(in_mag(iii))*6,'markerfacecolor','[0.7 0.0 0.0]');
end

%%% Plot the selected (latest/largest magnitude) earthquake
h4 = m_line(slc_prop(:,1)+360,slc_prop(:,2),'marker','o','color','[0 0 0]','linewi',0.2,...
          'linest','none','markersize',round(slc_prop(:,4))*6,'markerfacecolor','[0.9 0.5 0.8]');

      
% Other figure properties
title({['Earthquakes in the past month/day']}) % make sure this is change accordingly based on the USGS data

% Annotation/Notes
dim = [.8 .5 .8 .46]; % [x,y,width,height]
str = ['Last refreshed on ', string(datetime)];
annotation('textbox',dim,'String',str,'FitBoxToText','on');

% legend
% hleg = legend([h4 h5 h6],'1','3','6')
% title(hleg, 'Magnitude')set(gca,'Fontsize',16)

% Plot north arrow
m_northarrow(range(1)-360+0.24,range(3)+0.25,.5,'type',4);

set(gca,'Fontsize',15)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Plot inset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change the range of inset if needed. Otherwise, just ignore the default.

yrange = 40; % all in degrees
xrange = 40;


%%% y2 range 
if y2-yrange < -90
    y2check = -90;
else
    y2check = y2-yrange;
end

%%% y1 range
if y1+yrange > 90
    y1check = 90;
else
    y1check = y1+yrange;
end
   
%%% For x-range
    while x2+xrange >= 0 & x1-xrange >=0 % for positive x2 and x1
            
            x2check = x2+xrange;
            x1check = x1-xrange;
        break
        
    end
    
    while  x2+xrange >= 0 & x1-xrange <0 % for positive x2 and negative x1
           
            x2check = x2+range;
            x1check = x1-xrange+360;
            
            break

    end  
    
    while x2+xrange < 0 & x1-xrange < 0 % for negative x2 and x1
        
        if x2+xrange+360 > 360
            x2check = 360;
            x1check = x1-xrange+360;
            break
        else
            x2check = x2+xrange+360;
            x1check = x1-xrange+360;
            break
        end
       
    end

% Plot inset here
while Insetcheck == 1 % only plots the inset if this is allowed 
    axes('parent',h,'position',[0.71 0.17 0.24 0.24]); % [x,y,width,height];
    
    range2                       = [x1check x2check y2check y1check]; % longitude and latitude range for the map (adjust this to your preferred area)
    mp2                          = 'm_proj(''mercator'', ''long'', range2(1:2) ,''lat'', range2(3:4));';
    mg2                          = 'm_grid(''linestyle'', ''none'',''xlabeldir'',''end'', ''tickdir'', ''out'', ''ticklen'', 0.02, ''FontSize'', 7);';
    mg2                          = 'm_grid(''linestyle'', ''none'',''xlabeldir'',''end'',''fontsize'',7)';

    load WorldHiVectors % this is a coastline file that should be included in the Blocks package
    states                      = shaperead('usastatehi', 'UseGeoCoords', true, 'BoundingBox', ...
        [range2(1:2)'-360, range2(3:4)']); % loads in state boundaries (built into matlab) % For USA only

    eval(mp2); eval(mg2);

    m_patch(lon-360, lat, 0.76*[1 1 1], 'EdgeColor', 'none'); % plots coastlines

    for j = 1:numel(states)
        m_line(states(j).Lon+360, states(j).Lat, 'color', 1*[1 1 1], 'linewidth', 0.8); % Plots state lines

    end 
    
    %%% Plot boundary of area of interest in inset
%     h4= m_line([x1check x1check x2check x2check x1check],[y2check y1check y1check y2check y2check], ...
%         'linewi',1.5,'color','r'); 

    if slc_prop(:,1) < 0 % this is for when selected EQ has negative longitude
        h4 = m_line(slc_prop(:,1)+360,slc_prop(:,2),'marker','x','color','[1 0 0 ]','markersize',15);

        break
        
    elseif slc_prop(:,1) > 0 % this is for when selected EQ has positive longitude
        h4 = m_line(slc_prop(:,1),slc_prop(:,2),'marker','x','color','[1 0 0 ]','markersize',15);

        break
    end
end

set(gca,'Fontsize',15)

tEnd = toc(tStart); % Stopping stopwatch
disp(['Completed plot in ', num2str(tEnd),' s']);
