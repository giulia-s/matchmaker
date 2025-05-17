function matchmaker(varargin)
% ------------------------------------------------------------------------
% MATCHMAKER GIT running version ( OG was 2.04, 27 July 2011, Sune Olander
% Rasmussen)
% MATCHMAKER syntax : matchmaker(filenames, datafileID, numberofpanels);
%    filenames        Name of .m file containing a list of data and matchpoint file names (try 'files_main')
%    datafileID       Vector of length N indicating which datafiles from "filenames" that should be used
%    numberofpanels   Vector of length N determining the number of data sub-panels in each data window
%
% Example : matchmaker('files_main', [2 3], [1 4]);
%    opens GRIP (no. 2 in "files_main") with only one data panel, and
%    NGRIP1 (no. 3 in "files_main") with four data sub-panels.
% ------------------------------------------------------------------------
% If the program fails to start and you have problems getting rid of the
% figure window, issue the following commands in the command line :
%    set(0, 'showhiddenhandles', 'on')
%    delete(gcf)
%    set(0, 'showhiddenhandles', 'off')

switch nargin
    case {0 1 2} % Only for development purposes
        delete(gcf);
        clc;
        %        eval('open_request(''files_main'', [3 6], [2 2])');
        disp('MATCHMAKER needs input arguments ! Take a look at the users'' guide.');
    case 3
        eval('open_request(varargin{1:3})');
    case {4, 5, 6, 7}
        eval([char(varargin{1}) '(varargin{[2 4:nargin]})']);
    otherwise
        disp('Wrong number of arguments when calling matchmaker.m');
end

%---

function open_request(datafiles, fileno, NN)
try
    eval(datafiles);
catch
    disp('ERROR in Matchmaker : File name file could not be read.');
    return;
end
load matchmaker_sett
if size(fileno) ~= size(NN)
    disp('ERROR in Matchmaker : 2nd and 3rd argument must have same dimension.');
    return;
end
scrsize = get(0, 'screensize');
hgt = scrsize(4);

handles.datafiles=datafiles;

handles.fig = figure('position', [1 60 scrsize(3) scrsize(4)-100], ...
    'name', ['Matchmaker - ',datafiles],...
    'CloseRequestFcn', 'matchmaker(''exit_Callback'',gcbo,[],guidata(gcbo))',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))',...
    'nextplot', 'add', 'color', 0.9*[1 1 1], 'pointer', 'crosshair',...
    'Interruptible', 'off', 'Numbertitle', 'off',...
    'tag', 'matchmakermainwindow', 'integerhandle', 'off');

N = length(fileno);
handles.fileno = fileno;
handles.N = N;
handles.NN = NN;
h_wait = waitbar(0.05, 'Please be patient ... loading'); % Wait window is launched
for i = 1:N
    waitbar(0.2*i, h_wait,...
        ['Please be patient ... loading data file no. ' num2str(i)]); % Wait window is launched
    try
        load(['data' filesep files.datafile{fileno(i)}]);
    catch
        disp(['Data file of record ' num2str(fileno(i)) ' not found']);
        delete(handles.fig);
        delete(h_wait);
        return
    end
    handles.data{i} = data;
    handles.depth{i} = depth;
    handles.depth_no{i} = depth_no;
    handles.species{i} = species;
    handles.colours{i} = colours;
    
    waitbar(0.2*i+0.1, h_wait, ['Please be patient ... loading matchpoint file no. ' num2str(i)]); % Wait window is updated
    try
        load(['matchfiles' filesep files.matchfile{fileno(i)}]);
    catch
        disp(['Matchpoint file ' files.matchfile{fileno(i)} ' not found']);
        delete(handles.fig);
        delete(h_wait);
        return
    end
    handles.matchfile{i} = files.matchfile{fileno(i)};
    handles.core{i} = files.core{fileno(i)};
    handles.mp{i} = mp;
    if length(sett.specs{fileno(i)}) == NN(i)
        handles.selectedspecs{i} = sett.specs{fileno(i)};
    else
        if length(sett.specs{fileno(i)}) < NN(i)
            handles.selectedspecs{i} = [sett.specs{fileno(i)} (length(sett.specs{fileno(i)})+1):NN(i)];
        else
            handles.selectedspecs{i} = sett.specs{fileno(i)}(1:NN(i));
        end
    end
    
    handles.selectedspecs{i} = min(handles.selectedspecs{i}, length(depth_no));
    
end
close(h_wait)

font1 = 8;
font2 = 14;

y0 = 0.03;
y1 = 0.02;
dy = 0.015;
yh = (1-y0-(N+2)*dy)/N;
yoverlap = 0.45; % fraction
yhsub = (yh-y1)./(NN-(NN-1)*yoverlap);

x0 = 0.045;
x1 = 0.08;
dx = 0.005;
xw = 1-x0-2*x1-4*dx;

eh = 0.029*710/hgt;
dh = 0.002*710/hgt;

dummyax = axes('position', [0 0 1 1], 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off',...
    'nextplot', 'add');
handles.title = text(dx, 0.4*y0, 'MATCHMAKER', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);


handles.save = uicontrol('units', 'normalized', ...
    'position', [x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Save', 'style', 'pushbutton', ...
    'callback', ['matchmaker(''save_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'off', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

handles.accordianize = uicontrol('units', 'normalized', ...
    'position', [3*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Accordianize', 'style', 'pushbutton', ...
    'callback', ['matchmaker(''accordianize_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.masterno = uicontrol('units', 'normalized', ...
    'position', [5*x0+x1+3*dx 0.4*y0 0.6*x0 eh], 'string', '1', 'style', 'edit', ...
    'callback', ['matchmaker(''masterno_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.evaluate = uicontrol('units', 'normalized', ...
    'position', [6*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Evaluate', 'style', 'pushbutton', ...
    'callback', ['matchmaker(''evaluate_Callback'',gcbo,[],guidata(gcbo), ''button'')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.mark = uicontrol('units', 'normalized', ...
    'position', [8*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Mark ?', 'style', 'togglebutton', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.dummymark = uicontrol('units', 'normalized', ...
    'position', [10*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Dummies?', 'style', 'togglebutton', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.othermarks = uicontrol('units', 'normalized', ...
    'position', [12*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Others?', 'style', 'togglebutton', ...
    'callback', ['matchmaker(''othermarks_Callback'',gcbo,[],guidata(gcbo), 0)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.plotmp2 = uicontrol('units', 'normalized', ...
    'position', [14*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', '2nd order?', 'style', 'togglebutton', ...
    'callback', ['matchmaker(''plotmp2_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 1, 'Selected', 'off', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.check = uicontrol('units', 'normalized', ...
    'position', [16*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Check mps', 'style', 'pushbutton', ...
    'callback', ['matchmaker(''check_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.exit = uicontrol('units', 'normalized', ...
    'position', [18*x0+x1+3*dx 0.4*y0 1.6*x0 eh], 'string', 'Exit', 'style', 'pushbutton', ...
    'callback', ['matchmaker(''exit_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

handles.undo = uicontrol('units', 'normalized',...
    'position', [18*x0+x1+3*dx 0*y0 1.6*x0 eh], 'string', 'UNDO', 'style', 'pushbutton',...
    'callback', ['matchmaker(''undo_Callback'',gcbo,[],guidata(gcbo))'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.N_undo=1000; % how many moves are saved in memory
handles.lastmoves=cell(handles.N_undo,1);

% Save Figure button
handles.save_fig = uicontrol('units', 'normalized',...
    'position', [4*x0+x1+3*dx 0*y0 1.6*x0 eh],...
    'string', 'SaveFig', 'style', 'pushbutton',...
    'callback', ['matchmaker(''save_fig_Callback'',gcbo,[],guidata(gcbo))'],...
    'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'on',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

for i = 1:N
    
    handles.bigax(i) = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy) xw yh-y1],...
        'nextplot', 'add', 'ylim', [0 1], 'ytick', [], 'box', 'off', 'fontsize', font1, 'ycolor', 'w', 'xcolor', 'w',...
        'ButtonDownFcn', ['matchmaker(''axesclick_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'],...
        'hittest','on');
    handles.bigax2(i) = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy) xw yh-y1], 'nextplot', 'add', 'visible', 'off', 'hittest', 'off', 'clipping', 'on', 'ylim', [0 1]);
    handles.name(i) = text(dx+x0/2, y0+dy+i*(yh+dy), files.core{fileno(i)}, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
    handles.minx(i) = uicontrol('units', 'normalized', ...
        'position', [dx y0+dy+i*(yh+dy)-2*(eh+dh) x0 eh], 'string', '0', 'style', 'edit', ...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    handles.maxx(i) = uicontrol('units', 'normalized', ...
        'position', [dx y0+dy+i*(yh+dy)-3*(eh+dh) x0 eh], 'string', '1', 'style', 'edit', ...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    handles.back(i) = uicontrol('units', 'normalized', ...
        'position', [dx y0+dy+i*(yh+dy)-5*(eh+dh) x0 eh], 'string', '<--', 'style', 'pushbutton', ...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', -1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.fwd(i) = uicontrol('units', 'normalized', ...
        'position', [dx y0+dy+i*(yh+dy)-6*(eh+dh) x0 eh], 'string', '-->', 'style', 'pushbutton', ...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.incx(i) = uicontrol('units', 'normalized', ...
        'position', [dx y0+dy+i*(yh+dy)-7*(eh+dh) x0 eh], 'string', '1', 'style', 'edit', ...
        'callback', ['matchmaker(''incx_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
end
sides = [{'right'} {'left'}];
for i = 1:N
    
    handles.tickax{i,1} = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy) xw yhsub(i)], 'nextplot', 'add', 'color', 'none', 'xcolor', 'k', 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', 'left', 'xaxislocation', 'bottom', 'hittest', 'off', 'fontweight', 'bold');
    handles.plotax{i,1} = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy) xw yhsub(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
    for j = 1:NN(i)
        if j > 1
            handles.tickax{i,j} = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i) xw yhsub(i)], 'nextplot', 'add', 'ycolor', handles.colours{i}(handles.selectedspecs{i}(j),:), 'color', 'none', 'xcolor', 'w', 'xtick', [], 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', sides{mod(j,2)+1}, 'xaxislocation', 'top', 'hittest', 'off', 'fontweight', 'bold');
            handles.plotax{i,j} = axes('position', [x0+x1+3*dx y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i) xw yhsub(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
        end
        handles.spec{i,j}  = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-(eh-2*dh) x0 eh], 'string', handles.species{i}, 'value', handles.selectedspecs{i}(j), 'style', 'popupmenu', 'callback', ['matchmaker(''spec_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center');
        handles.offset{i,j} = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-2*(eh+dh) x0 eh], 'string', 0, 'style', 'edit', ...
            'callback', ['matchmaker(''offset_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        handles.autoy{i,j} = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-3*(eh+dh) (x0-dh)/2 eh], 'string', 'Aut', 'style', 'togglebutton', ...
            'callback', ['matchmaker(''autoy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'value', 1, 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        handles.logy{i,j}  = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx)+(x0+dh)/2 y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-3*(eh+dh) (x0-dh)/2 eh], 'string', 'Log', 'style', 'togglebutton', ...
            'callback', ['matchmaker(''logy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        handles.miny{i,j} = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-4*(eh+dh) x0 eh], 'string', 0, 'style', 'edit', ...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        handles.maxy{i,j} = uicontrol('units', 'normalized', ...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-5*(eh+dh) x0 eh], 'string', 1, 'style', 'edit', ...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        
        % button to change color of species
        handles.color_change{i,j} = uicontrol('units', 'normalized','Tooltip', ['Color'],...
            'position', [(mod(j,2)==1)*(x0+3*dx)+(mod(j,2)==0)*(1-x0-dx) y0+2*dy+y1+(i-1)*(yh+dy)+(j-1)*(1-yoverlap)*yhsub(i)+yhsub(i)-6*(eh+dh) x0 eh],...
            'string', 'Col', 'style', 'pushbutton',...
            'callback', ['matchmaker(''change_color_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'enable', 'on', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        
    end
    set([handles.tickax{i,:} handles.plotax{i,:} handles.bigax(i) handles.bigax2(i)], 'xlim', sett.xlim(fileno(i),:)); % Set the x limits according to the last values
    set(handles.minx(i), 'string', num2str(sett.xlim(fileno(i),1)));
    set(handles.maxx(i), 'string', num2str(sett.xlim(fileno(i),2)));
end
for i = 1:N
    axes(handles.bigax2(i));
end
handles.storeidx = [];
guidata(handles.fig, handles);
for i = 1:N
    for j = 1:NN(i)
        axes(handles.plotax{i,j});
        plotcurve(handles, i, j);
    end
    
    handles = plotmp(handles, i);
    
    update_yminmax(handles.fig, handles, i, 0); % Update the y-scaling
end
set(handles.fig, 'HandleVisibility', 'callback');
guidata(handles.fig, handles);
warning('off', 'MATLAB:Axes:NegativeDataInLogAxis');

%-----------------------

function varargout = move_Callback(hObject, handles, no, direc)
incX = str2double(get(handles.incx(no), 'string')); % Get increment value. Validity check is done elsewhere
oldlimX = get(handles.bigax(no), 'xlim'); % Get depth limits
set([handles.bigax(no) handles.bigax2(no) handles.plotax{no,:} handles.tickax{no,:}], 'xlim', oldlimX+direc*incX); % Add/Subtract increment value ...
set(handles.minx(no), 'String', num2str(oldlimX(1)+direc*incX)); % and update the edit-boxes
set(handles.maxx(no), 'String', num2str(oldlimX(2)+direc*incX));
handles = plotmp(handles, no);
plotcurve(handles, no, 0);
update_yminmax(hObject, handles, no, 0); % The view has changed, so update the y-sacle edit-boxes
guidata(handles.fig, handles)
if nargout == 1
    varargout{1} = handles;
end

%---

function offset_Callback(hObject, handles, no1, no2)
value = str2double(get(handles.offset{no1, no2}, 'string')); % get input
if ~isreal(value) || length(value) ~= 1 % check if input is valid
    set(handles.offset{no1, no2}, 'string', '0');
end
plotcurve(handles, no1, no2);
update_yminmax(hObject, handles, no1, no2); % The view has changed, so update the y-sacle edit-boxes

%---

function othermarks_Callback(hObject, handles, keyboardcall)
if keyboardcall == 1
    state = get(handles.othermarks, 'Value');
    if state == 1
        set(handles.othermarks, 'Value', 0);
    else
        set(handles.othermarks, 'Value', 1);
    end
end
for i = 1:handles.N
    plotmp(handles, i);
end

%---

function masterno_Callback(hObject, handles)
value = str2double(get(handles.masterno, 'string')); % get input
if ~isreal(value) || length(value) ~= 1 || mod(value,1)~=0 || value>handles.N || value<1% check if input is valid
    set(handles.masterno, 'string', '1');
    value = 1;
end
idx1 = handles.mp1_depth{value};
if length(idx1)<2
    set(handles.evaluate, 'Enable', 'off');
else
    set(handles.evaluate, 'Enable', 'on');
end

%---

function incx_Callback(hObject, handles, no) % Depth increment edit-box callback. The validity of the input is checked, the actual value is used elsewhere
value = str2double(get(handles.incx(no), 'string')); % get input
if ~isreal(value) || length(value) ~= 1 % check if input is valid
    set(handles.incx(no), 'string', '1');
end
if value <= 0
    set(handles.incx(no), 'string', num2str(-value)); % Negative values are not logically acceptable
end

%---

function xscale_Callback(hObject, handles, no, limit) % X-scaling edit-boxes callback
if limit == 1
    value = get(handles.minx(no), 'string'); % Get input
else
    value = get(handles.maxx(no), 'string'); % Get input
end
if length(value)>0 && value(1) == 'b'
    if limit == 1
        numvalue = (str2double(value(2:end))-1)*0.55;
        set(handles.minx(no), 'string', num2str(numvalue)); % ... use old lower limit
    else
        numvalue = str2double(value(2:end))*0.55;
        set(handles.maxx(no), 'string', num2str(numvalue)); % ... use old upper limit
    end
else
    numvalue = str2double(value);
end
Xlim = get(handles.bigax(no), 'xlim'); % Get old limits
if ~isreal(numvalue) || length(numvalue) ~= 1 % If input is not a valid number ...
    set(handles.minx(no), 'string', num2str(Xlim(1))); % ... use old lower limit
    set(handles.maxx(no), 'string', num2str(Xlim(2))); % ... use old upper limit
    return
end
if limit == 1
    if numvalue >= Xlim(2) % Check if low < high limit
        set([handles.bigax(no) handles.bigax2(no) handles.plotax{no,:} handles.tickax{no,:}], 'xlim', [numvalue, numvalue + Xlim(2)-Xlim(1)]); % If so, move high limit up as well
        set(handles.maxx(no), 'string', num2str(numvalue + Xlim(2)-Xlim(1))); % and update the corresponding edit-box
    else
        set([handles.bigax(no) handles.bigax2(no) handles.plotax{no,:} handles.tickax{no,:}], 'xlim', [numvalue, Xlim(2)]); % If everything is OK, use the input value
    end
else
    if numvalue <= Xlim(1)
        set([handles.bigax(no) handles.bigax2(no) handles.plotax{no,:} handles.tickax{no,:}], 'xlim', [numvalue - Xlim(2) + Xlim(1), numvalue]);
        set(handles.minx(no), 'string', num2str(numvalue - Xlim(2) + Xlim(1)));
    else
        set([handles.bigax(no) handles.bigax2(no) handles.plotax{no,:} handles.tickax{no,:}], 'xlim', [Xlim(1), numvalue]);
    end
end
plotcurve(handles, no, 0);

handles = plotmp(handles, no);

update_yminmax(hObject, handles, no, 0); % Update the y-scaling
guidata(handles.fig, handles)

%---

function yscale_Callback(hObject, handles, no1, no2, limit) % Y-scaling edit-boxes callback
if limit == 1
    value = str2double(get(handles.miny{no1, no2}, 'string')); % Get input
else
    value = str2double(get(handles.maxy{no1, no2}, 'string')); % Get input
end
Ylim = get(handles.tickax{no1, no2}, 'ylim'); % Get old limits
if ~isreal(value) || length(value) ~= 1 % If input is not a valid number ...
    set(handles.miny{no1, no2}, 'string', num2str(Ylim(1))); % ... use old lower limit
    set(handles.maxy{no1, no2}, 'string', num2str(Ylim(2))); % ... use old upper limit
    return
end
if limit == 1
    if value >= Ylim(2) % Check if low < high limit
        set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'ylim', [value, value + Ylim(2)-Ylim(1)]); % If so, move high limit up as well
        set(handles.maxy{no1, no2}, 'string', num2str(value + Ylim(2)-Ylim(1))); % and update the corresponding edit-box
    else
        set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'ylim', [value, Ylim(2)]); % If everything is OK, use the input value
    end
else
    if value <= Ylim(1)
        set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'ylim', [value - Ylim(2) + Ylim(1), value]);
        set(handles.miny{no1, no2}, 'string', num2str(value - Ylim(2) + Ylim(1)));
    else
        set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'ylim', [Ylim(1), value]);
    end
end
set(handles.autoy{no1, no2}, 'Value', 0);

%---

function autoy_Callback(hObject, handles, no1, no2)
if get(handles.autoy{no1, no2}, 'value') == 1
    set(handles.plotax{no1, no2}, 'ylimmode', 'auto');
    update_yminmax(hObject, handles, no1, no2);
else
    set(handles.plotax{no1, no2}, 'ylimmode', 'manual');
end
set(handles.tickax{no1, no2}, 'ylim', get(handles.plotax{no1, no2}, 'ylim'));

%---

function logy_Callback(hObject, handles, no1, no2)
if get(handles.logy{no1, no2}, 'value') == 1
    set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'yscale', 'log');
else
    set([handles.plotax{no1, no2} handles.tickax{no1, no2}], 'yscale', 'linear');
end
set(handles.tickax{no1, no2}, 'ylim', get(handles.plotax{no1, no2}, 'ylim'));
update_yminmax(hObject, handles, no1, no2);

%---

function spec_Callback(hObject, handles, no1, no2)
handles.selectedspecs{no1}(no2) = get(handles.spec{no1, no2}, 'Value');
plotcurve(handles, no1, no2);
set(handles.autoy{no1, no2}, 'Value', 1);
autoy_Callback(hObject, handles, no1, no2);
update_yminmax(hObject, handles, no1, no2);
guidata(handles.fig, handles)

%---

function axesclick_Callback(hObject, handles, no1)
if get(handles.mark, 'Value') == 1
    type = get(hObject,'type');
    if strcmp(type,'axes')
        pos = get(handles.bigax(no1), 'currentpoint');%click pos norm. units
        ypos = pos(1,2);% y pos in norm. units
        
    elseif strcmp(type,'line')
        pos=get(gcf, 'CurrentPoint'); %click pos norm. units
        ypos = pos(1,2); % y pos in norm. units
        
        parent=get(hObject,'parent');
        pos=get(parent,'CurrentPoint'); %click pos in data units
        
        % check if clicked spot is on an existing mp
        mp = handles.mp{no1}; %all mps of this ice core
        
        temp_object.XData=pos;
        temp_object.Type=type;
        
        del_idx=check_mp_click_inches_conversion(mp,pos(1,1),handles.bigax(no1));
        
        if ~isempty(del_idx)
            handles = mpclick_Callback(temp_object, handles, no1);
            return;
        end
        
    else
        disp('unhandled object type');
    end
    
    pos = 0.001*round(1000*pos(1,1)); %convert normalized units to data units
    but = get(handles.fig, 'selectiontype');
    dummy = get(handles.dummymark, 'Value');
    % NEW TYPE OF MARKS APPENDED JULY 27 2011: TYPE 11/12/13/14/15
    other = get(handles.othermarks, 'Value')*(ypos<0.5);
    if strcmp(but, 'normal')
        if dummy
            mptype = 4+10*other;
        else
            mptype = 1+10*other;
        end
    elseif strcmp(but, 'alt')
        if dummy
            mptype = 5+10*other;
        else
            mptype = 2+10*other;
        end
        if get(handles.plotmp2, 'value') == 0
            return
        end
    elseif strcmp(but, 'extend')
        mptype = 3+10*other;
    else
        return;
    end
    
    mp = handles.mp{no1};
    mp = [mp; pos mptype];
    
    %updating Undo memory
    
    try % see if memory is already allocated
        saved_moves=handles.saved_moves;
    catch
        saved_moves=0; %initialize saved_moves
        handles.saved_moves=saved_moves;
    end
    
    if saved_moves<handles.N_undo % if not reached max limit of saved moves
        
        handles.saved_moves=saved_moves+1; %increase number of saved moves
        
    else % delete one move from the beginning
        
        handles.lastmove(1:handles.N_undo-1,:)=handles.lastmove(2:handles.N_undo,:);
        handles.saved_moves=handles.N_undo;
    end
    % add new entry:
    
    handles.lastmove{handles.saved_moves,1}=pos; % mp position in data units
    handles.lastmove{handles.saved_moves,2}='added'; % this mp was added
    handles.lastmove{handles.saved_moves,3}=no1; % this mp was clicked on the icecore no1
    handles.lastmove{handles.saved_moves,4}=mptype; % this mp has type mptype
    
    %
    
    handles.mp{no1} = sortrows(mp);
    handles = plotmp(handles, no1);
    set(handles.save, 'enable', 'on');
    guidata(hObject, handles);
end

%---

function varargout = mpclick_Callback(hObject, handles, no1)
if get(handles.mark, 'Value') == 1
    
    try
        type=get(hObject,'type');
        pos = get(handles.bigax(no1), 'currentpoint');
        ypos_true=pos(1,2);
        
    catch e
        % if it's a data line you are clicking on, then the hObject is a
        % different structure:
        type=(hObject.Type);
        pos = (hObject.XData);
        ypos=get(gcf,'currentpoint');
        ypos_true=ypos(1,2);
    end
    % --- Undo update memory---
    try %try if any memory is available
        saved_moves=handles.saved_moves;
    catch e
        saved_moves=0;
        handles.saved_moves=saved_moves;
    end
    
    % undo update:
    if saved_moves<handles.N_undo %if not yet reached max saved moves
        handles.saved_moves=saved_moves+1;
    else %delete from beginning
        handles.lastmove(1:handles.N_undo-1,:)=handles.lastmove(2:handles.N_undo,:);
        handles.saved_moves=handles.N_undo;
    end
    
    % add new UNDO entry:
    handles.lastmove{ handles.saved_moves,1}=pos(1,1); % pos of mp
    handles.lastmove{ handles.saved_moves,2}='removed'; %removed mp: because the mp_callback was activated by removing an existing mp
    handles.lastmove{ handles.saved_moves,3}=no1; %which icecore
    handles.lastmove{ handles.saved_moves,4}=3; %assign type 3
    
    
    mp = handles.mp{no1};
    
    if get(handles.othermarks, 'Value')==0 || (ypos_true>=0.5 && get(handles.othermarks, 'Value')==1)
        delindx=check_mp_click_inches_conversion(mp,pos(1,1),handles.bigax(no1));
    elseif get(handles.othermarks, 'Value')==1 && ypos_true<0.5
        delindx=[];
    end
    
    
    if length(delindx)>1 && get(handles.othermarks, 'Value') == 1
        [~, order] = sort(mp(delindx,2));
        pos = get(handles.bigax(no1), 'currentpoint');
        if pos(1,2)>0.5
            delindx = delindx(order(1));
        else
            delindx = delindx(order(2));
        end
    end
    
    mp = mp(setdiff(1:length(mp(:,1)), delindx),:);
    handles.mp{no1} = mp;
    
    handles = plotmp(handles, no1);
    
    set(handles.save, 'enable', 'on');
    guidata(handles.fig, handles);
    varargout{1}=handles;
end

%---

function update_yminmax(hObject, handles, no1, no2) % Updates the minY and maxY edit-boxes with the current Y-axis limits. Is called whenever the view changes.
if no2 == 0
    no2 = 1:handles.NN(no1);
end
for j = 1:length(no2)
    limY = get(handles.plotax{no1, no2(j)}, 'ylim');
    set(handles.miny{no1, no2(j)}, 'string', num2str(limY(1)));
    set(handles.maxy{no1, no2(j)}, 'string', num2str(limY(2)));
    set(handles.tickax{no1, no2(j)}, 'ylim', limY);
end

%---

function curve = plotcurve(handles, no1, no2)
if no2 == 0
    no2 = 1:handles.NN(no1);
end
xlim = get(handles.bigax(no1), 'xlim');
for j = no2
    offset = str2double(get(handles.offset{no1, j}, 'String'));
    offsetxlim = xlim - offset;
    depth = handles.depth{no1}{handles.depth_no{no1}(handles.selectedspecs{no1}(j))};
    data = handles.data{no1}{handles.selectedspecs{no1}(j)};
    idx = [max(1, min(find(depth>=offsetxlim(1)))-1) : min(length(data), max(find(depth<=offsetxlim(2)))+1)];
    if isempty(idx)
        curve = plot(0, 0, 'parent', handles.plotax{no1,j}, 'hittest', 'off');
    else
        plotdepth = depth(idx);
        plotdata = data(idx);
        curve = plot(offset+plotdepth, plotdata, 'color', handles.colours{no1}(handles.selectedspecs{no1}(j),:), 'linewidth', 1.5, 'parent', handles.plotax{no1,j}, 'hittest', 'off');
    end
    set([handles.spec{no1, j} handles.offset{no1, j} handles.autoy{no1, j} handles.logy{no1, j} handles.miny{no1, j} handles.maxy{no1, j}], 'Backgroundcolor', 'w', 'Foregroundcolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
    set(handles.tickax{no1, j}, 'ycolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
    
    % the curves are set to be "clickable":
    set(curve,'hittest', 'on','PickableParts','all','ButtonDownFcn',['matchmaker(''axesclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')'],'parent',handles.plotax{no1,j});
    
end

%---

function handles = plotmp(handles, no1)

cla(handles.bigax2(no1));
greytone = 0.8*[1 1 1];
redtone = 0.85*[1 0 0];
bluetone = 0.85*[0 0 1];
greytone10 = 0.9*[1 1 1];
redtone10 = 0.85*[1 0.5 0.5];
bluetone10 = 0.85*[0.5 0.5 1];
mp = handles.mp{no1};
xlim = get(handles.bigax(no1), 'xlim');
if isempty(mp)
    return
else
    othermarks = get(handles.othermarks, 'Value');
    mp1 = mp(find(mp(:,2)==1),1);
    mp3 = mp(find(mp(:,2)==3),1);
    mp4 = mp(find(mp(:,2)==4),1);
    mp134 = mp(find(mp(:,2)==1 | mp(:,2)==3 | mp(:,2)==4),1);
    if ~isempty([mp1' mp3' mp4'])
        idx1 = find(mp1>=xlim(1) & mp1<=xlim(2));
        idx3 = find(mp3>=xlim(1) & mp3<=xlim(2));
        idx4 = find(mp4>=xlim(1) & mp4<=xlim(2));
        idx134 = find(mp134>=xlim(1) & mp134<=xlim(2));
        if ~isempty(idx1)
            plot((mp1(idx1)*[1 1])', repmat([0.01+othermarks*0.5 0.93]', 1, length(idx1)), 'linewidth', 6, 'color', greytone, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ');']);
        end
        if ~isempty(idx3)
            plot((mp3(idx3)*[1 1])', repmat([0.01+othermarks*0.5 0.93]', 1, length(idx3)), 'linewidth', 6, 'color', redtone, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
        end
        if ~isempty(idx4)
            plot((mp4(idx4)*[1 1])', repmat([0.01+othermarks*0.5 0.93]', 1, length(idx4)), 'linewidth', 6, 'color', bluetone, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
        end
        text(mp134(idx134), 0.93*ones(length(idx134),1), num2str(idx134), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', 'k');
        handles.mp1_idx{no1} = idx134;
        handles.mp1_depth{no1} = mp134(idx134);
    else
        handles.mp1_idx{no1} = 0;
        handles.mp1_depth{no1} = [];
    end
    idx2 = find(mp(:,2)==2 & mp(:,1)>=xlim(1) & mp(:,1)<=xlim(2));
    idx5 = find(mp(:,2)==5 & mp(:,1)>=xlim(1) & mp(:,1)<=xlim(2));
    if ~isempty(idx2) && get(handles.plotmp2, 'Value') == 1
        plot((mp(idx2,1)*[1 1])', repmat([0.05+othermarks*0.51 0.89]', 1, length(idx2)), 'linewidth', 4, 'color', greytone, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
    end
    if ~isempty(idx5) && get(handles.plotmp2, 'Value') == 1
        plot((mp(idx5,1)*[1 1])', repmat([0.05+othermarks*0.51 0.89]', 1, length(idx5)), 'linewidth', 4, 'color', bluetone, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
    end
    % NEW SECTION FOR TYPE 11/12/13/14/15 MARKS
    if othermarks
        mp11 = mp(find(mp(:,2)==11),1);
        mp13 = mp(find(mp(:,2)==13),1);
        mp14 = mp(find(mp(:,2)==14),1);
        mp111314 = mp(find(mp(:,2)==11 || mp(:,2)==13| mp(:,2)==14),1);
        if ~isempty([mp11' mp13' mp14'])
            idx11 = find(mp11>=xlim(1) & mp11<=xlim(2));
            idx13 = find(mp13>=xlim(1) & mp13<=xlim(2));
            idx14 = find(mp14>=xlim(1) & mp14<=xlim(2));
            idx111314 = find(mp111314>=xlim(1) & mp111314<=xlim(2));
            if ~isempty(idx11)
                plot((mp11(idx11)*[1 1])', repmat([0.07 0.49]', 1, length(idx11)), 'linewidth', 6, 'color', greytone10, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
            end
            if ~isempty(idx13)
                plot((mp13(idx13)*[1 1])', repmat([0.07 0.49]', 1, length(idx13)), 'linewidth', 6, 'color', redtone10, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
            end
            if ~isempty(idx14)
                plot((mp14(idx14)*[1 1])', repmat([0.07 0.49]', 1, length(idx14)), 'linewidth', 6, 'color', bluetone10, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
            end
            text(mp111314(idx111314), 0.07*ones(length(idx111314),1), num2str(idx111314), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k');
        end
        idx12 = find(mp(:,2)==12 & mp(:,1)>=xlim(1) & mp(:,1)<=xlim(2));
        idx15 = find(mp(:,2)==15 & mp(:,1)>=xlim(1) & mp(:,1)<=xlim(2));
        if ~isempty(idx12) && get(handles.plotmp2, 'Value') == 1
            plot((mp(idx12,1)*[1 1])', repmat([0.12 0.49]', 1, length(idx12)), 'linewidth', 4, 'color', greytone10, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
        end
        if ~isempty(idx15) && get(handles.plotmp2, 'Value') == 1
            plot((mp(idx15,1)*[1 1])', repmat([0.12 0.49]', 1, length(idx15)), 'linewidth', 4, 'color', bluetone10, 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ')']);
        end
    end
    % END OF NEW SECTION
end

if length(handles.mp1_idx{str2double(get(handles.masterno, 'string'))})<2
    set(handles.evaluate, 'Enable', 'off');
else
    set(handles.evaluate, 'Enable', 'on');
end

%---

function keypressed_Callback(hObject, handles) % Translate keypress to appropriate button actions.
key = double(get(handles.fig, 'currentcharacter'));
if ~isempty(key)
    switch key
        case 28   %<-
            handles = move_Callback(hObject, handles, str2double(get(handles.masterno, 'string')), -1);
            accordianize_Callback(hObject, handles);
        case 29  %->
            handles = move_Callback(hObject, handles, str2double(get(handles.masterno, 'string')), 1);
            accordianize_Callback(hObject, handles);
        case {80, 112}   %p, P
            set(handles.fig, 'InvertHardcopy', 'on', 'paperunits', 'centimeters', 'paperorientation', 'landscape', 'papertype', 'A4', 'paperposition', [1 1 27.7 19], 'renderer', 'painters');
            %        print(handles.fig, '-dpsc2', '-r300', 'matchmaker.eps');
            print(handles.fig, '-dpsc2', '-noui', '-r300', 'matchmaker.eps');
        case {97, 65}   %a, A
            accordianize_Callback(hObject, handles);
        case {99, 67}   %c, C
            cursor_Callback(hObject, handles);
        case {100, 68}   %d, D
            state = get(handles.dummymark, 'Value');
            if state == 1
                set(handles.dummymark, 'Value', 0);
            else
                set(handles.dummymark, 'Value', 1);
            end
        case {109, 77}  %m, M
            set(handles.mark, 'value', get(handles.mark, 'value')==0);
        case {111, 79}   %o, O
            othermarks_Callback(hObject, handles, 1);
        case {115, 83}  %s, S
            if strcmp(get(handles.save, 'enable'), 'on')
                save_Callback(hObject, handles);
            end
        case {120, 88}  %x, X
            exit_Callback(hObject, handles);
        case 50  %2
            set(handles.plotmp2, 'value', get(handles.plotmp2, 'value')==0);
            plotmp2_Callback(hObject, handles);
        otherwise % If key not defined, show info window
            disp(['Just for information : MATCHMAKER undefined key callback : ' num2str(key)]);
            h_help = helpdlg({...
                'Available keyboard commands:';
                '<- = move selected core one frame back and accordianize'
                '-> = move selected core one frame forward and accordianize'
                'A  = Accordianize'
                'C  = change Cursor type'
                'D  = Toggle "Dummy ?" button on/off'
                'M  = Toggle "Mark ?" button on/off'
                'O  = Toggle "Other ?" button on/off'
                'S  = Save matchpoint files'
                'X  = eXit'
                '2  = Toggle "2nd order" button on/off'
                'U  = Undo'});
            
    end
end

%---

function cursor_Callback(hObject, handles) % Change cursor type from crosshair to fullcrosshair and back
if strcmp(get(handles.fig, 'pointer'), 'crosshair')
    set(gcf, 'pointer', 'fullcrosshair');
else
    set(gcf, 'pointer', 'crosshair');
end

%---

function accordianize_Callback(hObject, handles)
masterno = str2double(get(handles.masterno, 'string'));
mastermp = handles.mp1_idx{masterno};
if isempty(mastermp)
    return
end
xlim = get(handles.bigax(masterno), 'xlim');
mp_depth = handles.mp1_depth{masterno}([1 end]);
frac = (mp_depth-xlim(1))./(xlim(2)-xlim(1));
if length(mastermp) == 1
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(find(mpi(:,2)==1 || mpi(:,2)==3 || mpi(:,2)==4),1);
            newxlim = round(1000*(mpi134(mastermp)+[-frac(1) (1-frac(1))]*(xlim(2)-xlim(1))))/1000;
            set([handles.bigax(i) handles.bigax2(i) handles.plotax{i,:} handles.tickax{i,:}], 'xlim', newxlim);
            plotcurve(handles, i, 0);
            set(handles.minx(i), 'string', num2str(newxlim(1)));
            set(handles.maxx(i), 'string', num2str(newxlim(2)));
            handles = plotmp(handles, i);
        end
    end
else
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(find(mpi(:,2)==1 || mpi(:,2)==3 || mpi(:,2)==4),1);
            mpi134_depth = mpi134(mastermp([1 end]));
            newwidth = diff(mpi134_depth)/(frac(2)-frac(1));
            newxlim = round(100*(mpi134_depth(1)-frac(1)*newwidth + [0 newwidth]))/100;
            set([handles.bigax(i) handles.bigax2(i) handles.plotax{i,:} handles.tickax{i,:}], 'xlim', newxlim);
            plotcurve(handles, i, 0);
            handles = plotmp(handles, i);
            set(handles.minx(i), 'string', num2str(newxlim(1)));
            set(handles.maxx(i), 'string', num2str(newxlim(2)));
        end
    end
end
guidata(handles.fig, handles); % Is it OK to have it outside the loop ???

%---

function evaluate_Callback(hObject, handles, identify)
if strcmp(identify, 'button')
    masterno = str2double(get(handles.masterno, 'string'));
    if isfield(handles, 'evaluatefigurehandle')
        matchmaker_evaluate('evalreuse', handles.evaluatefigurehandle, [], handles.mp, handles.core, masterno, handles.mp1_idx{masterno});
    else
        matchmaker_evaluate('evalopen', handles.fig, [], handles.mp, handles.core, masterno, handles.mp1_idx{masterno});
    end
elseif strcmp(identify, 'opening_evaluate')
    evalhandles = handles; % the input argument 'handles' is the handles of the evaluate window.
    handles = guidata(evalhandles.matchmakerfighandle); %This line, redefines 'handles' to contain the handles of the matchmaker window
    handles.evaluatefigurehandle = evalhandles.fig;
    guidata(handles.fig, handles);
elseif strcmp(identify, 'closing_evaluate')
    evalhandles = handles; % the input argument 'handles' is the handles of the evaluate window.
    handles = guidata(evalhandles.matchmakerfighandle); %This line, redefines 'handles' to contain the handles of the matchmaker window
    handles = rmfield(handles, 'evaluatefigurehandle');
    guidata(handles.fig, handles);
else
    disp(['Error in MATCHMAKER.m, evaluate_Callback : ' identify]);
end

%---

function check_Callback(hObject, handles)
clc
names = [];
for i = 1:handles.N
    names = [names char(handles.core{i}) ' '];
end
disp(['MATCHMAKER DIAGNOSTICS            for matchpoints from the cores : ' names]);
disp(' ');
for i = 1:handles.N
    mpi = handles.mp{i};
    mpi1 = mpi(find(mpi(:,2)==1),1);
    mpi25 = mpi(find(mpi(:,2)==2 || mpi(:,2)==5),1);
    mpi134 = mpi(find(mpi(:,2)==1 || mpi(:,2)==3 || mpi(:,2)==4),1);
    Nmp1(i) = length(mpi1);
    Nmp134(i) = length(mpi134);
    for j = 1:Nmp134(i)-1
        Nmp25(i,j) = sum(mpi25>=mpi134(j) & mpi25<mpi134(j+1));
    end
    if length(mpi134)<2
        mindist134(i) = 0;
    else
        mindist134(i) = min(diff(mpi134));
    end
    if length(mpi25)<2
        mindist25(i) = 0;
    else
        mindist25(i) = min(diff(mpi25));
    end
end
if isempty(setdiff(Nmp1, Nmp1(1)))
    disp('The number of type 1 matchpoints is the same for all cores.');
else
    disp(['The number of type 1 matchpoints is not the same for all cores   : ' num2str(Nmp1, 2)]);
end
if isempty(setdiff(Nmp134, Nmp134(1)))
    disp('The total number of type 1/3/4 matchpoints is the same for all cores.');
else
    disp(['The total number of type 1/3/4 matchpoints is not the same for all cores   : ' num2str(Nmp134, 2)]);
end

disp(' ')
diffidx = [];
for j = 1:max(Nmp134)-1
    if ~isempty(setdiff(Nmp25(:,j), Nmp25(1,j)))
        diffidx = [diffidx j];
    end
end
if isempty(diffidx)
    disp('The number of type 2/5 matchpoints between each set of type 1/3/4 matchpoints is the same for all cores.');
else
    disp('The number of type 2/5 matchpoints between each set of type 1/3/4 matchpoints is not the same for all cores :');
    for k = 1:length(diffidx)
        disp(['Number of type 2/5 matchpoints between type 1/3/4 matchpoint ' num2str(diffidx(k)) ' and ' num2str(diffidx(k)+1) ' : ' num2str(Nmp25(:, diffidx(k))', 2)]);
    end
end
disp(' ');
disp(['The minimum distance between two adjacent type 1/3/4 matchpoints is  : ' num2str(mindist134, 2)]);
disp(['The minimum distance between two adjacent type 2/5 matchpoints is  : ' num2str(mindist25, 2)]);
disp('(rounded off to nearest centimeter value)');
disp(' ');
answer = input('(Press ENTER to return)');
disp(' ');
disp(' ');
figure(handles.fig);

%---

function save_Callback(hObject, handles)
for i = 1:handles.N
    status = copyfile(['matchfiles' filesep handles.matchfile{i}], ['matchfiles' filesep handles.matchfile{i} '.backup']);
    if status == 0
        disp(['MATCHMAKER.m warning : Could not back up matchpoint file ' handles.matchfile{i} ' before saving']);
        disp('   (this error does not influence the saving procedure itself)');
    end
    mp = handles.mp{i};
    save(['matchfiles' filesep handles.matchfile{i}], 'mp', '-MAT');
    
end
set(handles.save, 'enable', 'off');

%---

function plotmp2_Callback(hObject, handles)
for i = 1:handles.N
    handles = plotmp(handles, i);
end
guidata(hObject, handles);

%---

function exit_Callback(hObject, handles)
if strcmp(get(handles.save, 'enable'), 'on') % Ask about saving marks if something has been changed, otherwise confirm and exit
    answer = questdlg([{'The matchpoints have been changed.'} {'Do you want to save the matchpoints before leaving Matchmaker ?'}], 'Save marks ?', 'Yes', 'No', 'Yes');
    switch answer
        case 'Yes'
            save_Callback(hObject, handles);
        case 'No'
            answer = questdlg('Do you want to exit without saving ?', 'Exit ?', 'Yes', 'No', 'No');
            switch answer
                case {'No' ''}
                    return;
            end
        case ''
            return;
    end
end
fileno = handles.fileno;
load('matchmaker_sett.mat');
for i = 1:length(fileno)
    sett.xlim(fileno(i),:) = get(handles.bigax(i), 'xlim');
    sett.specs{fileno(i)} = handles.selectedspecs{i};
end
save('matchmaker_sett.mat', 'sett');
if isfield(handles, 'evaluatefigurehandle')
    delete(handles.evaluatefigurehandle)
end
delete(handles.fig)
warning('on', 'MATLAB:Axes:NegativeDataInLogAxis');

%---

function handles=undo_Callback(hObject, handles)

try
    saved_moves= handles.saved_moves;
catch e
    disp(e);
    saved_moves=0;
end

if saved_moves<1
    disp('Undo : no move in memory');
end

if and(~isnan(saved_moves),saved_moves>0)
    
    no1=handles.lastmove{saved_moves,3}; %retrieve ice core
    
    if get(handles.mark, 'Value') == 1
        if strcmp(handles.lastmove{saved_moves,2},'added') % an added mp will be removed
            if handles.lastmove{saved_moves,4}<10
                idx = find(handles.mp{no1}(:,1)==handles.lastmove{saved_moves,1});
                if isempty(idx)
                    idx=check_mp_click_inches_conversion(handles.mp{no1},handles.lastmove{saved_moves,1},handles.bigax(no1));%giulia: see this function description
                end
                handles.mp{no1}(idx,:)=[];
                handles = plotmp(handles, no1);
                set(handles.save, 'enable', 'on');
                handles.lastmove(saved_moves,:)=[];
                handles.saved_moves=handles.saved_moves-1;
                guidata(hObject, handles);
                
            else
                idx_2 = find(handles.mp_2{no1}(:,1)==handles.lastmove{saved_moves,1});
                if isempty(idx_2)
                    idx_2=check_mp_click_inches_conversion(handles.mp_2{no1},handles.lastmove{saved_moves,1},handles.bigax(no1)); %giulia: see this function description
                end
                handles.mp_2{no1}(idx_2,:)=[];
                handles = plotmp(handles, no1);
                set(handles.save, 'enable', 'on');
                handles.lastmove(saved_moves,:)=[];
                handles.saved_moves=handles.saved_moves-1;
                guidata(hObject, handles);
            end
            
        elseif strcmp(handles.lastmove{saved_moves,2},'removed') % a removed mp will be re-added
            
            if handles.lastmove{saved_moves,4}<10
                
                removed_mp=[handles.lastmove{saved_moves,1} handles.lastmove{saved_moves,4}];
                handles.mp{no1}=[handles.mp{no1};removed_mp];
                handles.mp{no1} = sortrows(handles.mp{no1});
                handles = plotmp(handles, no1);
                set(handles.save, 'enable', 'on');
                %undo-ed moves are deleted, double-undo is avoided
                handles.lastmove(saved_moves,:)=[];
                handles.saved_moves=handles.saved_moves-1;
                
                guidata(hObject, handles);
            else
                removed_mp=[handles.lastmove{saved_moves,1} handles.lastmove{saved_moves,4}-10];
                handles.mp_2{no1}=[handles.mp_2{no1};removed_mp];
                handles.mp_2{no1} = sortrows(handles.mp_2{no1});
                handles = plotmp(handles, no1);
                set(handles.save, 'enable', 'on');
                handles.lastmove(saved_moves,:)=[];
                handles.saved_moves=handles.saved_moves-1;
                
                guidata(hObject, handles);
            end
        else
            disp('error');
        end
    end
    
end

%---

function save_fig_Callback(hObject, handles)
state=get(handles.save_fig,'Enable');
if strcmp(state,'on')
    matchmaker_savefig('open_save_fig',handles)
    set(handles.save_fig,'Enable','on');
else
    set(handles.save_fig,'Enable','on');
end

%---

function delindx = check_mp_click_inches_conversion(mp,P,x_axis)
% this function checks whether a point clicked is close enough to an existing mp to delete it.
% it works by converting the linewidth of the mp bar from inches to data units,
% and setting this as a tolerance distance for the deletion of the mp.

% mp : set of mp to search
% P : point of click
% x_axis: X_axis handle
[min_dist,closest_idx]=min(abs(mp(:,1)-P));
t=mp(closest_idx,2);
min_X=x_axis.XLim(1);
max_X=x_axis.XLim(2);
D_X=max_X-min_X; % X_axis width in data units
set(x_axis,'units','inch');
X_inch=get(x_axis,'Position');
set(x_axis,'units','normalized');
X_inch=X_inch(3);% X_axis width in inches
if t==7
    LW=1;
elseif t==6
    LW=2;
elseif t==2 || t==5
    LW=4;
elseif t==1 || t==3 || t==4
    LW=6;
else
    LW=NaN; % no mp was clicked
    delindx=[];
    return;
end
LW_inch=LW/72; % width of mp marker in inches
tol_x=(max_X-min_X)/X_inch*LW_inch; %width of mp bar in data units
if min_dist<tol_x
    delindx=closest_idx;
else
    delindx=[];
end

%---

function change_color_Callback(hObject, handles, no1, no2)

color_activated_save = 0;
if strcmp(get(handles.save,'enable'),'off') %if button is off
    set(handles.save, 'enable', 'on'); %activate it
    color_activated_save = 1;
end

color=uisetcolor(handles.colours{no1}(handles.selectedspecs{no1}(no2),:),['Select a color for:' handles.species{no1}{handles.selectedspecs{no1}(no2)}]);
handles.colours{no1}(handles.selectedspecs{no1}(no2),:)=color;

guidata(hObject, handles);

% re-plot with new color
axes(handles.plotax{no1,no2});
plotcurve(handles, no1,no2);
handles = plotmp(handles, no1);
update_yminmax(handles.fig, handles, no1, 0); % Update the y-scaling

guidata(hObject, handles);

% Save new colors of data-species
colours=handles.colours{no1};
eval(handles.datafiles); %load file names of icecores to be able to access the datafile
save(['data' filesep files.datafile{handles.fileno(no1)}],'colours','-append'); %save new colors in datafile

if color_activated_save==1 %if save was activated only by the color button
    set(handles.save, 'enable', 'off'); %set if off again
end

