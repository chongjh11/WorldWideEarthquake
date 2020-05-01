% Plot earthquakes in real-time using USGS webservices.
%
%   REQUIREMENTS
%   - Internet access
%   - mmap suite
%       - m_etopo2 and its DEM
%   - (OPTIONAL) Shapefiles
%
%   Version 1.0 
%   - Plotting earthquakes using mmap
%   - has specific range for plotting inset
%   - Manual changing of faults (shapefile only)
%
%   Version 2.0 published on 27-Apr-2020
%   Version 2.1 published on 31-May-2020
%   
%   Last modified on 29-Apr-2020
%   by Jeng Hann, Chong (jenghann.chong.43@my.csun.edu)
%
% MIT License
%
% Copyright (c) 2020 Jeng Hann Chong
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%__________________________________________________________________________


clear all
clc
close all

addpath(genpath([pwd,'/m_map'])) 
addpath(genpath([pwd,'/borders']))
addpath(genpath([pwd,'/etopo1_ice_g_i2/']))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Past duration of earthquakes - choose only one between (hour, day, week, month)
dur = 'month'; % e.g: 'day'

%%% Minumum magnitude - choose only one between (significant, 1.0, 2.5, 4.5) 
siz = '1.0'; % e.g: '2.5'

%%% Do you want an inset? It will take longer if yes.
Insetcheck = 1; % 1 = yes; 0 = no

%%% What do you want to see? [1: recent earthquake or 2: largest magnitude]
sorttype = 1;
% sorttype = 2;

%%% Setting up the parameters (range) for the region you are interested.
%%% All should be from -180 to 180 longitude. If no preference, set values
%%% of x1 = x2 and y1 = y2.

x1 = -119;   % longitude on the left
x2 = -117;   % longitude on the right
y2 = 33;     % latitude on the bottom
y1 = 35;     % latitude on the top

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. Load EQ data
    % This is the website to select the earthquake parameters 
    % https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
tStart = tic; % starting stopwatch

% Downloading feed from USGS
options = weboptions('Timeout',20);
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

% Automatic ranges if no range was set. 

if x1 == x2 && y2 == y1
    x1 = slc_prop(:,1)-2.55; 
    x2 = slc_prop(:,1)+2.55;
    y1 = slc_prop(:,2)+2.55;
    y2 = slc_prop(:,2)-2.55;
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2.  Set up mapping and load some basemap files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

range                       = [x1+360 x2+360 y2 y1]; % longitude and latitude range for the map (adjust this to your preferred area)
mp                          = 'm_proj(''mercator'', ''long'', range(1:2) ,''lat'', range(3:4));';
mg                          = 'm_grid(''li  asxcvbnmnestyle'', ''none'', ''tickdir'', ''out'', ''yaxislocation'', ''left'', ''xaxislocation'', ''bottom'', ''ticklen'', 0.01, ''FontSize'', fs);';
mc                          = 'm_coast(''patch'',''r'')';
me                          = 'm_elev(''shadedrelief'',''gradient'',.5);' ;
% mr                          = 'm_ruler([.65 .95],.92,''tickdir'',''out'',''ticklen'',[.007 .007]);'; % Scale bar

disp(['Plotting earthquakes within longitude of ' num2str(x1) char(176) ' to ' num2str(x2) char(176) ' latitude of ' ...
     num2str(y2) char(176) ' to ' num2str(y1) char(176)])

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
% 5. Plot topo map and title for color bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c1 = -3000:50:0; % color interval sea-based (meters)
c2 = 0:50:3000; % color interval land-based (meters)

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


al = m_etopo2('shadedrelief','lightangle',-45,'gradient',70); % plotting the hillshade

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Map faults using shape file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Optional (if do not want faults, comment section out)
S = shaperead('cafaults_dd.shp'); % change shape file here


% Finding and plotting faults one by one
    for ii = 1:numel(S)

    % Only plot faults within the bounding box
    if S(ii).BoundingBox(1,1)  >= range(1)-360 & S(ii).BoundingBox(2,1) <= range(2)-360 & ...
            S(ii).BoundingBox(1,2) >=range(3) & S(ii).BoundingBox(2,2) <= range(4)
        
        mx = S(ii).X; % get longitude of faults 
        my = S(ii).Y; % get latitude of faults
    
        hold on
        m_line(mx+360, my, 'color', 0*[1 1 1], 'linewidth', 1.2); % Plots fault lines individually
        hold on
        break
    else
        continue
        break
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
          'linest','none','markersize',round(slc_prop(:,4))*6,'markerfacecolor','[0.1350 0.9780 0.1840]');

      
%%% Other figure properties
% Title properties here
title([title_main, ' ', siz, '+ earthquakes in the past ', dur]) % make sure this is change accordingly based on the USGS data

% Annotation/Notes
dim = [.8 .5 .8 .46]; % [x,y,width,height]
str = ['Last refreshed on ', string(datetime)];
annotation('textbox',dim,'String',str,'FitBoxToText','on');

%%% You can set your legend for magnitude here
% hleg = legend([h4 h5 h6],'1','3','6')
% title(hleg, 'Magnitude')set(gca,'Fontsize',16)

% Plot north arrow
m_northarrow(range(1)-360+0.24,range(3)+0.25,.5,'type',4);

set(gca,'Fontsize',15)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Plot inset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Plot inset here
while 1
    if Insetcheck == 1 % only plots the inset if this is allowed 
    fprintf(['Plotting inset ... '])
    axes('parent',h,'position',[0.605 0.45 0.33 0.33]); % [x,y,width,height];

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

%%% The title of the map
    txt_title_2 = uicontrol('Style', 'text', 'Position', [1150 640 200 20], 'Fontsize',15,'FontWeight','bold',...
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
