%     Results.threshold_time = threshold_time;
%     Results.threshold_amplitude = threshold_amplitude;
%     Results.threshold_index = threshold_index;

function [threshold_time,threshold_amplitude,threshold_index,dvdtthreshold,dvdt1v2,dvdt2,dvdt1loc,dvdt1pks] = SpikeThreshold(data,dvdtthreshold,si,numspikes,xminmax,sweep,graph_on,stop,pklocations)

    if nargin ~= 9
        error('Not enough input arguments');
    end
    dvdt1 = diff(data)/(si/1000); % first derivative
    dvdt1v2 = smooth(dvdt1,5); % smooths the first derivative by 5 points - all following code is done on smoothed data
    dvdt2 = (diff(diff(data))/(si/1000)^2); % second derivative
    findpeakofdvdtthresh = dvdtthreshold;
    [dvdt1pks, dvdt1loc] = findpeaks(dvdt1v2,'minpeakheight',findpeakofdvdtthresh,'minpeakdistance',1/(si/1000));

    % ok so the peaks of the dvdt1 trace right now has 2 per spike... we want to use the first one, the shorter one. how do i get that?
    % counter = 0
    keepit = [];
    remove = [];
    for i = 1:length(dvdt1loc)-1
        ref =  dvdt1loc(1+length(dvdt1loc)-i);
        test = dvdt1loc(1+length(dvdt1loc)-i-1);
        if ref-test > (2/(si/1000)) % if ISIpoints is larger than however many points within 1.2ms
            keepit = [keepit; i];
        else
            keepit = [keepit; i];
            remove = [remove; i+1];
        end
    end
    keepit = [keepit; length(dvdt1loc)];
    keepit(ismember(keepit,remove))=[];
    dvdt1loc = flipud(dvdt1loc);
    dvdt1loc = dvdt1loc(keepit);
    dvdt1loc = flipud(dvdt1loc);
    dvdt1pks = dvdt1v2(dvdt1loc);  
    
    %% Remove dvdtpeaks that are occuring within 1ms past the baseline stop interval
    withinblremove = find(dvdt1loc <= (stop+1/(si/1000))); % default = 1
    dvdt1loc(withinblremove) = [];
    dvdt1pks(withinblremove) = [];
    %% check to see if 1st spike is occuring after 1st dvdt 
    % might be an issue after removal of dvdtpeak occuring within 1ms past baseline stop interval
    % sometimes the dvdtspike is removed but the actual spike is still there which will offset everything
    if ((pklocations(1) - dvdt1loc(1))*(si/1000)) < 0 % should be positive b/c dvdt occurs before pklocation. if negative, then first spike is missing dvdt
        figure, plot(1:length(data),data,'b',pklocations,data(pklocations),'r*'); title(sprintf('Trace Sweep: %g',sweep));
        hold on, plot(1:length(dvdt1v2),dvdt1v2,'k',dvdt1loc,dvdt1pks,'m*'); title(sprintf('First Derivative Sweep: %g',sweep));
        if abs((pklocations(1) - dvdt1loc(1))*(si/1000)) > 5 % spike should occur within a few ms of the dvdt spike, maybe 1~2ms tops
            error('First spike is missing a dvdt peak for sweep %g. Firt dvdt peak is occuring more than 5ms after the first spike. Inspect trace and dvdt. Might need to change the window for removing spikes occuring in baseline interval',sweep)
        end
        error('First spike is missing a dvdt peak for sweep %g. Inspect trace and dvdt. Might need to change the window for removing spikes occuring in baseline interval',sweep)
    end
    %% see if some dvdt peaks are below threshold
    if length(pklocations) == length(dvdt1loc)
        difference = (pklocations - dvdt1loc)*(si/1000); % should all be positive b/c dvdt occurs before pklocation.
        belowzero = difference(difference < 0);
        belowzerospikes = 1:length(pklocations);
        belowzerospikes(difference>0) = [];
        if ~isempty(belowzero)
            error('Some dvdt peaks are occuring after spike. Some dvdts likely not found. Check dvdt threshold for spike(s) # %s',num2str(belowzerospikes))
        end
    end
    
    %%
    if graph_on == 1
        ff = figure;
        plot(1:length(dvdt1v2),dvdt1v2,'b',dvdt1loc,dvdt1pks,'r*');
        xlim([xminmax])
        title('First Derivative')
        xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
        hold on
        plotthreshold = zeros(1,length(dvdt1v2));
        plotthreshold(:) = dvdtthreshold;
        plot(plotthreshold)
        title(sprintf('Sweep %g',sweep))
    end
% find when dvdt crosses threshold
    for i = 1:length(dvdt1pks)
        counter = 1;
        backdvdt = [];
        while isempty(backdvdt)
            if dvdt1v2(dvdt1loc(i)-counter) <= dvdtthreshold
                backdvdt = dvdt1loc(i)-counter;
            end
            counter = counter + 1;
            if i == 1
                if counter == length(dvdt1v2(1:dvdt1loc(i)))
                    break
                end
            else
                if counter == length(dvdt1v2(dvdt1loc(i-1):dvdt1loc(i)))
                    break
                end
            end
        end
        if ~isempty(backdvdt)
            timepointstouse(i) = backdvdt;
        else
            timepointstouse(i) = NaN;
        end
    end

    if length(timepointstouse) < numspikes
        figure, plot(1:length(data),data,'b',pklocations,data(pklocations),'r*'); title(sprintf('Trace Sweep: %g',sweep));
        hold on, plot(1:length(dvdt1v2),dvdt1v2,'k',dvdt1loc,dvdt1pks,'m*'); title(sprintf('First Derivative Sweep: %g',sweep));
        error('Number spikes (%g) exceeds number of dvdt1 peaks (%g) for sweep %g. Inspect trace and dvdt. Co uld be due to bad dvdt threshold or bad minimumISI',numspikes,length(timepointstouse),sweep)
    elseif length(timepointstouse) > numspikes
%         figure, plot(1:length(data),data,'b',pklocations,data(pklocations),'r*'); title(sprintf('Trace Sweep: %g',sweep));
%         figure, plot(1:length(dvdt1v2),dvdt1v2,'b',dvdt1loc,dvdt1pks,'r*'); title(sprintf('First Derivative Sweep: %g',sweep));
        warning('Number dvdt1 peaks (%g) exceeds number of spikes (%g) for sweep %g. Bad dvdt removed', length(timepointstouse),numspikes,sweep)
        [timepointstouse, dvdt1loc] = removebaddvdt(pklocations, timepointstouse, dvdt1loc);
        dvdt1pks = dvdt1v2(dvdt1loc);
    end
    timepointstouse = timepointstouse(1:numspikes);
%% check to make sure dvdtpks do not violate spike pks
    for i = 1:length(pklocations) % peaks should happen after dvdt peaks
        difference = pklocations(i) - timepointstouse(i);
        if difference < 0 && abs(difference) >= 5/(si/1000) % if dvdtpk is happening after spike and 5ms after, then set to NaN
            timepointstouse(i) = NaN;
            threshold_amplitude(i,1) = NaN;
        else
            threshold_amplitude(i,1) = data(timepointstouse(i));
        end
    end

%%  
    
    threshold_time = timepointstouse*(si/1000);
    threshold_index = timepointstouse;


end
