function matchmaker_savefig(varargin)
% matchmaker_savefig is designed to be called from MATCHMAKER.
% matchmaker_savefig version 2.05, 30 September 2020,   Giulia Sinnl NEW FEATURES: as described in matchmaker
switch nargin
    case {0, 1}% Only for development purposes
        disp('matchmaker_savefig needs input arguments, and is designed to be called from MATCHMAKER.');
    case {2, 3, 4, 5, 6, 7,8,9}
        %        try
        eval([char(varargin{1}) '(varargin{[2 4:nargin]})']);
        %        catch
        %            disp(lasterr)
        %            dummy = input('ERROR : Log the error and press enter to continue');
        %            disp(' ');
        %        end;
    otherwise
        disp('Wrong number of arguments when calling matchmaker_evaluate.m');
end

function open_save_fig(handles)
fig_new=figure('Visible','off');

fac=1;
N = length(handles.core);

dx = 1;
y0 = 0.03;
dy = 0.015/fac;
yh = (1-y0-(N+2)*dy)/N;

% save('handles','handles');
for i=1:length(handles.core)
    
    core_name=handles.core{i};
    dummyax = axes('position', [0 0 1 1], 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off', 'hittest', 'off');
    text(0.05,0.05+(1-0.1)/N*i,core_name,'parent',dummyax,'fontweight','normal','fontsize',9,'interpreter','none');
    
    ax_new=copyobj(handles.bigax(1,i),fig_new);
    set(ax_new,...
        'Units','normalized',...
        'Xgrid','off',...
        'ygrid','off',...
        'xminorgrid','off',...
        'yminorgrid','off',...
        'box','off',...
        'FontUnits','points',...
        'fontsize',9,...
        'FontName','Helvetica');
    ax_new=copyobj(handles.bigax2(1,i),fig_new);
    set(ax_new,...
        'Units','normalized',...
        'Xgrid','off',...
        'ygrid','off',...
        'xminorgrid','off',...
        'yminorgrid','off',...
        'box','off',...
        'FontUnits','points',...
        'FontWeight','normal',...
        'fontsize',9,...
        'FontName','Helvetica');
    size(handles.tickax)
    for j=1:length(handles.species{i}(handles.selectedspecs{i}))
        
        ax_new=copyobj(handles.tickax{i,j},fig_new);
        set(ax_new,...
            'Units','normalized',...
            'Xgrid','off',...
            'ygrid','off',...
            'xminorgrid','off',...
            'yminorgrid','off',...
            ...%'box','off',...
            'FontUnits','points',...
            'FontWeight','normal',...
            'fontsize',9,...
            'FontName','Helvetica');
        ax_new.XAxis.Exponent=0;
        
        ylabel_str=setYlabel(handles.species{i}(handles.selectedspecs{i}(j)));
        
        ax_new.YLabel.String=[ylabel_str];
        if j==1
            % ax_new.Title.String=[core_name];
            ax_new.XLabel.String=[core_name ' depth [m]'];
            ax_new.XLabel.Interpreter='none';
            Xlb=min(ax_new.XAxis.Limits)-2/20*(ax_new.XAxis.Limits(2)-ax_new.XAxis.Limits(1));
            Ylb=min(ax_new.YAxis.Limits);%-1/20*(ax_new.YAxis.Limits(2)-ax_new.YAxis.Limits(1));
            ax_new.XLabel.Position=[Xlb Ylb];
            % ax_new.XLabel.HorizontalAlignment='right';
        end
        
        
        ax_new=copyobj(handles.plotax{i,j},fig_new);
     
    end
end

set(fig_new,'Units','normalized',...
    'Position',[0        0.0333333333333333                         1                    0.89],...
    'PaperPositionMode','auto');
save_title_Callback(fig_new)




function save_title_Callback(fig)
set(fig, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');

disp(['MATCHMAKER SAVE FIGURE             ' ]);
disp(' ');
% disp(['Figure will be saved in .fig .bpm .eps             ' ]);
% disp(' ');
disp(['Figure TITLE will be in the format STRING_date' ]);
disp(' ');
title_str = input('>>> Insert title [with quotation marks!!]:');
disp(' ');
title_str=[title_str '_' date ];

% NB: Uncomment this line if you want the timestamp on the figure name:
% title_str=[title_str '_' datestr(datetime('now'),'dd_mm_yy-HH_MM')];

savefig(fig,[title_str '.fig']);
% print(fig,[title_str '.eps'],'-depsc2');
% print(fig,[title_str '.bmp'],'-dbmp');
% set(fig,'Units','Inches');
% pos = get(fig,'Position');
% set(fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
% print(fig,[title_str '.pdf'],'-dpdf','-r0');

function ylabel_str=setYlabel(species)
if contains(species,'ECM','IgnoreCase',true)
    ylabel_str={'ECM','μeq/kg'};
elseif contains(species,'DEP','IgnoreCase',true)
    ylabel_str={'DEP',''};
    
elseif contains(species,'18','IgnoreCase',true)
    ylabel_str={'δ^{18}O','‰'};
    
elseif contains(species,'dD','IgnoreCase',true)
    ylabel_str={'dD','‰'};
elseif contains(species,'Pseudo','IgnoreCase',true)
    ylabel_str={'ECM','a.u.'};
    
else
    ylabel_str={species{1}, 'ppb'};
    
end