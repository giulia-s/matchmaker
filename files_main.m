% File name array for Matchmaker
%         1        2        3        4        5        6
% Order : Core1    Core2    etc.

files.core{1} = 'Core1';
files.datafile{1} = 'core1_data.mat';
files.matchfile{1} = 'CORE1_core123match.mat';
% optional, secondary mp file:
files.matchfile_secondary{1} = 'CORE1_core123match_secondary.mat';

files.core{2} = 'Core2';
files.datafile{2} = 'core2_data.mat';
files.matchfile{2} = 'CORE2_core123match.mat';
% optional, secondary mp file:
files.matchfile_secondary{2} = 'CORE2_core123match_secondary.mat';

files.core{3} = 'Core3';
files.datafile{3} = 'core3_data.mat';
files.matchfile{3} = 'CORE3_core123match.mat';
% optional, secondary mp file:
files.matchfile_secondary{3} = 'CORE3_core123match_secondary.mat';

% FILL IN THE RIGHT NAMES, for example:
% files.core{4} = 'NGRIP2';
% files.datafile{4} = 'NGRIP2_data.mat';
% files.matchfile{4} = 'NGRIP2_match_project_NGRIPvsGISP.mat';
% 
% files.core{5} = 'GISP2';
% files.datafile{5} = 'GISP2_data.mat';
% files.matchfile{5} = 'GISP2_match_project_NGRIPvsGISP.mat';


% NOTE the matchfile names used. There has to be a file for each core, but
% the files comprise a set. Therefore, using the core name first and the
% name of the matching project afterwards is a good way of keeping track of
% the files.