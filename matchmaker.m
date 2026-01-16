function matchmaker(varargin)
% ------------------------------------------------------------------------
% MATCHMAKER GIT running version
% (Originally released as v2.04, 27 July 2011, Sune Olander Rasmussen)
% MATCHMAKER syntax : matchmaker(filenames, init_file_nameID, numberofpanels);
%    filenames        Name of .m file containing a list of data and matchpoint file names (try 'files_main')
%    init_file_nameID       Vector of length N indicating which init_file_name from "filenames" that should be used
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

%--- Opens GUI and set the appearance of buttons, axes, etc:

function open_request(init_file_name, fileno, N_species)
try
    eval(init_file_name);
catch
    disp('ERROR in Matchmaker : File name file could not be read.');
    return;
end
load matchmaker_sett
if size(fileno) ~= size(N_species)
    disp('ERROR in Matchmaker : 2nd and 3rd argument must have same dimension.');
    return;
end

handles.init_file_name=init_file_name;

% GUI window
handles.fig = figure('units','normalized',...
    'outerposition', [0.025 0.075 0.85 0.85], ...%initial dimensions upon opening
    'name', ['Matchmaker - ',init_file_name],...
    'CloseRequestFcn', 'matchmaker(''exit_Callback'',gcbo,[],guidata(gcbo))',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))',...
    'nextplot', 'add', 'color', 0.9*[1 1 1], 'pointer', 'cross',...
    'Interruptible', 'off', 'Numbertitle', 'off',...
    'tag', 'matchmakermainwindow', 'integerhandle', 'off',...
    'Menubar', 'none', 'Toolbar', 'none');

% initialize and populate data
N = length(fileno);
handles.fileno = fileno;
handles.N = N;
handles.N_species = N_species;
h_wait = waitbar(0.05, 'Please be patient ... loading'); % Wait window is launched
for i = 1:N

    waitbar(0.2*i, h_wait,...
        ['Please be patient ... loading data file no. ' num2str(i)]); % Wait window is launched
    try
        load(['data' filesep files.datafile{fileno(i)}]); %#ok<*LOAD>
    catch
        disp(['Data file of record ' num2str(fileno(i)) ' not found']);
        disp(['Missing file name: ' 'data' filesep files.datafile{fileno(i)}]);
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
        disp(['Loading matchfiles' filesep files.matchfile{fileno(i)},' ...']);
        load(['matchfiles' filesep files.matchfile{fileno(i)}]);
    catch
        disp(['Matchfile of ' files.core{fileno(i)} ' not found. Either it was not specified or it is not existing.']);
        files.matchfile{fileno(i)}=[ files.core{fileno(i)} '.mat'];
        if ~exist(['matchfiles/' files.matchfile{fileno(i)}]) %#ok<*EXIST>
            disp(['Creating a new matchfile for ' files.core{fileno(i)} ' contanining empty mp=[].']);
            mp=[];
            save(['matchfiles',filesep,files.matchfile{fileno(i)}],'mp');
            disp(['Loading matchfiles' filesep files.matchfile{fileno(i)},' ...']);
        else
            disp(['The existing file ' 'matchfiles/' files.matchfile{fileno(i)} ' is loaded as as matchfile instead.']);
        end
        load(['matchfiles' filesep files.matchfile{fileno(i)}]);
    end
    handles.matchfile{i} = files.matchfile{fileno(i)};
    handles.core{i} = files.core{fileno(i)};
    
    %check if mp contains mptypes>10 (compatibility of oder versions)
    handles.mp{i} = mp;
    
    % try finding a secondary set of mps (if specified in init_file)
    try
        try %#ok<*TRYNC> %in the init_file it may be called matchfile_bis or matchfile_secondary
            files.matchfile_secondary{fileno(i)}=files.matchfile_bis{fileno(i)};
        end
        mp_2=load(['matchfiles' filesep files.matchfile_secondary{fileno(i)}]);
        disp(['Loading secondary: matchfiles' filesep files.matchfile_secondary{fileno(i)},' ...']);
        
        mp_2=mp_2.mp;
        handles.mp_2{i}=mp_2;
        handles.matchfile_secondary{i} = files.matchfile_secondary{fileno(i)};
    catch
        disp(['Matchfile_secondary file for ' files.core{fileno(i)} ' not found. Program will continue by generating an apppropriate file, if needed, upon pressing Save.']);
        mp_2=[];
        handles.mp_2{i}=[];
       
    end
    
    if length(sett.specs{fileno(i)}) == N_species(i)
        handles.selectedspecs{i} = sett.specs{fileno(i)};
    else
        if length(sett.specs{fileno(i)}) < N_species(i)
            handles.selectedspecs{i} = [sett.specs{fileno(i)} (length(sett.specs{fileno(i)})+1):N_species(i)];
        else
            handles.selectedspecs{i} = sett.specs{fileno(i)}(1:N_species(i));
        end
    end
    
    handles.selectedspecs{i} = min(handles.selectedspecs{i}, length(depth_no));
    
end
close(h_wait)

% Get screen size
scrsze = get(0, 'screensize');
L = scrsze(3);
H = scrsze(4);

% Font sizes
font1 = 8;
font2 = 10;

% Button color
butcol = 0.8*[1 1 1];
figcol = get(handles.fig, 'color');

% Vertical dimensions of user interface, including axis and button heights (in normalized units)
y0 = 5/H;                               % Space below row of buttons at the lower edge of the window
y1 = 25/H;                              % Space reserved for depth axis tickmarks, located below each core's axis
y2 = 15/H;                              % Space between upper axis and upper window edge
species_overlap_H = 0.45;               % Fraction of overlap between species subaxes. Should be below 0.5 if using more than 2 subaxes (i.e., more than one at the right and one at the left)
button_H2 = 32/H;                       % Height of main buttons below the axes (uses font2)
button_H1 = button_H2*font1/font2;      % height of the smaller buttons belonging to cores and species axes (which uses the smaller font1)
button_y_spacing = button_H1/20;        % Vertical distance between buttons belonging to cores and species axes
ax_H = (1-y0-button_H2-y2-N*y1)/N;      % The remaining height is divided between the N cores
ax_species_H = ax_H./(N_species-(N_species-1)*species_overlap_H); % Calculating the height of each species sub-axis taking into acount that the subaxes overlap

% Horizontal dimensions of user interface, including axis and button widths (in normalized units)
x0 = 5/L;                               % Space from left window edge to row of core buttons
xcore = 65/L;                           % Width of strip which contains core names and buttons
x1 = 5/L;                               % Strip of space separating core buttons and species buttons
xspec = 100/L;                          % Width of strip which contains species buttons. Width of individual fields are fractions hereof
specspace = 0.03;                       % Horizontal spacing between species buttons/fields. 
specwidth = (1-2*specspace)/3;          % Width of Aut, log and offset buttons/fields. 
speclimwidth = (1-specspace)/2;         % Width of ymin and ymax fields.
x2 = 30/L;                              % Strips reserved for y-axis tickmarks left of axes
x3 = 30/L;                              % Strips reserved for y-axis tickmarks right of axes
x4 = 5/L;                               % Space from right window edge to the rightmost spec buttons
ax_width = 1-x0-x1-x2-x3-x4-xcore-2*xspec;  % Remaining width is used for axes
N_buttons = 13.5;                       % The window for selected of which cores to accordize to is only half width. 
button_x_spacing = 0.0015;              % Horizontal button separation used only for the bottom buttons
button_L = (ax_width-(N_buttons-0.5)*button_x_spacing)/N_buttons;          % Buttons are located only below the axis in this model. If buttons get too narrow, more space is available by allowing the buttons to expand to either side
axis_left_xpos = x0+xcore+x1+xspec+x2;       % The x coordinate of the left axis corner

%BOTTOM LINE BUTTONS
dummyax = axes('position', [0 0 1 1], 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off', 'nextplot', 'add');
handles.title = text(x0, y0,...
    'MATCHMAKER', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
handles.save = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos, y0, button_L, button_H2],...
    'string', 'Save', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', ['Saves all matchfiles.' 10 'Creates backup files of everything. (S)'],...
    'callback', 'matchmaker(''save_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'off', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = 2;
handles.save_fig = uicontrol('units', 'normalized',...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Save figure', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Saves a figure.',...
    'callback', 'matchmaker(''save_fig_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'on',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.accordianize = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Accordianize', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', ['Align 1st and Last tiepoint of all icecores.' 10 'Won''''t work in case of mp number mismatch.  (Spacebar)'],...
    'callback', 'matchmaker(''accordianize_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.stretchianize = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Stretch-ianize', 'style', 'togglebutton', 'Backgroundcolor', butcol,'value',0, ...
    'Tooltip', ['Align all tiepoints.' 10 'Won''''t work in case of mp number mismatch.  (Spacebar)'],...
    'callback', 'matchmaker(''stretchianize_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.masterno = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L/2, button_H2],...
    'Tooltip', 'Set which icecore to align to.',...
    'string', '1', 'style', 'edit', ...
    'callback', 'matchmaker(''masterno_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');

Buttonnumber = Buttonnumber+0.5;
handles.evaluate = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Evaluate', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Opens new panel with evaluation tools.',...
    'callback', 'matchmaker(''evaluate_Callback'',gcbo,[],guidata(gcbo), ''button'')', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.check = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Check mps', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Displays matchmaker diagnostics on command window.',...
    'callback', 'matchmaker(''check_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.edit = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Edit mps', 'style', 'togglebutton', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center',...
    'value', 0, 'Backgroundcolor', butcol, ...
    'Tooltip', 'Activate MatchPoint adding/removing. (E)',...
    'callback','matchmaker(''edit_marks_callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.ref_mark = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Reference mps', 'style', 'radio', 'fontname', 'default', 'fontsize', font1, 'horizontalalignment', 'center',...
    'value', 1, 'Backgroundcolor', figcol, ...
    'Tooltip', 'Edit type 1(click),3(shift-click),4(r-click) (R)',...
    'callback','matchmaker(''ref_mark_Callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.thin_mark =    uicontrol('units', 'normalized',...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'Tooltip', 'Edit type 2(click),5(r-click) (T)',...
    'string', 'Thin mps', 'style', 'radio', 'Backgroundcolor', figcol, ...
    'value',0,...
    'callback','matchmaker(''temp_mark_Callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.years_mark =    uicontrol('units', 'normalized',...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'Tooltip', 'Edit type 6(click),7(r-click) (Y)',...
    'string', 'Years', 'style', 'radio', 'Backgroundcolor', figcol, ...
    'value',0,...
    'callback', 'matchmaker(''years_mark_Callback'',gcbo,[],guidata(gcbo),0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
% Get all the handles to everything we want to set in a single array.
handles.radiogroup = [handles.ref_mark, handles.years_mark, handles.thin_mark];
% Disable them all. They can only be enabled if pressing the edit marks button
set(handles.radiogroup, 'Enable', 'off');

Buttonnumber = Buttonnumber+1;
handles.hide_minor_mp = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Hide minor mps', 'style', 'togglebutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Hide minor mp, i.e. types 2,5,6,7. (H)',...
    'callback', 'matchmaker(''hide_minor_mp_Callback'',gcbo,[],guidata(gcbo),0)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center',...
    'Selected', 'off', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))',...
    'value',1);

Buttonnumber = Buttonnumber+1;
handles.secondary_marks = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Show secondary', 'style', 'togglebutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Show secondary matchfile. (J)',...
    'callback', 'matchmaker(''secondary_marks_Callback'',gcbo,[],guidata(gcbo), 0)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'value', 0, ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.undo = uicontrol('units', 'normalized',...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Undo', 'style', 'pushbutton', 'Backgroundcolor', butcol,'enable','off', ...
    'Tooltip', ['Cancels new mp and Re-adds removed mp.' 10 ' (U)'],...
    'callback', 'matchmaker(''undo_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

Buttonnumber = Buttonnumber+1;
handles.exit = uicontrol('units', 'normalized', ...
    'position', [axis_left_xpos+(Buttonnumber-1)*(button_L+button_x_spacing), y0, button_L, button_H2],...
    'string', 'Exit', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
    'Tooltip', 'Exit program. (X)',...
    'callback', 'matchmaker(''exit_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.N_undo=1000; % how many moves are saved in memory
handles.lastmoves=cell(handles.N_undo,1);

% CREATING AXES ("BIGAX") AND BUTTONS FOR EACH ICE CORE
for i = 1:N
    % Calculating lower y position for the to sets of axes to be created
    bigax_y_pos = y0 + button_H2 + y1 + (i-1)*(ax_H + y1);
    % Calculating y position of the top of the core name text line (relative to which the rest of the buttons are placed)
    corename_ypos = bigax_y_pos+ax_H;
    
    % These are the axes in which the user clicks. Due to axis/curve stacking issues, it's not where the marker bars are plotted
    handles.bigax(i) = axes('position', [axis_left_xpos, bigax_y_pos, ax_width, ax_H],...
        'nextplot', 'add', 'ylim', [0 1], 'ytick', [], 'box', 'off', 'fontsize', font1, 'ycolor', 'w', 'xcolor', 'w',...
        'ButtonDownFcn', ['matchmaker(''axesclick_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'],...
        'hittest','on');
    set(handles.bigax(i) ,'interactions',[])
    % In these overlaid (invisible) axes, the marks are later plotted.
    handles.bigax2(i) = axes('position', [axis_left_xpos, bigax_y_pos , ax_width, ax_H], 'nextplot', 'add', 'visible', 'off',...
        'hittest', 'off', 'clipping', 'on', 'ylim', [0 1]);

    % Buttons and other controls are created 
    handles.name(i) = text(x0, corename_ypos,...
        files.core{fileno(i)}, 'VerticalAlignment', 'top', 'interpreter','none','HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
    handles.minx(i) = uicontrol('units', 'normalized', ...
        'position', [x0, corename_ypos-2*button_H1-button_y_spacing, xcore, button_H1],...
        'string', '0', 'style', 'edit', ...
        'Tooltip', 'Min X Limit',...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    handles.maxx(i) = uicontrol('units', 'normalized', ...
        'position', [x0, corename_ypos-3*button_H1-2*button_y_spacing, xcore, button_H1],...
        'Tooltip', 'Max X Limit',...
        'string', '1', 'style', 'edit', ...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    handles.back(i) = uicontrol('units', 'normalized', ...
        'position', [x0, corename_ypos-4*button_H1-3*button_y_spacing, xcore, button_H1],...
        'string', '←', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
        'Tooltip', 'Move Back',...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', -1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.fwd(i) = uicontrol('units', 'normalized', ...
        'position', [x0, corename_ypos-5*button_H1-4*button_y_spacing, xcore, button_H1],...
        'string', '→', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
        'Tooltip', 'Move Forward',...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.incx(i) = uicontrol('units', 'normalized', ...
        'position', [x0, corename_ypos-6*button_H1-5*button_y_spacing, xcore, button_H1],...
        'string', '1', 'style', 'edit', ...
        'Tooltip','X-Axis Moving increment',...
        'callback', ['matchmaker(''incx_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
end

% BUTTONS FOR EACH SPECIES
sides = [{'right'} {'left'}];

for i = 1:N
    bigax_y_pos = y0 + button_H2 + y1 + (i-1)*(ax_H + y1); % Same as above under "bigax"
 
    % As the title suggests, these axes are used to show the tickmarks etc.
    % for each species subaxis, but due to axis/curve overlap issues, the
    % data are not plotted in these.
    handles.tickax{i,1} = axes('position', [axis_left_xpos, bigax_y_pos ax_width ax_species_H(i)], 'nextplot', 'add', 'color', 'none', 'xcolor', 'k', 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', 'left', 'xaxislocation', 'bottom', 'hittest', 'off', 'fontweight', 'bold');
    % ... but in these similar but invisible axes instead
    handles.plotax{i,1} = axes('position', [axis_left_xpos, bigax_y_pos ax_width ax_species_H(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
    
    for j = 1:N_species(i)    
        specax_lower_ypos = bigax_y_pos + (j-1)*(1-species_overlap_H)*ax_species_H(i);  % lower y-position of the species axis box

        if j > 1
            handles.tickax{i,j} = axes('position', [axis_left_xpos specax_lower_ypos ax_width ax_species_H(i)], 'nextplot', 'add', 'ycolor', handles.colours{i}(handles.selectedspecs{i}(j),:), 'color', 'none', 'xcolor', 'w', 'xtick', [], 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', sides{mod(j,2)+1}, 'xaxislocation', 'top', 'hittest', 'off', 'fontweight', 'bold');
            handles.plotax{i,j} = axes('position', [axis_left_xpos specax_lower_ypos ax_width ax_species_H(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
        end

        %position of species-button column can be left or right depending
        %on mod(n,2):
        specbuttoncolumn_xpos = (mod(j,2)==1)*(x0+xcore+x1)... % left
            +(mod(j,2)==0)*(1-x4-xspec); % or right

        % Top left: Species selection drop-down
        handles.spec{i,j}  = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos specax_lower_ypos+ax_species_H(i)/2-button_H1 xspec*(2*specwidth+specspace) button_H1],...
            'Tooltip', 'Select species to display', 'Backgroundcolor', butcol, ...
            'string', handles.species{i}, ...
            'value', handles.selectedspecs{i}(j),...
            'style', 'popupmenu',...
            'callback', ['matchmaker(''spec_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'],...
            'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center');
        
        % Top right: Button to change color of species
        handles.color_change{i,j} = uicontrol('units', 'normalized','Tooltip', 'Color',...
            'position', [specbuttoncolumn_xpos+xspec*(2*specwidth+2*specspace) specax_lower_ypos+ax_species_H(i)/2-button_H1 xspec*specwidth button_H1],...
            'string', 'Col', 'style', 'pushbutton', 'Backgroundcolor', butcol, ...
            'Tooltip','Change color of species. Changes are saved automatically.',...
            'callback', ['matchmaker(''change_color_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'enable', 'on', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

        % Middle left: Automatic y-axis scaling button
        handles.autoy{i,j} = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos specax_lower_ypos+ax_species_H(i)/2-2*button_H1-button_y_spacing xspec*specwidth button_H1],...
            'string', 'Aut', 'style', 'togglebutton', 'Backgroundcolor', butcol, ...
            'Tooltip', 'Automatic y-axis limits',...
            'callback', ['matchmaker(''autoy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], ...
            'value', 1, 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

        % Middle center: Logarithmic y-axis scaling button
        handles.logy{i,j}  = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos+xspec*(specspace+specwidth) specax_lower_ypos+ax_species_H(i)/2-2*button_H1-button_y_spacing xspec*specwidth button_H1],...
            'string', 'Log', 'style', 'togglebutton', 'Backgroundcolor', butcol, ...
            'Tooltip', 'Set y-axis to log',...
            'callback', ['matchmaker(''logy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

        % Middel right: Reverse y-axis scaling button 
        handles.revy{i,j}  = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos+xspec*(2*specspace+2*specwidth) specax_lower_ypos+ax_species_H(i)/2-2*button_H1-button_y_spacing xspec*specwidth button_H1],...
            'string', 'Rev', 'style', 'togglebutton', 'Backgroundcolor', butcol, ...
            'Tooltip', 'Reverse y-axis',...
            'callback', ['matchmaker(''revY_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

        
        % Lower left: Min y field
        handles.miny{i,j} = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos specax_lower_ypos+ax_species_H(i)/2-3*button_H1-2*button_y_spacing xspec*specwidth button_H1],...
            'string', 0, 'style', 'edit', ...
            'Tooltip', 'Min Y (arb.units)',...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
  
        % Lower center: Max y field
        handles.maxy{i,j} = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos+xspec*(specspace+specwidth) specax_lower_ypos+ax_species_H(i)/2-3*button_H1-2*button_y_spacing xspec*specwidth button_H1],...
            'string', 1, 'style', 'edit', ...
            'Tooltip', 'Max Y (arb.units)',...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
       
         % Lower right: x offset
    
         handles.offset{i,j} = uicontrol('units', 'normalized', ...
            'position', [specbuttoncolumn_xpos+xspec*(2*specspace+2*specwidth) specax_lower_ypos+ax_species_H(i)/2-3*button_H1-2*button_y_spacing xspec*specwidth button_H1],...
            'string', '0', 'style', 'edit', ...
            'backgroundcolor',[1 1 1]*0.5,...   
            'Tooltip', 'Shift data relative to x-Axis by this offset (m)',...
            'callback', ['matchmaker(''offset_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
       
    end

    if isequal(sett.command_line_info,{handles.init_file_name;handles.fileno})
        set([handles.tickax{i,:} handles.plotax{i,:} handles.bigax(i) handles.bigax2(i)], 'xlim', sett.xlim(fileno(i),:)); % Set the x limits according to the last values
        set(handles.minx(i), 'string', num2str(sett.xlim(fileno(i),1)));
        set(handles.maxx(i), 'string', num2str(sett.xlim(fileno(i),2)));
    else
        set([handles.tickax{i,:} handles.plotax{i,:} handles.bigax(i) handles.bigax2(i)], 'xlim', [0 100]); 
        set(handles.minx(i), 'string', 0);
        set(handles.maxx(i), 'string', 100);   
    end
end
for i = 1:N
    axes(handles.bigax2(i));
end
handles.storeidx = [];
guidata(handles.fig, handles);
handles.multiple_opening_indicator=1; %refers to a feature in plot mp: if any of the panels has too many mp, the edit button is greyed
for i = 1:N
    for j = 1:N_species(i)
        axes(handles.plotax{i,j});
        plotcurve(handles, i, j);
    end
    
    % Plots all mp for the first time
    handles = plotmp(handles, i);
    
    update_yminmax(handles.fig, handles, i, 0); % Update the y-scaling
end
handles.multiple_opening_indicator=0;


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
if ~isreal(value) | length(value) > 1 | isnan(value) % check if input is valid
    set(handles.offset{no1, no2}, 'string', '0', 'Backgroundcolor', 'w')
else
    if value == 0
        set(handles.offset{no1, no2}, 'Backgroundcolor', 'w')
    else
        set(handles.offset{no1, no2}, 'Backgroundcolor', [1 0.52 0.45])
    end;
end
plotcurve(handles, no1, no2);
update_yminmax(hObject, handles, no1, no2); % The view has changed, so update the y-scale edit-boxes
guidata(handles.fig, handles);

%---

function secondary_marks_Callback(~, handles, keyboardcall)
if keyboardcall == 1
    state = get(handles.secondary_marks, 'Value');
    if state == 1
        set(handles.secondary_marks, 'Value', 0);
    else
        set(handles.secondary_marks, 'Value', 1);
    end
end
handles.multiple_opening_indicator=1;
for i = 1:handles.N
    plotmp(handles, i);
end
handles.multiple_opening_indicator=0;

%---

function masterno_Callback(~, handles)
accord_value = str2double(get(handles.masterno, 'string')); % get input
if ~isreal(accord_value) | length(accord_value) ~= 1 | mod(accord_value,1)~=0 | accord_value>handles.N | accord_value<1% check if input is valid
    set(handles.masterno, 'string', '1');
    accord_value = 1;
end

mp = handles.mp1_depth{accord_value};
if length(mp)<2
    set(handles.evaluate, 'Enable', 'off');
else
    set(handles.evaluate, 'Enable', 'on');
end

%---

function incx_Callback(~, handles, no) % Depth increment edit-box callback. The validity of the input is checked, the actual value is used elsewhere
value = str2double(get(handles.incx(no), 'string')); % get input
if ~isreal(value) | length(value) ~= 1 % check if input is valid
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
if ~isempty(value) && value(1) == 'b'
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
if ~isreal(numvalue) | length(numvalue) ~= 1 % If input is not a valid number ...
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

function yscale_Callback(~, handles, no1, no2, limit) % Y-scaling edit-boxes callback
if limit == 1
    value = str2double(get(handles.miny{no1, no2}, 'string')); % Get input
else
    value = str2double(get(handles.maxy{no1, no2}, 'string')); % Get input
end
Ylim = get(handles.tickax{no1, no2}, 'ylim'); % Get old limits
if ~isreal(value) | length(value) ~= 1 % If input is not a valid number ...
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

%--- Function for adding new mps:

function axesclick_Callback(hObject, handles, no1)
if get(handles.edit, 'Value') == 1 & strcmp(get(handles.edit, 'Enable'),'on') %if editing is legal
    type = get(hObject,'type'); % get the type of surface you clicked on
    if strcmp(type,'axes') %white-area click
        pos = get(handles.bigax(no1), 'currentpoint'); % click x-pos norm. units
        ypos = pos(1,2);% y pos in norm. units
        
    elseif strcmp(type,'line') %line click : could be a free spot on the datacurve or an existing mp on that curve
        temp_pos=get(gcf, 'CurrentPoint'); %click x pos norm. units
        ypos = temp_pos(1,2); % y pos in norm. units
        
        parent=get(hObject,'parent');
        pos=get(parent,'CurrentPoint'); %click x-pos in data units (m)
    else
        disp('unhandled object type');
    end
    % check if clicked spot is on an existing mp
    mp = handles.mp{no1}; %all mps of this ice core
    
    click_pos_object.XData=pos;
    click_pos_object.Type=type;
    click_pos_object.UserData=type;
    
    if get(handles.secondary_marks, 'Value')==0 | (ypos>=0.5 && get(handles.secondary_marks, 'Value')==1)
        mp = handles.mp{no1}; %load mp of this ice core
    elseif get(handles.secondary_marks, 'Value')==1 && ypos<0.5
        mp = handles.mp_2{no1}; %load mp_2 of this ice core
    end
    
    %identify if there is an mp to delete
    if ~isempty(mp)
        del_idx=check_mp_click_inches_conversion(mp,pos(1,1),handles.bigax(no1));
    else
        del_idx=[];
    end
    
    if ~isempty(del_idx)
        mpclick_Callback(click_pos_object, handles, no1);
        return;
    end
    
    pos = 0.001*round(1000*pos(1,1)); %adjust precision to be 1 mm
    
    % Determining which type the new mp should be
    mptype = determine_mptype_from_click(handles);
    
    % calling current sets of mp and mp_2
    mp = handles.mp{no1};
    mp_2 = handles.mp_2{no1};
    
    % distinguish if click is on top or lower half of axis, and update mp
    if get(handles.secondary_marks, 'Value')==0 | (ypos>=0.5 && get(handles.secondary_marks, 'Value')==1)  %#ok<*OR2>
        mp = [mp; pos mptype];% amplitudes];
        secondary_marks=0;
    elseif get(handles.secondary_marks, 'Value')==1 && ypos<0.5
        mp_2=[mp_2;pos mptype];
        secondary_marks=1;
    end
    
    handles.mp{no1} = sortrows(mp);
    handles.mp_2{no1} = sortrows(mp_2);
    
    %updating Undo memory
    
    try % see if memory is already allocated
        saved_moves=handles.saved_moves;

    catch
        saved_moves=0; %initialize saved_moves
        handles.saved_moves=saved_moves;

    end
    set(handles.undo,'enable','on');

    
    if saved_moves<handles.N_undo % if not reached max limit of saved moves
        
        handles.saved_moves=saved_moves+1; %increase counter of saved moves
        
    else % delete one move from the beginning
        
        handles.lastmove(1:handles.N_undo-1,:)=handles.lastmove(2:handles.N_undo,:);
        handles.saved_moves=handles.N_undo;
    end
    
    % add new memory entry:
    
    
    handles.lastmove{handles.saved_moves,1}=pos; % mp position in data units
    handles.lastmove{handles.saved_moves,2}='added'; % this mp was added
    handles.lastmove{handles.saved_moves,3}=no1; % this mp was clicked on the icecore no1
    handles.lastmove{handles.saved_moves,4}=mptype+10*secondary_marks; % this mp has type mptype
    
    
    %replot everything and trigger save button
    handles = plotmp(handles, no1);
    set(handles.save, 'enable', 'on');
    guidata(hObject, handles);

end

%--- Function for deleting existing mps. Called either if clicking on
%existing mp, or if clicking on curve (axesclick_callback) and then
%deleting an mp found in proximity

function mpclick_Callback(hObject, handles, no1)
if get(handles.edit, 'Value') == 1 & strcmp(get(handles.edit, 'Enable'),'on') %if editing is legal
    
    try %if clicking on mp
        type=get(hObject,'type');
        pos = get(handles.bigax(no1), 'currentpoint');
        ypos_true=pos(1,2);
        
    catch
        % if it's a data line you are clicking on, then the hObject is a
        % different structure:
        type=(hObject.Type); %#ok<*NASGU>
        pos = (hObject.XData);
        ypos=get(gcf,'currentpoint');
        ypos_true=ypos(1,2);
    end
    % --- update memory of saved moves ---
    try %  if any memory is available
        saved_moves=handles.saved_moves;
    catch  %start new undo-chain
        saved_moves=0;
        handles.saved_moves=saved_moves;
    end
    set(handles.undo,'enable','on');

    
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
    userdata = get(hObject,'UserData');
    [mptype]=userdata(1);
    [secondary_marks]=userdata(2);

    handles.lastmove{ handles.saved_moves,4}=mptype+10*secondary_marks;
    
    % acquire the current series of mps
    mp = handles.mp{no1};
    mp_2=handles.mp_2{no1};
    
    % check if clicking on bottom or lower half of screen
    if get(handles.secondary_marks, 'Value')==0 | (ypos_true>=0.5 && get(handles.secondary_marks, 'Value')==1)
        delindx=check_mp_click_inches_conversion(mp,pos(1,1),handles.bigax(no1));
        delindx_2=[];
    elseif get(handles.secondary_marks, 'Value')==1 && ypos_true<0.5
        delindx=[];
        delindx_2=check_mp_click_inches_conversion(mp_2,pos(1,1),handles.bigax(no1));
    end
    
    % remove the identified mps:
    mp = mp(setdiff(1:length(mp(:,1)), delindx),:);
    if ~isempty(mp_2)
    mp_2 = mp_2(setdiff(1:length(mp_2(:,1)), delindx_2),:);
    end
    
    %update handles:
    handles.mp{no1} = mp;
    handles.mp_2{no1} = mp_2;
    
    %re-plot everything
    handles = plotmp(handles, no1);
    
    %toggle save button
    set(handles.save, 'enable', 'on');
    
    
end
guidata(handles.fig, handles);
%---

function update_yminmax(~, handles, no1, no2) % Updates the minY and maxY edit-boxes with the current Y-axis limits. Is called whenever the view changes.
if no2 == 0
    no2 = 1:handles.N_species(no1);
end
for j = 1:length(no2)
    limY = get(handles.plotax{no1, no2(j)}, 'ylim');
    set(handles.miny{no1, no2(j)}, 'string', num2str(limY(1)));
    set(handles.maxy{no1, no2(j)}, 'string', num2str(limY(2)));
    set(handles.tickax{no1, no2(j)}, 'ylim', limY);
end

%---

function plotcurve(handles, no1, no2)
if no2 == 0
    no2 = 1:handles.N_species(no1);
end
xlim = get(handles.bigax(no1), 'xlim');
for j = no2
    offset = str2double(get(handles.offset{no1, j}, 'String'));
    offsetxlim = xlim - offset;
    depth = handles.depth{no1}{handles.depth_no{no1}(handles.selectedspecs{no1}(j))};
    data = handles.data{no1}{handles.selectedspecs{no1}(j)};
    
    startIdx = find(depth >= offsetxlim(1), 1, 'first');
    endIdx   = find(depth <= offsetxlim(2), 1, 'last');
    
    % Handle cases where limits are outside the depth range
    if isempty(startIdx)
        startIdx = 1;
    else
        startIdx = max(1, startIdx - 1);
    end
    
    if isempty(endIdx)
        endIdx = length(data);
    else
        endIdx = min(length(data), endIdx + 1);
    end
    
    % Final index range
    idx = startIdx:endIdx;
    if isempty(idx)
        plot(0, 0, 'parent', handles.plotax{no1,j}, 'hittest', 'off');
    else
        plotdepth = depth(idx);
        plotdata = data(idx);
        plot(offset+plotdepth, plotdata,...
            'color', handles.colours{no1}(handles.selectedspecs{no1}(j),:),...
            'linewidth', 1.5, 'parent', handles.plotax{no1,j},...
            'hittest', 'off', 'PickableParts','none');
    end
    % uncomment this line if you would like the text to change color
    % depending on the species
    % set([handles.spec{no1, j} handles.color_change{no1, j} handles.offset{no1, j} handles.autoy{no1, j} handles.logy{no1, j} handles.miny{no1, j} handles.maxy{no1, j}], 'Foregroundcolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
    set([ handles.color_change{no1, j} handles.offset{no1, j} handles.autoy{no1, j} handles.logy{no1, j} handles.miny{no1, j} handles.maxy{no1, j}], 'Foregroundcolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
    set(handles.tickax{no1, j}, 'ycolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
    
end

%--- Plot the mps, in the current viewing window between depth_min and depth_max

function handles = plotmp(handles, no1)

cla(handles.bigax2(no1)); %clear axes

% colors for each mp type
greytone = 0.8*[1 1 1];
redtone = 0.85*[1 0 0];
bluetone = 0.85*[0 0 1];
greentone = 0.7 * [0 1 0];

greytone_2 = 0.9*[1 1 1];
redtone_2 = 0.85*[1 0.5 0.5];
bluetone_2 = 0.85*[0.5 0.5 1];
greentone_2 = 0.8 * [0.5 1 0.5];

colors=[greytone; redtone; bluetone; greytone; bluetone; greentone; greentone];

% collect current mp data
if get(handles.stretchianize,'value')==1
    mp = handles.mp_stretch{no1};
else
    mp = handles.mp{no1};
end

if isfield(handles,'mp_2')
    mp_2=handles.mp_2{no1};
end
% collect current depth limits
xlim = get(handles.bigax(no1), 'xlim');

scrsze = get(0, 'screensize');


%common parameters ofr the mps
if isempty(mp)
    return
else
    
    secondary_marks = get(handles.secondary_marks, 'Value'); %logical value to decide whether to plot full screen or only top half
    
    bar_height=[0.93;0.93;0.93;0.88;0.88;0.85;0.85];

    handles = plot_mp_subfunction(handles, mp, xlim, colors, bar_height, no1, 0.01+secondary_marks*0.5);
    if secondary_marks
        % Repeat the same procedure for the "secondary_/mp_2" dataset
        bar_height=[0.93;0.93;0.93;0.88;0.88;0.85;0.85]/2; %half height
        handles = plot_mp_subfunction(handles, mp_2, xlim, colors*115/100, bar_height, no1, 0.01);
    end

end
   




%---

function keypressed_Callback(hObject, handles) % Translate keypress to appropriate button actions.
symbol=char(get(handles.fig, 'currentcharacter'));%get value from keyboard

if ~isempty(symbol)
    
    switch symbol
        case '←'  
            handles = move_Callback(hObject, handles, str2double(get(handles.masterno, 'string')), -1);
            accordianize_Callback(hObject, handles);
        case '→'  %->
            handles = move_Callback(hObject, handles, str2double(get(handles.masterno, 'string')), 1);
            accordianize_Callback(hObject, handles);
        case {'p','P'}   %p, P
            set(handles.fig, 'InvertHardcopy', 'on', 'paperunits', 'centimeters', 'paperorientation', 'landscape', 'papertype', 'A4', 'paperposition', [1 1 27.7 19], 'renderer', 'painters');
            %        print(handles.fig, '-dpsc2', '-r300', 'matchmaker.eps');
            print(handles.fig, '-dpsc2', '-noui', '-r300', 'matchmaker.eps');
        case {'a','A'}    %a,A
            accordianize_Callback(hObject, handles);
        case {'c',' C'}  %y, Y
            stretchianize_Callback(hObject,handles,1);
        case {'e',' E'}  %e, E
            edit_marks_callback(hObject,handles,1);
        case {'h',' H'}  %h, H
            hide_minor_mp_Callback(hObject, handles,1);
        case {'j',' J'}  %j, J
            secondary_marks_Callback(hObject, handles,1);
        case {'r',' R'}   %r, R
            ref_mark_Callback(hObject, handles, 1);
        case {'s',' S'}  %s, S
            if strcmp(get(handles.save, 'enable'), 'on')
                save_Callback(hObject, handles);
            end
        case {'t',' T'}  %t, T
            temp_mark_Callback(hObject, handles, 1)
        case {'u','U'}  %u,U
            undo_Callback(hObject, handles)
        case {'x',' X'}  %x, X
            exit_Callback(hObject, handles);
        case {'y',' Y'}  %y, Y
            years_mark_Callback(hObject,handles,1);
        otherwise % If key not defined, show info window
            h_help = helpdlg({...
                'Available keyboard commands:';
                '<- = move selected core one frame back and accordianize'
                '-> = move selected core one frame forward and accordianize'
                'A  = Accordianize'
                'C  = Stretchianize'
                'E  =  "Edit mps"  on/off'              
                'R  =  "Reference mps"  on/off'
                 'T  =  "Thin mps"  on/off'
                 'Y =  "Yearly layers"  on/off'
                'H  =  "Hide minor mps"  on/off'
                'J  =  "Show secondary mps"  on/off'
                'S  = Save matchpoint files'
                'X  = Exit'
                'U  = Undo'});
                
            
    end
end



%---

function accordianize_Callback(~, handles)
masterno = str2double(get(handles.masterno, 'string'));
mastermp = handles.mp1_idx{masterno};
if isempty(mastermp)
    return
end
xlim = get(handles.bigax(masterno), 'xlim');
mp_depth = handles.mp1_depth{masterno}([1 end]);
frac = (mp_depth-xlim(1))./(xlim(2)-xlim(1));
if length(mastermp) == 1
    handles.multiple_opening_indicator=1;
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(ismember(mpi(:,2),[1,3,4]),1);
            newxlim = round(1000*(mpi134(mastermp)+[-frac(1) (1-frac(1))]*(xlim(2)-xlim(1))))/1000;
            set([handles.bigax(i) handles.bigax2(i) handles.plotax{i,:} handles.tickax{i,:}], 'xlim', newxlim);
            plotcurve(handles, i, 0);
            set(handles.minx(i), 'string', num2str(newxlim(1)));
            set(handles.maxx(i), 'string', num2str(newxlim(2)));
            handles = plotmp(handles, i);
        end
    end
    handles.multiple_opening_indicator=0;
else
    handles.multiple_opening_indicator=1;
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(ismember(mpi(:,2),[1,3,4]),1);
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
    handles.multiple_opening_indicator=0;
end
guidata(handles.fig, handles); % Is it OK to have it outside the loop ???

%---

function stretchianize_Callback(~, handles)

set(handles.stretchianize,'value',1)

masterno = str2double(get(handles.masterno, 'string'));
mastermp = handles.mp1_idx{masterno};

if isempty(mastermp)
    return
end

xlim = get(handles.bigax(masterno), 'xlim');

try
    mp_depth = handles.mp1_depth{masterno}([1 end]);
catch
    return 
end

frac = (mp_depth-xlim(1))./(xlim(2)-xlim(1));

if length(mastermp) == 1 %accordianize like normally
    handles.multiple_opening_indicator=1;
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(ismember(mpi(:,2),[1,3,4]),1);
            newxlim = round(1000*(mpi134(mastermp)+[-frac(1) (1-frac(1))]*(xlim(2)-xlim(1))))/1000;
            set([handles.bigax(i) handles.bigax2(i) handles.plotax{i,:} handles.tickax{i,:}], 'xlim', newxlim);
            
            plotcurve(handles, i, 0);
            set(handles.minx(i), 'string', num2str(newxlim(1)));
            set(handles.maxx(i), 'string', num2str(newxlim(2)));
            handles = plotmp(handles, i);
        end
    end
    handles.multiple_opening_indicator=0;
elseif length(mastermp) > 1 %stretchianize

    mp_134_master=handles.mp{masterno}(mastermp);

    handles.multiple_opening_indicator=1;
    for i = setdiff(1:handles.N, masterno)
        mpi = handles.mp{i};
        
        if length(mpi)>=max(mastermp)
            mpi134 = mpi(ismember(mpi(:,2),[1,3,4]),1);

            mpi134_accordnan = mpi134(mastermp);
            
            depth = handles.depth{i}{handles.depth_no{i}(handles.selectedspecs{i})};
            N=min(length(mpi134_accordnan),length(mp_134_master));

            f_stretch=griddedInterpolant(mpi134_accordnan(1:N),mp_134_master(1:N),'linear','linear');

            
            handles.depth_stretch{i}{handles.depth_no{i}(handles.selectedspecs{i})}=f_stretch(handles.depth{i}{handles.depth_no{i}(handles.selectedspecs{i})});
            handles.mp_stretch{i}=handles.mp{i};
            handles.mp_stretch{i}(:,1)=f_stretch(handles.mp{i}(:,1));

            mpi134_depth = f_stretch(mpi134(mastermp([1 end])));
            newwidth = diff(mpi134_depth)/(frac(2)-frac(1));
            newxlim = round(100*(mpi134_depth(1)-frac(1)*newwidth + [0 newwidth]))/100;
            % newxlim = f_stretch(newxlim);

            set([handles.bigax(i) handles.bigax2(i) handles.plotax{i,:} handles.tickax{i,:}], 'xlim', newxlim);

            plotcurveStretch(handles, i, 0);
            
            handles = plotmp(handles, i);
            set(handles.minx(i), 'string', num2str(newxlim(1)));
            set(handles.maxx(i), 'string', num2str(newxlim(2)));
        end
    end
    handles.multiple_opening_indicator=0;
end

set(handles.stretchianize,'value',0)
guidata(handles.fig, handles); % Is it OK to have it outside the loop ???

%---

function evaluate_Callback(~, handles, identify)
if strcmp(identify, 'button')
    masterno = str2double(get(handles.masterno, 'string'));
    if isfield(handles, 'evaluatefigurehandle') %if evaluate was already open
        matchmaker_evaluate('evalreuse', handles.evaluatefigurehandle, [], handles.mp, handles.mp_2, handles.core, masterno, handles.mp1_idx{masterno});
    else %open new evaluate window
        matchmaker_evaluate('evalopen', handles.fig, [], handles.mp, handles.mp_2, handles.core, masterno, handles.mp1_idx{masterno}, handles.secondary_marks);
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

function check_Callback(~, handles)
clc
names = [];
for i = 1:handles.N
    names = [names char(handles.core{i}) ' ']; %#ok<AGROW>
end
disp(['MATCHMAKER DIAGNOSTICS            for matchpoints from the cores : ' names]);
disp(' ');

Nmp1=zeros(1,handles.N);
Nmp134=zeros(1,handles.N);
% Nmp25=cell(1,handles.N);
mindist134=zeros(1,handles.N);
% mindist25=zeros(1,handles.N);

%currently tpe 2/5 are excluded from calculations, as this doesn't seem
%useful at this moment.

for i = 1:handles.N
    mpi = handles.mp{i};
    mpi1 = mpi(ismember(mpi(:,2),1),1);
    mpi25 = mpi(ismember(mpi(:,2),[2,5]),1);
    mpi134 = mpi(ismember(mpi(:,2),[1,3,4]),1);
    
    Nmp1(i) = length(mpi1);
    Nmp134(i) = length(mpi134);
    
    %     Nmp25{i}=zeros(Nmp134(i)-1,1);
    %     for j = 1:Nmp134(i)-1
    %         Nmp25{i}(j) = sum(mpi25>=mpi134(j) & mpi25<mpi134(j+1));
    %     end
    if length(mpi134)<2
        mindist134(i) = 0;
    else
        mindist134(i) = min(diff(mpi134));
    end
    %     if length(mpi25)<2
    %         mindist25(i) = 0;
    %     else
    %         mindist25(i) = min(diff(mpi25));
    %     end
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

% disp(' ')
% diffidx = [];
% for j = 1:max(Nmp134)
%     try
%         d = setdiff(cellfun(@(x) x(j), Nmp25), Nmp25{1}(j));
%         diffidx = [diffidx j]; %#ok<AGROW>
%     catch e
%         disp(e)
%     end
% end
% if isempty(diffidx)
%     disp('The number of type 2/5 matchpoints between each set of type 1/3/4 matchpoints is the same for all cores.');
% else
%     disp('The number of type 2/5 matchpoints between each set of type 1/3/4 matchpoints is not the same for all cores :');
%     for k = 1:length(diffidx)
%         disp(['Number of type 2/5 matchpoints between type 1/3/4 matchpoint ' num2str(diffidx(k)) ' and ' num2str(diffidx(k)+1) ' : ' num2str(cellfun(@(x) x(diffidx(k)), Nmp25), 2)]);
%     end
% end
disp(' ');
disp(['The minimum distance (m) between two adjacent type 1/3/4 matchpoints is  : ' num2str(mindist134, 2)]);
% disp(['The minimum distance (m) between two adjacent type 2/5 matchpoints is  : ' num2str(mindist25, 2)]);
disp('(rounded off to nearest centimeter value)');
disp(' ');
answer = input('(Press ENTER to return)');
disp(' ');
disp(' ');
figure(handles.fig);

%---

function save_Callback(~, handles)

% Setting up the back-up folder
init_file_name=handles.init_file_name;

if ~exist(['matchfiles/matchfiles_backup/' init_file_name '/' ],'dir')
    mkdir(['matchfiles/matchfiles_backup/' init_file_name '/' ]); % create backup folder with init_file_name name
end
backup_dir=['matchfiles/matchfiles_backup/' init_file_name '/' ];
%generate a counter file
if exist( [backup_dir '/runID.mat'],'file')
    load( [backup_dir '/runID.mat']); % increment a counter
    runID = runID+1; %#ok<NODEF>
else
    runID = 1;
end
save([backup_dir '/runID.mat'],'runID');
%generate the backup forlder for this run
output_dir = [backup_dir '#' num2str(runID)]; % create a sub folder
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

for i = 1:handles.N
    status = copyfile(['matchfiles' filesep handles.matchfile{i}], ['matchfiles' filesep handles.matchfile{i} '.backup']);
    if status == 0
        disp(['MATCHMAKER.m warning : Could not back up matchpoint file ' handles.matchfile{i} ' before saving']);
        disp('   (this error does not influence the saving procedure itself)');
    end
    mp = handles.mp{i};
    if isfield(handles,'not_allowed_mp') % if the helpdlg box from plotmp was triggered at the start
        try
            mp=[mp;handles.not_allowed_mp{i}];
        end
        mp=sortrows(mp);
    end
    
    % Over-write mp files
    save(['matchfiles' filesep handles.matchfile{i}], 'mp', '-MAT');
    %Back-up mp files
    copyfile(['matchfiles/' handles.matchfile{i}], output_dir);
    
    if sum(handles.mp_2{i})~=0 %if mp_2 isn't empty
        mp=handles.mp_2{i}; % save secondary dataset
        
        a=split(handles.matchfile{i},'/');
        if ~isfield(handles,'matchfile_secondary') %if none of the cores was provided wit a secondary matchfile
            for j = 1:handles.N
                a_temp=split(handles.matchfile{j},'/');
                handles.matchfile_secondary{j}=[a_temp{end}(1:end-4) '_secondary.mat'];
            end
        end
        if isempty(handles.matchfile_secondary{i}) %if any one of the cores was provided wit a secondary matchfile
            handles.matchfile_secondary{i}=['secondary_temp_' num2str(i) '.mat'];
        end
        
        b=split(handles.matchfile_secondary{i},'/');
        
        if strcmp(a{end},b{end}) %if they are called the same
            disp('The reference and secondary matchfile are called the same. This can cause conflicts.');
            disp(['Saving secondary matchfile as ' handles.matchfile_secondary{i}(1:end-4) '_secondary.mat']);
            
            save(['matchfiles' filesep handles.matchfile_secondary{i}(1:end-4) '_secondary.mat' ], 'mp', '-MAT');%,'save mp_2'
            copyfile(['matchfiles/' handles.matchfile_secondary{i}(1:end-4) '_secondary.mat'   ], output_dir); % save backup
        else
            save(['matchfiles' filesep handles.matchfile_secondary{i} ], 'mp', '-MAT');%,'save mp_2'
            copyfile(['matchfiles/' handles.matchfile_secondary{i} ], output_dir); % save backup
        end
    end
end
copyfile([init_file_name '.m'], output_dir); % save init_file_name in backup folder
disp(['Output directory: ','/',output_dir]);
set(handles.save, 'enable', 'off');

%---

function hide_minor_mp_Callback(hObject, handles, keyboardcall)

if keyboardcall
    set(handles.hide_minor_mp, 'value', get(handles.hide_minor_mp, 'value')==0);
end
if get(handles.hide_minor_mp,'Value') %if enabled
    set([handles.thin_mark, handles.years_mark], 'Enable', 'off');
elseif ~get(handles.hide_minor_mp,'Value') & get(handles.edit,'Value') %if not enabled and editable
    set([handles.thin_mark, handles.years_mark], 'Enable', 'on');  

end

handles.multiple_opening_indicator=1;
for i = 1:handles.N
    handles = plotmp(handles, i);

end

handles.multiple_opening_indicator=0;

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
sett.command_line_info={handles.init_file_name;handles.fileno};
save('matchmaker_sett.mat', 'sett'); %Saves xlim and the displayed species so they are re-loaded next time you open the program
if isfield(handles, 'evaluatefigurehandle')
    delete(handles.evaluatefigurehandle)
end
delete(handles.fig)

%---

function undo_Callback(hObject, handles)
try
    saved_moves= handles.saved_moves;
catch e
    saved_moves=0;
end

if saved_moves<1
   	set(handles.undo,'enable','off');
    disp('Undo : no move in memory');
    set(handles.save,'enable','off');

end
if and(~isnan(saved_moves),saved_moves>0)
    
    no1=handles.lastmove{saved_moves,3}; %retrieve ice core
    
    if get(handles.edit, 'Value') == 1
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

function save_fig_Callback(~, handles)
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
% P : point of click in data units
% x_axis: X_axis handle

min_X=x_axis.XLim(1);
max_X=x_axis.XLim(2);
ab_data_units=max_X-min_X;

set(x_axis,'units','inch');
ab_inch=get(x_axis,'Position');
ab_inch=ab_inch(3);% x_axis width in inches
set(x_axis,'units','normalized');

K = ab_data_units / ab_inch; %conversion factor between data units and inches

[min_dist,closest_idx]=min(abs(mp(:,1)-P));
mptype=mp(closest_idx,2);
if mptype==7
    LW=2;
elseif mptype==6
    LW=2;
elseif mptype==2 | mptype==5
    LW=4;
elseif mptype==1 | mptype==3 | mptype==4
    LW=6;
else
    LW=NaN;  % no mp was clicked
    delindx=[];
    return;
end
LW_inch=LW/72; % width of mp marker in inches according to MATLAB documentation

LW_data_units =LW_inch * K;

tol_x=LW_data_units/2;

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

%color selector:
color=uisetcolor(handles.colours{no1}(handles.selectedspecs{no1}(no2),:),...
    ['Select a color for: ' handles.species{no1}{handles.selectedspecs{no1}(no2)}]);
%update color
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
eval(handles.init_file_name); %load file names of icecores to be able to access the init_file_name
save(['data' filesep files.datafile{handles.fileno(no1)}],'colours','-append'); %save new colors in init_file_name

if color_activated_save==1 %if save was activated only by the color button
    set(handles.save, 'enable', 'off'); %put if off again
end



%

function mptype=determine_mptype_from_click(handles)

selectiontype = get(handles.fig, 'selectiontype');
ref_mark = get(handles.ref_mark, 'Value');
years_mark = get(handles.years_mark, 'Value');
thin_mark = get(handles.thin_mark, 'Value');

if ref_mark & strcmp(get(handles.ref_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 1;
    elseif strcmp(selectiontype, 'extend') %shift-click
        mptype = 3;
    elseif strcmp(selectiontype, 'alt')  %right click
        mptype=4;
    end
elseif years_mark & strcmp(get(handles.years_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 6;
    elseif strcmp(selectiontype, 'alt')  %rightclick
        mptype=7;
    elseif strcmp(selectiontype, 'extend') %shift-click
        mptype = 7;
    end
elseif thin_mark & strcmp(get(handles.thin_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 2;
    elseif strcmp(selectiontype, 'alt')  %right-click
        mptype=5;
    elseif strcmp(selectiontype, 'extend') %shift-click
        mptype = 5;
    end
else
    return;
end

%--

function  edit_marks_callback(~,handles,keyboardcall)

if keyboardcall == 1
    state = get(handles.edit, 'Value');
    if state == 1
        set(handles.edit, 'Value', 0);
    else
        set(handles.edit, 'Value', 1);
    end
end
if get(handles.edit,'Value')==1 % if made editable
    if ~get(handles.hide_minor_mp,'Value') & ~handles.too_many_years
        set(handles.radiogroup,'Enable','on');
    elseif ~get(handles.hide_minor_mp,'Value') & handles.too_many_years
        set(handles.thin_mark,'Enable','on');
        set(handles.ref_mark,'Enable','on');
    else
        set(handles.ref_mark,'Enable','on');
    end
else
    set(handles.radiogroup,'Enable','off');
    
end

%--Ref layer callback
function ref_mark_Callback(hObject, handles, keyboardcall)

set(handles.radiogroup, 'Value', 0);
if keyboardcall == 1
    state = get(handles.ref_mark, 'Value');
    if state == 1
        set(handles.ref_mark, 'Value', 0);
    else
        set(handles.ref_mark, 'Value', 1);
    end
end
if keyboardcall == 0
    set(handles.ref_mark, 'Value', 1);
end
handles.multiple_opening_indicator=1;
for i = 1:handles.N
    handles = plotmp(handles, i);
end
handles.multiple_opening_indicator=0;
guidata(hObject, handles);

%--Temp mp callback
function temp_mark_Callback(hObject, handles, keyboardcall)

set(handles.radiogroup, 'Value', 0);
if keyboardcall == 1
    state = get(handles.thin_mark, 'Value');
    if state == 1
        set(handles.thin_mark, 'Value', 0);
    else
        set(handles.thin_mark, 'Value', 1);
    end
end
if keyboardcall == 0
    set(handles.thin_mark, 'Value', 1);
end
handles.multiple_opening_indicator=1;
for i = 1:handles.N
    handles = plotmp(handles, i);
end
handles.multiple_opening_indicator=0;
guidata(hObject, handles);

%--years layer callback
function years_mark_Callback(hObject, handles, keyboardcall)
set(handles.radiogroup, 'Value',0);
if keyboardcall == 1
    
    state = get(handles.years_mark, 'Value');
    if state == 1
        set(handles.years_mark, 'Value', 0);
    else
        set(handles.years_mark, 'Value', 1);
    end
end
if keyboardcall == 0
    set(handles.years_mark, 'Value', 1);
end
handles.multiple_opening_indicator=1;
for i = 1:handles.N
    handles = plotmp(handles, i);
end
handles.multiple_opening_indicator=0;
guidata(hObject, handles);


function create_secondary(hObject,handles,no1, not_allowed_mp)

    handles.mp_2{no1} = not_allowed_mp;
    if ~isfield(handles,'matchfile_secondary') 
        handles.matchfile_secondary{no1}=handles.matchfile{no1};
    elseif isempty(handles.matchfile_secondary{no1})
        handles.matchfile_secondary{no1}=handles.matchfile{no1};
    end
    delete(gcf);
guidata(hObject, handles);

function handles = plot_mp_subfunction(handles, mp, xlim, colors, bar_height, no1, bottom_pos)

secondary_marks = get(handles.secondary_marks, 'Value'); %if the secondary set is shown

if secondary_marks ==1 & bottom_pos>0.5
    belonging_to_mp_set = 0;
elseif secondary_marks ==1 & bottom_pos<0.5
    belonging_to_mp_set = 1;
else
    belonging_to_mp_set = 0;
end

too_many_mp_green=0; %reset
    N_max_MP=100; %set an arbitrary max number of mp that is possible to display
    N_max_mp_green=200; %set an arbitrary max number of green mp that is possible to display

if ~isempty(mp)
    
    % plot all mps within xlim(1) and xlim(2)
    mptypes=[1,3,4,2,5,6,7];
    show_mp = [1,1,1,1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value')];%if minor_mp button is toggled
    linewidth=[6,6,6,4,4,2,2];
    linetype={'-','-','-','-','-','-','-.'};
    
    %number the "reference" bars:
    mptypes_reference=[1,3,4];
    mp_reference = mp(ismember(mp(:,2),mptypes_reference),1);
    depth_subset_reference = find(mp_reference>=xlim(1) & mp_reference<=xlim(2));
    
    if length(depth_subset_reference)>N_max_MP %arbitrary limit of mp to display, prevents loading too slowly
        text( xlim(1), (bar_height(1)+bar_height(1)/15), 'The amount of matchpoints to display is very large. Please set x-limits to be smaller.', 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k', 'BackgroundColor', [1 1 1]);
        set(handles.edit, 'Enable', 'off');
        show_mp(1:5)=0;
    else
        text(mp_reference(depth_subset_reference), (bar_height(1)+bar_height(1)/15)*ones(length(depth_subset_reference),1), num2str(depth_subset_reference), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k');
        
        if handles.multiple_opening_indicator==1 & strcmp(get(handles.edit, 'Enable'),'off') %if, during the plotting of multiple ice cores, another ice core had too many mps
            set(handles.edit, 'Enable', 'off');
        else
            set(handles.edit, 'Enable', 'on');
        end

    end
    
    %number the "years" bars:
    mp_green = mp(ismember(mp(:,2),[6,7]),1);
    n_green_intervals=[];
    
    if ~isempty(depth_subset_reference)
        % number only after the left-most reference bar
        depth_subset_green = find(mp_green>=mp_reference(depth_subset_reference(1),1) & mp_green<=xlim(2));
        N_green = length(find(mp_green>=xlim(1) & mp_green<=xlim(2)));
        if ~isempty(depth_subset_green)
            %evaluate how many green bars between the reference horizons
            n_green_intervals(1)=1;
            [~,i_ref]=min(abs(mp_reference(depth_subset_reference,1) - mp_green(depth_subset_green(1)) ));
            for n=2:length(depth_subset_reference)-i_ref+1
                n_green_intervals(n)=length(find(mp_green>=mp_reference(depth_subset_reference(i_ref),1) & mp_green<=mp_reference(depth_subset_reference(i_ref+n-1),1)));
            end
            n_green_intervals(end+1)=length(depth_subset_green);
        end
    else %number all green bars
        depth_subset_green = find(mp_green>=xlim(1) & mp_green<=xlim(2));
        N_green=length(depth_subset_green);
        n_green_intervals(1)=1;
        n_green_intervals(2)=length(depth_subset_green);
    end
    
    if N_green>N_max_MP & N_green<=N_max_mp_green %arbitrary limit of mp to display, prevents loading too slowly
        too_many_mp_green=2; %only display end-of-interval numbers
    elseif N_green>N_max_mp_green %arbitrary limit of mp to display, prevents loading too slowly
        too_many_mp_green=1; %do not display any green bars and any numbers
        show_mp(6:7)=0;
    end
    
    %plot the mp of each type
    for i=1:length(mptypes) % for each type
        mp_subset=mp(mp(:,2)==mptypes(i),1);
        depth_subset=find(mp_subset>=xlim(1) & mp_subset<=xlim(2));
        
        if ~isempty(depth_subset) & show_mp(i)
            
            plot((mp_subset(depth_subset)*[1 1])', repmat([bottom_pos bar_height(i)]', 1, length(depth_subset)),...
                linetype{i},'linewidth', linewidth(i), 'color', colors(i,:),...
                'parent', handles.bigax2(no1),...
                'ButtonDownFcn', [' matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ');'],...
                'UserData',[mptypes(i),belonging_to_mp_set]);
            
        end
    end
    
    %plot the warning messages and the numbers for the green bars only
    if 1-get(handles.hide_minor_mp,'Value') % if the minor mps are visible
        switch too_many_mp_green
            case 0 %label all bars with all numbers
                text(mp_green(depth_subset_green), (bar_height(end)+bar_height(1)/15)*ones(length(depth_subset_green),1), ...
                    num2str((1:length(depth_subset_green))'), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', colors(6,:));
                if strcmp(get(handles.edit, 'Enable'), 'on') & get(handles.edit, 'Value')==1
                    if handles.multiple_opening_indicator==1 & strcmp(get(handles.years_mark, 'Enable'),'off') %if, during the plotting of multiple ice cores, another ice core had too many year-mps
                    set(handles.years_mark, 'Enable', 'off');
                    handles.too_many_years=1;
                    else
                    set(handles.years_mark, 'Enable', 'on');
                    handles.too_many_years=0;
                    end
                end

                handles.too_many_years=0;
            case 1 %do not display any green bars and any numbers

                text(mp_green(depth_subset_green(1)), (bar_height(end)-bar_height(end)/8), ...
                    'Not enough space for all years. Please zoom in or press "Hide minor mp".', 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', colors(6,:), 'BackgroundColor', [1 1 1]);
                for n=[1:length(n_green_intervals)] %plot the first and last interval numbers
                    text(mp_green(depth_subset_green(n_green_intervals(n))), (bar_height(end)+bar_height(1)/15), num2str(n_green_intervals(n)), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', colors(6,:));
                end
                set(handles.years_mark,'enable','off');
                handles.too_many_years=1;
            case 2 %only display end-of-interval numbers
                text(mp_green(depth_subset_green(1)), (bar_height(end)-bar_height(end)/8), ...
                    'Not enough space to label all numbers. Please zoom in.', 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', colors(6,:), 'BackgroundColor', [1 1 1]);
                for n=1:length(n_green_intervals) %plot the interval numbers
                    text(mp_green(depth_subset_green(n_green_intervals(n))), (bar_height(end)+bar_height(1)/15), num2str(n_green_intervals(n)), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', colors(6,:));
                end
                if strcmp(get(handles.edit, 'Enable'), 'on') & get(handles.edit, 'Value')==1
                    if handles.multiple_opening_indicator==1 & strcmp(get(handles.years_mark, 'Enable'),'off') %if, during the plotting of multiple ice cores, another ice core had too many year-mps
                    set(handles.years_mark, 'Enable', 'off');
                    handles.too_many_years=1;
                    else
                    set(handles.years_mark, 'Enable', 'on');
                    handles.too_many_years=0;
                    end                    
                end
                handles.too_many_years=0;
        end
    end
    
    %keep track of the plotted reference mps for the accordianize and evaluate function:
    if bottom_pos>0.5 & secondary_marks
        if ~isempty(depth_subset_reference)
            handles.mp1_idx{no1} = depth_subset_reference;
            handles.mp1_depth{no1} = mp_reference(depth_subset_reference);
        else
            handles.mp1_idx{no1}=0;
            handles.mp1_depth{no1} = [];
        end
    elseif bottom_pos<0.5 & secondary_marks
        handles.mp1_idx{no1} = handles.mp1_idx{no1};
        handles.mp1_depth{no1} = handles.mp1_depth{no1};        
    elseif bottom_pos<0.5 & ~secondary_marks
        if ~isempty(depth_subset_reference)
            handles.mp1_idx{no1} = depth_subset_reference;
            handles.mp1_depth{no1} = mp_reference(depth_subset_reference);
        else
            handles.mp1_idx{no1}=0;
            handles.mp1_depth{no1} = [];
        end
    end
    
    
    % check if any mps have wrong types and create a warning
    not_allowed_mp=mp(~ismember(mp(:,2),mptypes),:);
    
    if ~isempty(not_allowed_mp)
        L=length(not_allowed_mp);
        d = msgbox({...
            'Not allowed mp types in the matchfile of:',handles.name(no1).String,...
            'Problem for matchpoints (depth,type):',...
            num2str(not_allowed_mp), ...
            'The program will continue without displaying them, although they will be preserved when saving.',...
            'In the future: to compare secondary sets of mps on the same ice core, create a secondary matchfile (see user guide).'});
        uiwait(d);
        
        mp=mp(ismember(mp(:,2),mptypes),:);
        handles.mp{no1} = mp; %update the mp dataset to remove the unnecessary mps
        handles.not_allowed_mp{no1}=not_allowed_mp; % they are preserved here and saved at the end
    end
    if length(handles.mp1_idx{str2double(get(handles.masterno, 'string'))})<2
    set(handles.evaluate, 'Enable', 'off');
else
    set(handles.evaluate, 'Enable', 'on');
end
end

