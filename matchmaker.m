function matchmaker(varargin)
% ------------------------------------------------------------------------
% MATCHMAKER GIT running version
% (Originally released as v2.04, 27 July 2011, Sune Olander Rasmussen)
% MATCHMAKER syntax : matchmaker(filenames, datafileID, numberofpanels);
%    filenames        Name of .m file containing a list of data and matchpoint file names (try 'files_main')
%    datafileID       Vector of length N indicating which init_file_name from "filenames" that should be used
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
    'Toolbar', 'none');

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
        disp(['Matchfile_secondary file for ' files.core{fileno(i)} ' not found. Program will continue without.']);
        mp_2=zeros(1,2);
        handles.mp_2{i}=zeros(1,2);
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

%font sizes
font1 = 8;
font2 = 10;

%vertical dimensions (normalized)
bottom_edge_pos = 0.001;
ax_xlabel_H = 0.03;
ax_vert_spacing = 0.015;
ax_H = (1-bottom_edge_pos-(N+2)*ax_vert_spacing)/N;
species_overlap_H = 0.45; % fraction
ax_species_H = (ax_H-ax_xlabel_H)./(N_species-(N_species-1)*species_overlap_H);
button_H = 0.025;
button_y_spacing = 0.0016;

%horizontal dimensions (normalized)
buttons_left_edge_pos = 0.005;
ax_left_edge_pos = 0.1;
ax_width = 0.835;
N_buttons=13;
button_L = (1-ax_left_edge_pos)/N_buttons;
small_button_L=button_L/2;
button_x_spacing =0.001;

%BOTTOM LINE BUTTONS
dummyax = axes('position', [0 0 1 1], 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off', 'nextplot', 'add');
handles.title = text(buttons_left_edge_pos, bottom_edge_pos,...
    'MATCHMAKER', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
handles.save = uicontrol('units', 'normalized', ...
    'position', [ax_left_edge_pos, bottom_edge_pos, button_L/2, button_H],...
    'string', 'Save', 'style', 'pushbutton', ...
    'Tooltip', ['Saves all matchfiles.' 10 'Creates backup files of everything. (S)'],...
    'callback', 'matchmaker(''save_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'off', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.save,'position');
handles.save_fig = uicontrol('units', 'normalized',...
    'position', [p_neighbour(1)+p_neighbour(3)+button_x_spacing, bottom_edge_pos, button_L/2, button_H],...
    'string', 'SaveFig', 'style', 'pushbutton',...
    'Tooltip', 'Saves a figure.',...
    'callback', 'matchmaker(''save_fig_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'enable', 'on',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.save_fig,'position');
handles.accordianize = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Accordianize', 'style', 'pushbutton', ...
    'Tooltip', ['Align 1st and Last tiepoint of all icecores.' 10 'Won''''t work in case of mp number mismatch.  (Spacebar)'],...
    'callback', 'matchmaker(''accordianize_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.accordianize,'position');
handles.masterno = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, small_button_L, button_H],...
    'Tooltip', 'Set which icecore to align to.',...
    'string', '1', 'style', 'edit', ...
    'callback', 'matchmaker(''masterno_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
p_neighbour=get(handles.masterno,'position');
handles.evaluate = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Evaluate', 'style', 'pushbutton', ...
    'Tooltip', 'Opens new panel with evaluation tools.',...
    'callback', 'matchmaker(''evaluate_Callback'',gcbo,[],guidata(gcbo), ''button'')', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.evaluate,'position');
handles.edit = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Edit mps', 'style', 'togglebutton', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, ...
    'Tooltip', 'Activate MatchPoint adding/removing. (E)',...
    'callback','matchmaker(''edit_marks_callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.edit,'position');
handles.ref_mark = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Reference mps', 'style', 'radio', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 1, ...
    'Tooltip', 'Edit type 1(click),3(shift-click),4(r-click) (R)',...
    'callback','matchmaker(''ref_mark_Callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.ref_mark,'position');
handles.temp_mark =    uicontrol('units', 'normalized',...
    'Tooltip', 'Edit type 2(click),5(r-click) (T)',...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Thin mps', 'style', 'radio',...
    'callback','matchmaker(''temp_mark_Callback'',gcbo,[],guidata(gcbo), 0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.temp_mark,'position');
handles.annual_mark =    uicontrol('units', 'normalized',...
    'Tooltip', 'Edit type 6(click),7(r-click) (Y)',...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Years mps', 'style', 'radio',...
    'callback', 'matchmaker(''annual_mark_Callback'',gcbo,[],guidata(gcbo),0)',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
% Get all the handles to everything we want to set in a single array.
handles.radiogroup = [handles.ref_mark, handles.annual_mark, handles.temp_mark];
% Set them all disabled. They can only be enabled if pressing the edit
% marks button
set(handles.radiogroup, 'Enable', 'off');
%
p_neighbour=get(handles.annual_mark,'position');
handles.hide_minor_mp = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Hide minor mps', 'style', 'togglebutton', ...
    'Tooltip', 'Hide minor mp, i.e. types 2,5,6,7. (H)',...
    'callback', 'matchmaker(''hide_minor_mp_Callback'',gcbo,[],guidata(gcbo),0)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, 'Selected', 'off', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))',...
    'value',1);
p_neighbour=get(handles.hide_minor_mp,'position');
handles.secondary_marks = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Show secondary', 'style', 'togglebutton', ...
    'Tooltip', 'Show secondary matchfile. (J)',...
    'callback', 'matchmaker(''secondary_marks_Callback'',gcbo,[],guidata(gcbo), 0)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 0, ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');

p_neighbour=get(handles.secondary_marks,'position');
handles.check = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L, button_H],...
    'string', 'Check mps', 'style', 'pushbutton', ...
    'Tooltip', 'Displays matchmaker diagnostics on command window.',...
    'callback', 'matchmaker(''check_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.check,'position');

handles.undo = uicontrol('units', 'normalized',...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L/2, button_H],...
    'string', 'UNDO', 'style', 'pushbutton',...
    'Tooltip', ['Cancels new mp and Re-adds removed mp.' 10 ' (U)'],...
    'callback', 'matchmaker(''undo_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center',...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
p_neighbour=get(handles.undo,'position');

handles.exit = uicontrol('units', 'normalized', ...
    'position', [p_neighbour(1)+p_neighbour(3) + button_x_spacing, bottom_edge_pos, button_L/2, button_H],...
    'string', 'Exit', 'style', 'pushbutton', ...
    'Tooltip', 'Exit program. (X)',...
    'callback', 'matchmaker(''exit_Callback'',gcbo,[],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', ...
    'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
handles.N_undo=1000; % how many moves are saved in memory
handles.lastmoves=cell(handles.N_undo,1);

% BUTTONS FOR EACH ICE CORE
for i = 1:N
    
    main_ax_y_pos=bottom_edge_pos+2*ax_vert_spacing+ax_xlabel_H+(i-1)*(ax_H+ax_vert_spacing);
    primary_button_column_ypos = main_ax_y_pos+ax_H-2*ax_vert_spacing;
    
    handles.bigax(i) = axes('position', [ax_left_edge_pos, main_ax_y_pos, ax_width, ax_H-ax_xlabel_H],...
        'nextplot', 'add', 'ylim', [0 1], 'ytick', [], 'box', 'off', 'fontsize', font1, 'ycolor', 'w', 'xcolor', 'w',...
        'ButtonDownFcn', ['matchmaker(''axesclick_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'],...
        'hittest','on');
    set(handles.bigax(i) ,'interactions',[])
    handles.bigax2(i) = axes('position', [ax_left_edge_pos, main_ax_y_pos , ax_width, ax_H-ax_xlabel_H], 'nextplot', 'add', 'visible', 'off',...
        'hittest', 'off', 'clipping', 'on', 'ylim', [0 1]);
    handles.name(i) = text(buttons_left_edge_pos, primary_button_column_ypos,...
        files.core{fileno(i)}, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
    handles.minx(i) = uicontrol('units', 'normalized', ...
        'position', [buttons_left_edge_pos, primary_button_column_ypos-2*(button_H+button_y_spacing), small_button_L, button_H],...
        'string', '0', 'style', 'edit', ...
        'Tooltip', 'Min X Limit',...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    text(buttons_left_edge_pos+small_button_L, primary_button_column_ypos-2*(button_H+button_y_spacing),'m', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font1, 'fontweight', 'normal', 'parent', dummyax);
    handles.maxx(i) = uicontrol('units', 'normalized', ...
        'position', [buttons_left_edge_pos, primary_button_column_ypos-3*(button_H+button_y_spacing) small_button_L, button_H],...
        'Tooltip', 'Max X Limit',...
        'string', '1', 'style', 'edit', ...
        'callback', ['matchmaker(''xscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    text(buttons_left_edge_pos+small_button_L, primary_button_column_ypos-3*(button_H+button_y_spacing),'m', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font1, 'fontweight', 'normal', 'parent', dummyax);
    handles.back(i) = uicontrol('units', 'normalized', ...
        'position', [buttons_left_edge_pos, primary_button_column_ypos-5*(button_H+button_y_spacing) small_button_L, button_H],...
        'string', '<--', 'style', 'pushbutton', ...
        'Tooltip', 'Move Back',...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', -1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.fwd(i) = uicontrol('units', 'normalized', ...
        'position', [buttons_left_edge_pos, primary_button_column_ypos-6*(button_H+button_y_spacing) small_button_L, button_H],...
        'string', '-->', 'style', 'pushbutton', ...
        'Tooltip', 'Move Forward',...
        'callback', ['matchmaker(''move_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ', 1)'], 'fontname', 'default', 'fontsize', font2, 'fontweight', 'bold', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
    handles.incx(i) = uicontrol('units', 'normalized', ...
        'position', [buttons_left_edge_pos, primary_button_column_ypos-7*(button_H+button_y_spacing) small_button_L, button_H],...
        'string', '1', 'style', 'edit', ...
        'Tooltip','X-Axis Moving increment',...
        'callback', ['matchmaker(''incx_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
    text(buttons_left_edge_pos+small_button_L, primary_button_column_ypos-7*(button_H+button_y_spacing),'m', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font1, 'fontweight', 'normal', 'parent', dummyax);
    
end
sides = [{'right'} {'left'}];
% BUTTONS FOR EACH SPECIES
for i = 1:N
    
    handles.tickax{i,1} = axes('position', [ax_left_edge_pos, bottom_edge_pos+2*ax_vert_spacing+ax_xlabel_H+(i-1)*(ax_H+ax_vert_spacing) ax_width ax_species_H(i)], 'nextplot', 'add', 'color', 'none', 'xcolor', 'k', 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', 'left', 'xaxislocation', 'bottom', 'hittest', 'off', 'fontweight', 'bold');
    handles.plotax{i,1} = axes('position', [ax_left_edge_pos, bottom_edge_pos+2*ax_vert_spacing+ax_xlabel_H+(i-1)*(ax_H+ax_vert_spacing) ax_width ax_species_H(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
    
    for j = 1:N_species(i)
        
        species_yax_ypos=bottom_edge_pos+2*ax_vert_spacing+ax_xlabel_H+(i-1)*(ax_H+ax_vert_spacing)+(j-1)*(1-species_overlap_H)*ax_species_H(i);
        if j > 1
            
            handles.tickax{i,j} = axes('position', [ax_left_edge_pos species_yax_ypos ax_width ax_species_H(i)], 'nextplot', 'add', 'ycolor', handles.colours{i}(handles.selectedspecs{i}(j),:), 'color', 'none', 'xcolor', 'w', 'xtick', [], 'ylim', [0 1], 'box', 'off', 'fontsize', font1, 'yaxislocation', sides{mod(j,2)+1}, 'xaxislocation', 'top', 'hittest', 'off', 'fontweight', 'bold');
            handles.plotax{i,j} = axes('position', [ax_left_edge_pos species_yax_ypos ax_width ax_species_H(i)], 'nextplot', 'replacechildren', 'visible', 'off', 'hittest', 'off');
        end
        %position of species-button column can be left or right depending on mod(n,2)
        secondary_button_column_xpos = (mod(j,2)==1)*(buttons_left_edge_pos+10*button_x_spacing+small_button_L)...%left
            +(mod(j,2)==0)*(1-(buttons_left_edge_pos+small_button_L)-3*button_x_spacing);%right
        
        N_secondary_buttons=5;
        handles.spec{i,j}  = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos,  species_yax_ypos+N_secondary_buttons*button_H+6*button_y_spacing, small_button_L, button_H],...
            'Tooltip', 'Select species to display',...
            'string', handles.species{i}, 'value', handles.selectedspecs{i}(j), 'style', 'popupmenu', 'callback', ['matchmaker(''spec_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center');
        handles.autoy{i,j} = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos, species_yax_ypos+(N_secondary_buttons-1)*button_H+button_y_spacing, small_button_L/2, button_H],...
            'string', 'Aut', 'style', 'togglebutton', ...
            'Tooltip', 'Automatic y-axis limits',...
            'callback', ['matchmaker(''autoy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'value', 1, 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        handles.logy{i,j}  = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos+small_button_L/2+button_x_spacing species_yax_ypos+(N_secondary_buttons-1)*button_H (small_button_L-button_y_spacing)/2, button_H],...
            'string', 'Log', 'style', 'togglebutton', ...
            'Tooltip', 'Set y-axis to log',...
            'callback', ['matchmaker(''logy_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        handles.offset{i,j} = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos, species_yax_ypos+(N_secondary_buttons-2)*button_H+button_y_spacing, small_button_L-0.01, button_H],...
            'string', 0, 'style', 'edit', ...
            'Tooltip', 'Shift X-Axis by this offset (m)',...
            'callback', ['matchmaker(''offset_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        text(secondary_button_column_xpos+small_button_L-0.01, species_yax_ypos+(N_secondary_buttons-2)*button_H+button_y_spacing,'m', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font1, 'fontweight', 'normal', 'parent', dummyax);
        handles.maxy{i,j} = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos, species_yax_ypos+(N_secondary_buttons-3)*button_H+button_y_spacing, small_button_L, button_H],...
            'string', 1, 'style', 'edit', ...
            'Tooltip', 'Max Y (arb.units)',...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 2)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        handles.miny{i,j} = uicontrol('units', 'normalized', ...
            'position', [secondary_button_column_xpos, species_yax_ypos+(N_secondary_buttons-4)*button_H+button_y_spacing, small_button_L, button_H],...
            'string', 0, 'style', 'edit', ...
            'Tooltip', 'Min Y (arb.units)',...
            'callback', ['matchmaker(''yscale_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ', 1)'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'right');
        
        % button to change color of species
        handles.color_change{i,j} = uicontrol('units', 'normalized','Tooltip', 'Color',...
            'position', [secondary_button_column_xpos, species_yax_ypos+(N_secondary_buttons-5)*button_H+button_y_spacing, small_button_L, button_H],...
            'string', 'Color', 'style', 'pushbutton',...
            'Tooltip','Change color of species. Changes are saved automatically.',...
            'callback', ['matchmaker(''change_color_Callback'',gcbo,[],guidata(gcbo),' num2str(i) ',' num2str(j) ')'], 'fontname', 'default', 'fontsize', font1, 'fontweight', 'normal', 'horizontalalignment', 'center', 'enable', 'on', 'KeyPressFcn', 'matchmaker(''keypressed_Callback'',gcbo,[],guidata(gcbo))');
        
    end
    if isequal(sett.command_line_info,{handles.init_file_name;handles.fileno})
    set([handles.tickax{i,:} handles.plotax{i,:} handles.bigax(i) handles.bigax2(i)], 'xlim', sett.xlim(fileno(i),:)); % Set the x limits according to the last values
    set(handles.minx(i), 'string', num2str(sett.xlim(fileno(i),1)));
    set(handles.maxx(i), 'string', num2str(sett.xlim(fileno(i),2)));
    end
end
for i = 1:N
    axes(handles.bigax2(i));
end
handles.storeidx = [];
guidata(handles.fig, handles);
for i = 1:N
    for j = 1:N_species(i)
        axes(handles.plotax{i,j});
        plotcurve(handles, i, j);
    end
    
    %plots all mp for the first time
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
if ~isreal(value) | length(value) ~= 1 % check if input is valid
    set(handles.offset{no1, no2}, 'string', '0');
end
plotcurve(handles, no1, no2);
update_yminmax(hObject, handles, no1, no2); % The view has changed, so update the y-sacle edit-boxes

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
for i = 1:handles.N
    plotmp(handles, i);
end

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
if get(handles.edit, 'Value') == 1 % it it's possible to edit mps
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
    del_idx=check_mp_click_inches_conversion(mp,pos(1,1),handles.bigax(no1));
    
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
if get(handles.edit, 'Value') == 1 %if it's possible to mark mps
    
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
    mp_2 = mp_2(setdiff(1:length(mp_2(:,1)), delindx_2),:);
    
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
    set([handles.spec{no1, j} handles.offset{no1, j} handles.autoy{no1, j} handles.logy{no1, j} handles.miny{no1, j} handles.maxy{no1, j}], 'Backgroundcolor', 'w', 'Foregroundcolor', handles.colours{no1}(handles.selectedspecs{no1}(j),:));
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

% collect current mp data
mp = handles.mp{no1};
if isfield(handles,'mp_2')
    mp_2=handles.mp_2{no1};
end
% collect current depth limits
xlim = get(handles.bigax(no1), 'xlim');
too_large_flag=0;

if isempty(mp)
    return
else
    secondary_marks = get(handles.secondary_marks, 'Value'); %logical value to decide whether to plot full screen or only top half
    % plot all mps within xlim(1) and xlim(2)
    mptypes=[1,3,4,2,5,6,7];
    show_mp = [1,1,1,1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value'),1-get(handles.hide_minor_mp,'Value')];%if minor_mp button is toggled
    linewidth=[6,6,6,4,4,2,1];
    colors=[greytone; redtone; bluetone; greytone; bluetone; greentone; greentone];
    bar_height=[0.93;0.93;0.93;0.88;0.88;0.85;0.85];
    
    for i=1:length(mptypes)

        mp_subset=mp(mp(:,2)==mptypes(i),1);
        depth_subset=find(mp_subset>=xlim(1) & mp_subset<=xlim(2));
        if length(depth_subset)>100
            
            too_large_flag=1;
            break
        end
        if ~isempty(depth_subset) & show_mp(i) & ~too_large_flag
            plot((mp_subset(depth_subset)*[1 1])', repmat([0.01+secondary_marks*0.5 bar_height(i)]', 1, length(depth_subset)), 'linewidth', linewidth(i), 'color', colors(i,:),...
                'parent', handles.bigax2(no1),...
                'ButtonDownFcn', [' matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ');'],...
                'UserData',[mptypes(i),secondary_marks]);
        end
    end
    
    %number the "primary" bars:
    mptypes_primary=[1,3,4];
    mp_primary = mp(ismember(mp(:,2),mptypes_primary),1);
    depth_subset_primary = find(mp_primary>=xlim(1) & mp_primary<=xlim(2));
    if ~too_large_flag
    text(mp_primary(depth_subset_primary), (bar_height(1)+bar_height(1)/15)*ones(length(depth_subset_primary),1), num2str(depth_subset_primary), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k');
    else
    text(mp_primary(depth_subset_primary(1)), (bar_height(1)+bar_height(1)/15), 'The amount of matchpoints to display is very large. Please set x-limits to be smaller.', 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k');       
    end
    %keep track of the plotted primary mps for the evaluate function:
    if ~isempty(depth_subset_primary) & ~too_large_flag
        handles.mp1_idx{no1} = depth_subset_primary;
        handles.mp1_depth{no1} = mp_primary(depth_subset_primary);
    else
        handles.mp1_idx{no1} = 0;
        handles.mp1_depth{no1} = [];
    end
    
    %green layers numbering
    mp_green = mp(ismember(mp(:,2),[6,7]),1);
    if ~isempty(depth_subset_primary) & ~too_large_flag
        % number only after the left-most primary bar
        depth_subset_green = find(mp_green>=mp_primary(depth_subset_primary(1),1) & mp_green<=xlim(2));
    else
        %number all
        depth_subset_green = find(mp_green>=xlim(1) & mp_green<=xlim(2));
    end
    if 1-get(handles.hide_minor_mp,'Value')
        text(mp_green(depth_subset_green), (bar_height(end)+bar_height(1)/15)*ones(length(depth_subset_green),1), num2str((1:length(depth_subset_green))'), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', greentone);
    end
    
    %check if any mps have wrong types and create a warning    
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
    % Same procedure for the "secondary_/mp_2" dataset
    if secondary_marks & ~too_large_flag
        if ~isempty(mp_2)
            
            % plot all mps within xlim(1) and xlim(2)
            mptypes=[1,3,4,2,5,6,7];
            linewidth=[6,6,6,4,4,2,1];
            colors=[greytone_2; redtone_2; bluetone_2; greytone_2; bluetone_2; greentone_2; greentone_2];
            bar_height=[0.93;0.93;0.93;0.88;0.88;0.85;0.85]/2; %half height
            for i=1:length(mptypes)
                mp_subset=mp_2(mp_2(:,2)==mptypes(i),1);
                depth_subset=find(mp_subset>=xlim(1) & mp_subset<=xlim(2));
                if ~isempty(depth_subset) & show_mp(i)
                    plot((mp_subset(depth_subset)*[1 1])', repmat([0.01 bar_height(i)]', 1, length(depth_subset)), 'linewidth', linewidth(i), 'color', colors(i,:), 'parent', handles.bigax2(no1), 'ButtonDownFcn', ['matchmaker(''mpclick_Callback'',gcbo,[],guidata(gcbo),' num2str(no1) ');'],...
                        'UserData',[mptypes(i),secondary_marks]);
                end
            end
            %number the "primary" bars:
            mptypes_primary=[1,3,4];
            mp_primary = mp_2(ismember(mp_2(:,2),mptypes_primary),1);
            depth_subset_primary = find(mp_primary>=xlim(1) & mp_primary<=xlim(2));
            text(mp_primary(depth_subset_primary), (bar_height(1)+bar_height(1)/8)*ones(length(depth_subset_primary),1), num2str(depth_subset_primary), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'fontangle', 'italic', 'color', 'k');
            
            mp_2_green = mp_2(ismember(mp_2(:,2),[6,7]),1);
            
            if ~isempty(depth_subset_primary) %green layers numbering
                depth_subset_green = find(mp_2_green>=mp_primary(depth_subset_primary(1),1) & mp_2_green<=xlim(2));
            else
                depth_subset_green = find(mp_2_green>=xlim(1) & mp_2_green<=xlim(2));
            end
            if 1-get(handles.hide_minor_mp,'Value')
                text(mp_2_green(depth_subset_green), (bar_height(end)+bar_height(1)/8)*ones(length(depth_subset_green),1), num2str((1:length(depth_subset_green))'), 'parent', handles.bigax2(no1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top ', 'fontsize', get(handles.tickax{1,1}, 'fontsize'), 'color', greentone_2);
            end
        end
    end
    
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
        case {32}    %spacebar
            accordianize_Callback(hObject, handles);
        case {101, 69}  %e, E
            edit_marks_callback(hObject,handles,1);
        case {104,72}  %h, H
            hide_minor_mp_Callback(hObject, handles,1);
        case {106,74}  %j, J
            secondary_marks_Callback(hObject, handles,1);
        case {114, 82}   %r, R
            ref_mark_Callback(hObject, handles, 1);
        case {115, 83}  %s, S
            if strcmp(get(handles.save, 'enable'), 'on')
                save_Callback(hObject, handles);
            end
        case {116, 84}  %t, T
            temp_mark_Callback(hObject, handles, 1)
        case {117, 85}  %u,U
            undo_Callback(hObject, handles)
        case {120, 88}  %x, X
            exit_Callback(hObject, handles);
        case {121, 89}  %y, Y
            annual_mark_Callback(hObject,handles,1);
        otherwise % If key not defined, show info window
            h_help = helpdlg({...
                'Available keyboard commands:';
                '<- = move selected core one frame back and accordianize'
                '-> = move selected core one frame forward and accordianize'
                'Spacebar  = Accordianize'
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
else
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
end
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
datafile=handles.init_file_name;

if ~exist(['matchfiles/matchfiles_backup/' datafile '/' ],'dir')
    mkdir(['matchfiles/matchfiles_backup/' datafile '/' ]); % create backup folder with datafile name
end
backup_dir=['matchfiles/matchfiles_backup/' datafile '/' ];
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
        b=split(handles.matchfile_secondary{i},'/');
        
        if strcmp(a{end},b{end}) %if they are called the same
            disp('The primary and secondary matchfile are called the same. This can cause conflicts.');
            disp(['Saving secondary matchfile as ' handles.matchfile_secondary{i}(1:end-4) '_secondary.mat']);
            
            save(['matchfiles' filesep handles.matchfile_secondary{i}(1:end-4) '_secondary.mat' ], 'mp', '-MAT');%,'save mp_2'
            copyfile(['matchfiles/' handles.matchfile_secondary{i}(1:end-4) '_secondary.mat'   ], output_dir); % save backup
        else
            save(['matchfiles' filesep handles.matchfile_secondary{i} ], 'mp', '-MAT');%,'save mp_2'
            copyfile(['matchfiles/' handles.matchfile_secondary{i} ], output_dir); % save backup
        end
    end
end
copyfile([datafile '.m'], output_dir); % save init_file_name in backup folder
disp(['Output directory: ','/',output_dir]);
set(handles.save, 'enable', 'off');

%---

function hide_minor_mp_Callback(hObject, handles, keyboardcall)

if keyboardcall
    set(handles.hide_minor_mp, 'value', get(handles.hide_minor_mp, 'value')==0);
end
if get(handles.hide_minor_mp,'Value')
    set([handles.temp_mark, handles.annual_mark], 'Enable', 'off');
else
    set([handles.temp_mark, handles.annual_mark], 'Enable', 'on');
    
end
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
sett.command_line_info={handles.init_file_name;handles.fileno};
save('matchmaker_sett.mat', 'sett'); %Saves xlim and the displayed species so they are re-loaded next time you open the program
if isfield(handles, 'evaluatefigurehandle')
    delete(handles.evaluatefigurehandle)
end
delete(handles.fig)

%---

function handles=undo_Callback(hObject, handles)

try
    saved_moves= handles.saved_moves;
catch e
    saved_moves=0;
end

if saved_moves<1
    disp('Undo : no move in memory');
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
    LW=1;
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
eval(handles.init_file_name); %load file names of icecores to be able to access the datafile
save(['data' filesep files.datafile{handles.fileno(no1)}],'colours','-append'); %save new colors in datafile

if color_activated_save==1 %if save was activated only by the color button
    set(handles.save, 'enable', 'off'); %put if off again
end



%

function mptype=determine_mptype_from_click(handles)

selectiontype = get(handles.fig, 'selectiontype');
ref_mark = get(handles.ref_mark, 'Value');
annual_mark = get(handles.annual_mark, 'Value');
temp_mark = get(handles.temp_mark, 'Value');

if ref_mark & strcmp(get(handles.ref_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 1;
    elseif strcmp(selectiontype, 'extend') %alt click
        mptype = 3;
    elseif strcmp(selectiontype, 'alt')  %right click
        mptype=4;
    end
elseif annual_mark & strcmp(get(handles.annual_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 6;
    elseif strcmp(selectiontype, 'alt')  %rightclick
        mptype=7;
    end
elseif temp_mark & strcmp(get(handles.temp_mark, 'Enable'),'on')
    if strcmp(selectiontype, 'normal') %click
        mptype = 2;
    elseif strcmp(selectiontype, 'alt')  %rightclick
        mptype=5;
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
if get(handles.edit,'Value')==1
    set(handles.radiogroup,'Enable','on');
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
for i = 1:handles.N
    handles = plotmp(handles, i);
end
guidata(hObject, handles);

%--Temp mp callback
function temp_mark_Callback(hObject, handles, keyboardcall)

set(handles.radiogroup, 'Value', 0);
if keyboardcall == 1
    state = get(handles.temp_mark, 'Value');
    if state == 1
        set(handles.temp_mark, 'Value', 0);
    else
        set(handles.temp_mark, 'Value', 1);
    end
end
if keyboardcall == 0
    set(handles.temp_mark, 'Value', 1);
end
for i = 1:handles.N
    handles = plotmp(handles, i);
end
guidata(hObject, handles);

%--Annual layer callback
function annual_mark_Callback(hObject, handles, keyboardcall)
set(handles.radiogroup, 'Value',0);
if keyboardcall == 1
    
    state = get(handles.annual_mark, 'Value');
    if state == 1
        set(handles.annual_mark, 'Value', 0);
    else
        set(handles.annual_mark, 'Value', 1);
    end
end
if keyboardcall == 0
    set(handles.annual_mark, 'Value', 1);
end
for i = 1:handles.N
    handles = plotmp(handles, i);
end
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