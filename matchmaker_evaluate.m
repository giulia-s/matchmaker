function matchmaker_evaluate(varargin)

% MATCHMAKER_EVALUATE is designed to be called from MATCHMAKER.

switch nargin
    case {0, 1, 2}% Only for development purposes
        disp('MATCHMAKER_EVALUATE needs input arguments, and is designed to be called from MATCHMAKER.');
    case {3, 4, 5, 6, 7, 8, 9}

        eval([char(varargin{1}) '(varargin{[2 4:nargin]})']);
    otherwise
        disp('Wrong number of arguments when calling matchmaker_evaluate.m');
end
warning('off');

%---

function evalopen(matchmakerfighandle, mp, mp_2, core, masterno, current_mp_1, secondary_set_flag)

for i = 1:length(mp)
    mp_thick = mp{i}(ismember(mp{i}(:,2),[1,3,4]),1);
    
    if length(mp_thick)<2
        errordlg('There must be at least two first-order matchpoints for each icecore for the evaluate window to work. Evaluate window will not open.', 'Warning calling MATCHMAKER_EVALUATE', 'modal');
        return
    end
end

handles.fig = figure('units','normalized',...
    'outerposition', [0.1 0.1 0.75 0.75], ...%initial dimensions upon opening
    'name', 'Matchmaker Evaluation Tool',...
    'CloseRequestFcn', 'matchmaker_evaluate(''exit_Callback'', gcbo, [], guidata(gcbo))',...
    'nextplot', 'add', 'color', 0.9*[1 1 1], 'pointer', 'cross',...
    'toolbar', 'figure', 'Numbertitle', 'off',...
    'KeyPressFcn', 'matchmaker_evaluate(''keypressed_Callback'', gcbo, [], guidata(gcbo))',...
    'integerhandle', 'off');
handles.matchmakerfighandle = matchmakerfighandle;
handles.mp = mp;
handles.mp_2=mp_2;
handles.secondary_set_flag=secondary_set_flag;
handles.core = core;
handles.masterno = masterno;
handles.N = length(mp);
handles.current_mp_1 = current_mp_1([1 end]);

dummyax = axes('position', [0 0 1 1], 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off', 'nextplot', 'add', 'hittest', 'off');

font1 = 8;
font2 = 10;
button_height=0.025;

handles.title = text(0.005, 0.012, 'MATCHMAKER Evaluation Tool', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Fontsize', font2, 'fontweight', 'bold', 'parent', dummyax);
handles.text1 = text(0.52, 0.04, 'Comparison match point interval', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Fontsize', font1, 'parent', dummyax);
handles.text1 = text(0.69, 0.04, 'Match point ID', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Fontsize', font1, 'parent', dummyax);
handles.return = uicontrol('units', 'normalized', 'position', [0.81 0.012 0.08 button_height],...
    'string', 'Return',...
    'Tooltip', 'Return to matchmaker',...
    'style', 'pushbutton', 'callback', 'matchmaker_evaluate(''return_Callback'',gcbo, [],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.exit = uicontrol('units', 'normalized', 'position', [0.91 0.012 0.08 button_height],...
    'string', 'Exit',...
    'Tooltip', 'Close',...
    'style', 'pushbutton', 'callback', 'matchmaker_evaluate(''exit_Callback'',gcbo, [],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.lowmp = uicontrol('units', 'normalized', 'position', [0.41 0.012 0.08 button_height],...
    'string', num2str(current_mp_1(1)),...
    'Tooltip', 'Lowest mp to visualize',...
    'style', 'edit', 'callback', 'matchmaker_evaluate(''xlim_Callback'',gcbo, [],guidata(gcbo), -1)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.highmp = uicontrol('units', 'normalized', 'position', [0.55 0.012 0.08 button_height],...
    'string', num2str(current_mp_1(end)),...
    'Tooltip', 'Highest mp to visualize',...
    'style', 'edit', 'callback', 'matchmaker_evaluate(''xlim_Callback'',gcbo, [],guidata(gcbo), 1)', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.inc = uicontrol('units', 'normalized', 'position', [0.50 0.012 0.04 button_height],...
    'string', '1',...
    'Tooltip', 'mp increment when scrolling left and right',...
    'style', 'edit', 'callback', 'matchmaker_evaluate(''inc_Callback'',gcbo, [],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.info = uicontrol('units', 'normalized', 'position', [0.65 0.012 0.08 button_height],...
    'string', [],...
    'Tooltip', 'current mp',...
    'style', 'edit', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center');
handles.diff = uicontrol('units', 'normalized', 'position', [0.31 0.012 0.08 button_height],...
    'Tooltip', 'depth difference or normalized depth difference',...
    'string', 'Depth diff', 'style', 'togglebutton', 'callback', 'matchmaker_evaluate(''diff_Callback'',gcbo, [],guidata(gcbo))', 'fontname', 'default', 'fontsize', font1, 'fontweight', 'bold', 'horizontalalignment', 'center', 'value', 1);

handles.ax(1) = axes('position', [0.05 0.1 0.44 0.84], 'nextplot', 'add', 'box', 'on', 'fontsize', font1);
handles.axtitle(1) = title(['Depth vs. ' handles.core{handles.masterno} ' depth'], 'Fontsize', font1);
handles.ax(2) = axes('position', [0.55 0.1 0.44 0.84], 'nextplot', 'add', 'box', 'on', 'fontsize', font1);
handles.axtitle(2) = title(['(slope / ' handles.core{handles.masterno} ' slope) vs. ' handles.core{handles.masterno} 'depth'], 'Fontsize', font1);
for i=[1,2]
    handles.ax(i).XLabel.String='m';
    handles.ax(i).YLabel.String='arb.units';
end
xlim_Callback(handles.fig, handles, 1);
diff_Callback(handles.fig, handles);

set(handles.fig, 'handlevisibility', 'callback');
guidata(handles.fig, handles);

matchmaker('evaluate_Callback', handles.fig, [], handles, 'opening_evaluate');

%---

function evalreuse(evaluatefigurehandle, mp, mp_2, core, masterno, current_mp_1)
figure(evaluatefigurehandle);
handles = guidata(evaluatefigurehandle);
handles.mp = mp;
handles.mp_2 = mp_2;
handles.core = core;
handles.masterno = masterno;
handles.N = length(mp);
handles.current_mp_1 = current_mp_1([1 end]);

xlim_Callback(handles.fig, handles, 1);
guidata(handles.fig, handles);

%---

function keypressed_Callback(hObject, handles) % Translate keypress to appropriate button actions.
key = double(get(handles.fig, 'currentcharacter'));
if ~isempty(key)
    
    switch key
        case 28   %<-
            set(handles.lowmp, 'string', num2str(str2double(get(handles.lowmp, 'string'))-str2double(get(handles.inc, 'string'))));
            set(handles.highmp, 'string', num2str(str2double(get(handles.highmp, 'string'))-str2double(get(handles.inc, 'string'))));
            xlim_Callback(handles.fig, handles, 1);
            guidata(handles.fig, handles);
        case 29  %->
            set(handles.lowmp, 'string', num2str(str2double(get(handles.lowmp, 'string'))+str2double(get(handles.inc, 'string'))));
            set(handles.highmp, 'string', num2str(str2double(get(handles.highmp, 'string'))+str2double(get(handles.inc, 'string'))));
            xlim_Callback(handles.fig, handles, 1);
            guidata(handles.fig, handles);
        case {114, 82}  %r, R
            figure(handles.matchmakerfighandle)
        case {120, 88}  %x, X
            exit_Callback(hObject, handles);
        otherwise % If key not defined, show info window
            h_help = helpdlg({...
                'Available keyboard commands:';
                '<- = move selected core one frame back and accordianize'
                '-> = move selected core one frame forward and accordianize'
                'R  = Return to Matchmaker main screen'
                'X  = Exit'}); %#ok<NASGU>
    end
end

%---

function return_Callback(~, handles) % Change cursor type from crosshair to fullcrosshair and back
figure(handles.matchmakerfighandle)

%---

function diff_Callback(~, handles) % Change cursor type from crosshair to fullcrosshair and back
% if ~isfield(handles,'mp_2')
%     plotcurves(handles);
% else
    plotcurves(handles);
% end
if get(handles.diff, 'value') == 1
    set(handles.axtitle(1), 'String', ['Normalized depth difference(s) vs. ' handles.core{handles.masterno} ' depth']);
else
    set(handles.axtitle(1), 'String', ['Depth vs. ' handles.core{handles.masterno} ' depth']);
end

%---

function exit_Callback(hObject, handles)
matchmaker('evaluate_Callback',hObject,[], handles, 'closing_evaluate');
figure(handles.matchmakerfighandle)
delete(handles.fig)

%---

function inc_Callback( ~, handles)
value = str2double(get(handles.inc, 'string'));
if ~isreal(value) | length(value) ~= 1  %#ok<*OR2>
    set(handles.inc, 'string', '1');
elseif value < 0
    set(handles.inc, 'string', num2str(abs(value)));
end

%---

function xlim_Callback(~, handles, lowhigh)
lowmp = str2double(get(handles.lowmp, 'string'));
highmp = str2double(get(handles.highmp, 'string'));
oldmplim = handles.current_mp_1;
if mod(lowmp,1)==0 &...
        isreal(lowmp) &...
        length(lowmp) == 1 &...
        mod(highmp,1)==0 &...
        isreal(highmp) &...
        length(highmp)==1 %#ok<*AND2> % check if input is valid
    
    N_thick=zeros(handles.N,1);
    
    for i = 1:handles.N
        mp = handles.mp{i};
        N_thick(i) = length(mp(ismember(mp(:,2),[1,3,4]),1));
        
    end
    Nmp = min(N_thick);
    
    lowmp = max(1, lowmp);
    highmp = min(Nmp, highmp);
    
    %THIS makes it work even if the cores aren't accordianized:
    lowmp = min(Nmp-1, lowmp);
    highmp = max(2, highmp);
    
    if lowmp > highmp
        if lowhigh == -1
            highmp = min(Nmp, lowmp + (diff(oldmplim)-1));
        else
            lowmp = max(1, highmp - (diff(oldmplim)-1));
        end
        lowmp = max(1, lowmp);
        lowmp = min(Nmp-1, lowmp);
        highmp = min(Nmp, highmp);
        highmp = max(2, highmp);
    end
    
    set(handles.highmp, 'string', num2str(highmp));
    set(handles.lowmp, 'string', num2str(lowmp));
    
    handles.current_mp_1 = [lowmp highmp];
    
    guidata(handles.fig, handles);
    
    mp = handles.mp{handles.masterno};
    mp_thick = mp(ismember(mp(:,2),[1,3,4]),1);
    xlim = [mp_thick(lowmp)-0.1 mp_thick(highmp)+0.1];
    set(handles.ax, 'xlim', xlim);
    plotcurves(handles);
else
    set(handles.lowmp, 'string', handles.current_mp_1(1));
    set(handles.highmp, 'string', handles.current_mp_1(2));
end

%---

function plotcurves(handles)

lowmp = str2double(get(handles.lowmp, 'string'));
highmp = str2double(get(handles.highmp, 'string'));
idx_display = lowmp : highmp;

cla(handles.ax(1));
cla(handles.ax(2));
h_lgd = legend(handles.ax(1));
set(h_lgd, 'box', 'off');

colours = jet(handles.N);

mp_master = handles.mp{handles.masterno};
mp_master_thick = mp_master(ismember(mp_master(:,2),[1,3,4]),:);
% 
if isfield(handles,'mp_2')
    mp_master_2 = handles.mp_2{handles.masterno};
    if sum(mp_master_2)==0
        secondary_set_flag=0;
    else
        mp_master_thick_2 = mp_master_2(ismember(mp_master_2(:,2),[1,3,4]),:);

        % identify mp_2 within x_min and x_max
        temp_idx_2=find(mp_master_thick_2(:,1)>=handles.matchmakerfighandle.CurrentAxes.XLim(1)...
        & mp_master_thick_2(:,1)<=handles.matchmakerfighandle.CurrentAxes.XLim(2));
        secondary_set_flag=1;
    end
else
    secondary_set_flag=0;
end
% 
if secondary_set_flag % if mp_2 is a field
    if ~isempty(temp_idx_2) & length(temp_idx_2)>1 % if mp_2 is a field, there is enough mp_2, and it's more than one mp
        lowmp_2=temp_idx_2(1);
        highmp_2=temp_idx_2(end);
        idx2 = lowmp_2:highmp_2;
        secondary_set_flag=1;
    else
        secondary_set_flag=0; %don't evaluate mp_2
    end
end
% 
if length(idx_display) < 2
    return
end
% 
deltadepth=cell(length(setdiff(1:handles.N, handles.masterno)),1);
deltadepth_2=cell(length(setdiff(1:handles.N, handles.masterno)),1);

k_lgd=0;
if secondary_set_flag
    n_lgd=3;
else
    n_lgd=2;
end

for i = setdiff(1:handles.N, handles.masterno) % all cores, excluding master_no
    k_lgd=k_lgd+1;
    
    mp = handles.mp{i};
    mp_2 = handles.mp_2{i};
    if length(mp(:,1))>=2
        mp_thick = mp(ismember(mp(:,2),[1,3,4]),:);      
% 
        idx_evaluate=1:idx_display(end);
%         
%         %only types 1 and 3 are used for evaluation
        logical_array_master=ismember(mp_master_thick(idx_evaluate,2),[1,3]);
        logical_array=ismember(mp_thick(idx_evaluate,2),[1,3]);
%         
        idx_sure = intersect( idx_evaluate(logical_array_master & logical_array), idx_display);
% 
%         
        if secondary_set_flag
            mp_thick_2 = mp_2(ismember(mp_2(:,2),[1,3,4]),:);
            i2=min(length(mp_thick_2),highmp_2);
            
            idx_evaluate=1:i2;
            logical_array_master=ismember(mp_master_thick_2(idx_evaluate,2),[1,3]);
            logical_array=ismember(mp_thick_2(idx_evaluate,2),[1,3]);
            idx_sure_2 = intersect( idx_evaluate(logical_array_master & logical_array), idx2);
% 
        end
%         
        if length(idx_sure) == 1
            disp('Not enough first order matchpoints on screen (blue type 4 matchpoints do not count)');
        else %calculating the steps for the right-side plot
% 
            if length(idx_sure) == 2
                deltadepth{i} = [mp_master_thick(idx_sure(1), 1), diff(mp_thick(idx_sure, 1));...
                                 mp_thick(idx_sure(2), 1), diff(mp_thick(idx_sure, 1))];
% 
            else
                deltadepth{i} = stepit([mp_master_thick(idx_sure(2:end), 1), diff(mp_thick(idx_sure, 1))./diff(mp_master_thick(idx_sure, 1))]);
                deltadepth{i}(1,1) = mp_master_thick(idx_sure(1), 1);
            end
%             
            if secondary_set_flag
                if length(idx_sure_2) == 2
                    deltadepth_2{i} = [mp_master_thick_2(idx_sure_2(1), 1), diff(mp_thick_2(idx_sure_2, 1));...
                                        mp_thick_2(idx_sure_2(2), 1), diff(mp_thick_2(idx_sure_2, 1))];
                else
                    deltadepth_2{i} = stepit([mp_master_thick_2(idx_sure_2(2:end), 1), diff(mp_thick_2(idx_sure_2, 1))./diff(mp_master_thick_2(idx_sure_2, 1))]);
                    deltadepth_2{i}(1,1) = mp_master_thick_2(idx_sure_2(1), 1);
                end
            end
%             
%             %right-side plot
% 
            plot(deltadepth{i}(:,1), deltadepth{i}(:,2), 'DisplayName',handles.core{i},...
                'color', colours(i,:), 'linewidth', 2, 'parent', handles.ax(2));
            if secondary_set_flag %right plot
%                 plot(deltadepth_2{i}(:,1), deltadepth_2{i}(:,2),'-.' ,'DisplayName',[handles.core{i} ' others'],...
%                     'color', colours(i,:), 'linewidth', 1, 'parent', handles.ax(2));
            end
%             
%             %left-side plot
            plotdiff = get(handles.diff, 'Value'); %if button "depth diff" is toggled
            if plotdiff
                handles.ax(1).YLabel.String = 'arb.units';
            else
                handles.ax(1).YLabel.String ='m';
            end
%             
            offset = mean(mp_thick(idx_display, 1) - mp_master_thick(idx_display, 1));% 
%             

            
            l1=plot(mp_master_thick(idx_sure, 1), mp_thick(idx_sure, 1)-plotdiff*(mp_master_thick(idx_sure, 1)+offset),'-',...
                'DisplayName',handles.core{i},...
                'marker','o','MarkerFaceColor',colours(i,:), 'color', colours(i,:), 'Linewidth', 2, 'parent', handles.ax(1));
            l2=plot(mp_master_thick(idx_display, 1), mp_thick(idx_display, 1)-plotdiff*(mp_master_thick(idx_display, 1)+offset),'o:', 'color', colours(i,:),...
                'DisplayName', [handles.core{i} ' (blue mps)'],...
                'handlevisibility','on','parent', handles.ax(1));

            for j=1:length(idx_display)
                p=scatter(mp_master_thick(idx_display(j), 1), mp_thick(idx_display(j), 1)-plotdiff*(mp_master_thick(idx_display(j), 1)+offset),...%problem:handlevisibility makes is also invisible to cla!
                 'handlevisibility','on',...
                 'marker','o','MarkerFaceColor','none', 'MarkerEdgeColor', colours(i,:),  'parent', handles.ax(1),...
                 'ButtonDownFcn', 'matchmaker_evaluate(''mpclick_Callback'',gcbo,[],guidata(gcbo))','Tag', num2str(idx_display(j)));
            end
            %set legend items
            h_lgd.String{n_lgd*k_lgd - (n_lgd-1)  }=handles.core{i};
            h_lgd.String{n_lgd*k_lgd - (n_lgd-2)  }=[handles.core{i} ' (blue mps)'];
            h_lgd.String(n_lgd*k_lgd - (n_lgd-2) +1 : end)=[];
            
            if secondary_set_flag %left plot
                offset_2 = mean(mp_thick_2(idx2, 1) - mp_master_thick_2(idx2, 1));
%                 plot(mp_master_thick_2(i2, 1), mp_thick_2(i2, 1)-plotdiff*(mp_master_thick_2(i2, 1)+offset_2),...
%                  'DisplayName', [handles.core{i} ' (blue mps)'],...
%                     'marker','o','MarkerFaceColor','none', 'color', colours(i,:), 'Linewidth', 1, 'parent', handles.ax(1), 'hittest', 'on');
                plot(mp_master_thick_2(idx_sure_2, 1), mp_thick_2(idx_sure_2, 1)-plotdiff*(mp_master_thick_2(idx_sure_2, 1)+offset_2),'-.',...
                    'DisplayName',[handles.core{i} ' secondary set'],...
                    'marker','o','MarkerFaceColor',colours(i,:),'color', colours(i,:), 'markersize',3,'Linewidth', 1, 'parent', handles.ax(1), 'hittest', 'on');
                h_lgd.String{n_lgd*k_lgd - (n_lgd-3)}=[handles.core{i} ' secondary set'];
            end   
        end
    end
end

h_lgd = legend(handles.ax(2));
set(h_lgd, 'box', 'off');


set(p,'HandleVisibility','on'); %otherwise cla won't clear this curve




function mpclick_Callback(hObject, handles)
id = get(hObject, 'tag');
set(handles.info, 'string', id);

mpmaster = handles.mp{handles.masterno};
mp_master_thick = mpmaster(ismember(mpmaster(:,2),[1,3,4]),1);
mp_master_thin = mpmaster(ismember(mpmaster(:,2),[2,5]), 1);
pos = str2double(id);
if isfield(handles, 'indicatorline')
    if ishandle(handles.indicatorline)
        delete(handles.indicatorline);
    end
end
if ismember(pos, mp_master_thin)
    handles.indicatorline = plot([pos pos], get(handles.ax(2), 'ylim')+[1e-3 -1e-3], ':k','DisplayName',['Match point ID=', num2str(id)], 'parent', handles.ax(2));
else
    pos = mp_master_thick(pos);
    handles.indicatorline = plot([pos pos], get(handles.ax(2), 'ylim')+[1e-3 -1e-3], ':k','DisplayName',['Match point ID=', num2str(id)],'parent', handles.ax(2));
end
guidata(handles.fig, handles);