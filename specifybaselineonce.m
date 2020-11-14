function [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(abffile,channelidx,dvdtthreshold_on)
    if nargin < 2
        error('Not enough input arguments')
    elseif nargin < 3
        dvdtthreshold_on = 1;
    end
    
    [d,si,h]=abfload(abffile);
    data = d(:,channelidx,1);
%     timems = 1:length(data)*(si/1000);
    f = figure;
    zoomplot(data,(si/1000));
    set(f,'toolbar','figure')
    xlabel('time (ms)')
    ylabel('volts')
    set(gca,'plotboxaspectratio',[1.4 1 1])
    pos = get(gca,'position');
    pos2 = pos;
    pos2(2) = pos2(2)+0.05;
    set(gca,'position',pos2)
    title('First sweep of input file')
    uicontrol('Style', 'pushbutton', 'string','Continue','Position',[400 20 80 20],'Callback', 'uiresume(gcbf)');
    uicontrol('Style','text','Position',[20 20 300 20],'String','Zoom to fit figure. Press continue when finished.')
    uiwait(f);
    title_text = 'Enter Baseline Time Range';
    bl_times = str2double(inputdlg({'Start Baseline (ms):'; 'End Baseline (ms):'},title_text,[1,length(title_text)+25])); % input will be in ms
    if isempty(bl_times)
        close(gcf)
        error('Baseline intervals not specified')
    end
    start = bl_times(1,1)/(si/1000); % will have to convert ms to points by si/1000
    if start < 1
    	start = 1;
	end
    stop = bl_times(2,1)/(si/1000); % will have to convert ms to points by si/1000
    if isnan(start)
        close(gcf)
        error('Invalid input for "start"')
    end
    if isnan(stop)
        close(gcf)
        error('Invalid input for "stop"')
    end    
    
    if dvdtthreshold_on == 1
        dvdtthreshold = str2double(inputdlg('Enter dvdt threshold:','Threshold',1,{'20'}));
    else
        dvdtthreshold = [];
    end
    if isnan(dvdtthreshold)
        close(gcf)
        error('Invalid input for "dvdtthreshold"')
    end
    
    figure(f)
    xminmax = get(gca,'xlim');
    close(gcf)



end