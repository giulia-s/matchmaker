% Example of the making of three data files for Matchmaker

% DESCRIPTION:
% data      cell array with N data series.
% depth     cell array with M depth (or time) scales.
% depth_no  vector of size N. Element number i tells which of the cells in 
%           "depth" that contains the depth scale belonging to the ith of 
%           the data series.
% species   cell array with the N names of the data series.
% colours   Nx3 array with RGB colour definition for the plotting.

clear;

% -------------------------------------------------------------------------
% CORE1
% Contains two data series with common depth scale.
data{1} = sin(0:0.01:10)+0.5*rand(1,1001);
data{2} = sin(0:0.01:10).^2+0.3*rand(1,1001);
depth{1} = 0:0.01:10;
depth_no = [1 1];  % Because both data series 1 and 2 share the same depth scale (number 1)
species = {'Series 1' 'Series 2'};
colours = [0 1 0; 1 0 0];
save('data/core1_data.mat',  'data', 'depth', 'depth_no', 'species', 'colours');

clear;
% -------------------------------------------------------------------------
% CORE2
% Contains three data series each with their own depth scale.
data{1} = cos(0:0.01:10)+0.5*rand(1,1001);
data{2} = cos(0:0.01:10).^2+0.2*rand(1,1001);
data{3} = cos(-2:0.001:7).^2+0.5*rand(1,9001);
depth{1} = 0:0.01:10;
depth{2} = 0:0.001:9; 
depth_no = [1 1 2];  % Data series 1 and 2 share the same depth scale (number 1), and data series 3 corresponds to depth scale 2.
species = {'Ser1' 'Ser2' 'Ser3'};
colours = [0 0 1; 0 1 0; 1 1 0];
save('data/core2_data.mat',  'data', 'depth', 'depth_no', 'species', 'colours');

clear;
% -------------------------------------------------------------------------
% CORE3
% Contains only one data series
data{1} = cos(3:0.001:8)+0.5*rand(1,5001);
depth{1} = 0:0.001:5;
depth_no = [1];  % Data series 1 and 2 share the same depth scale (number 1), and data series 3 corresponds to depth scale 2.
species = {'The only one'};
colours = [0.3 0.3 0.3];
save('data/core3_data.mat',  'data', 'depth', 'depth_no', 'species', 'colours');
