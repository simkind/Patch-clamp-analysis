function [Results] = AccommodationAnalysis(d,si,h)
    %% Get baseline interval 
    % baseline interval will be common for all sweeps
    numsweeps = size(d,3); % number of sweeps
    title_text = 'Enter Baseline Time Range';
	bl_times = str2double(inputdlg({'Start Baseline (ms):'; 'End Baseline (ms):'},title_text,[1,length(title_text)+25])); % input will be in ms
    start = bl_times(1,1)/(si/1000); % will have to convert ms to points by si/1000
    if start < 1
    	start = 1;
    end
	stop = bl_times(2,1)/(si/1000); % will have to convert ms to points by si/1000
	dvdtthreshold = str2double(inputdlg('Enter dvdt threshold:','Threshold',1,{'20'}));
    xminmax = get(gca,'xlim');
    close(gcf)
    
    %% For each sweep
    for sweep = 1:numsweeps
        data = [];
        data = d(:,2,sweep);
        sweepdata(sweep).data = data;
        timemes = 1:length(data)*(si/1000);
        %% Get baseline data
        [Results(sweep).baseline_potential, Results(sweep).baseline_potentialstd] = baseline(data,start,stop);
        Results(sweep).baseline_timerange = bl_times; 
        meantracebl(sweep,1) = Results(sweep).baseline_potential;
        %% Find peak relative to holding potential
        thresh = -10;
        [pks, loc] = findpeaks(data,'minpeakheight',thresh);
        peak_times = loc*(si/1000);
        peak_amps = pks-Results(sweep).baseline_potential; 
        numspikes = length(peak_times);
        Results(sweep).num_spikes = numspikes;
        Results(sweep).peak_times = peak_times;
        Results(sweep).peak_idx = loc;
        Results(sweep).peak_amplitudes = pks;
        Results(sweep).peak_to_baseline = peak_amps;
        %% ISI
        if length(loc) > 1
            isitemp = diff(loc)*(si/1000); 
            for i = 1:length(isitemp)
                Results(sweep).ISI(i,1) = 1000/isitemp(i);% ISI in hertz
            end
        else
            Results(sweep).ISI = [];
        end
        %% Find FAST AHP after each spike
        wind = 10/(si/1000); % look into 10ms past peak points
        FastAHP = [];
        for i = 1:numspikes
            pklocation = loc(i);
            [FastAHP(i,1) FastAHP(i,2)] = min(data(pklocation:pklocation+wind));
            FastAHP(i,2) = FastAHP(i,2) + pklocation;
        end
        Results(sweep).FastAHP_Voltage = FastAHP(:,1);
        Results(sweep).FastAHP_Time = FastAHP(:,2)*(si/1000);
        %% Threshold
        [Results(sweep).threshold_time, Results(sweep).threshold_amplitude,Results(sweep).threshold_index,...
            Results(sweep).dvdtthreshold,Results(sweep).dvdt1,Results(sweep).dvdt2] = ...
            SpikeThreshold(data,dvdtthreshold,si,numspikes,xminmax,sweep);
        % plot the results with the fast AHP and peaks as well
        fff = figure;
        plot(1:length(data),data,'b',loc,pks,'r*');
        hold on
        plot(1:length(data),data,'b',Results(sweep).threshold_index,Results(sweep).threshold_amplitude,'m*')
        xlim([xminmax])
        plot(FastAHP(:,2),FastAHP(:,1),'g.')
        xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
        ylabel('Volts')
        movegui('northwest')
        title(sprintf('Sweep %g',sweep))
        %% Spikewidth from Baseline
        for i = 1:numspikes
            threshold = (peak_amps(i)/2) + Results(sweep).baseline_potential;
            pklocation = loc(i);
            [Results(sweep).SpikeWidth_Baseline(i,1), ~, ~] = halfwidth(threshold,pklocation,data,si);
        end     
        %% Spikewidth from Threshold
        for i = 1:numspikes
            threshold = ((peaks(i) - Results(sweep).threshold_amplitude(i))/2) + Results(sweep).threshold_amplitude(i);
            pklocation = loc(i); % need to go back to points 
            [Results(sweep).SpikeWidth_Threshhold(i,1), ~,~] = halfwidth(threshold, pklocation,data,si);
        end    
        %% Spikewidth from First Spikewidth-Baseline 
        firstthreshold = (peak_amps(1)/2) + Results(sweep).baseline_potential;
        for i = 1:numspikes
            pklocation = loc(i); % need to go back to points 
            [Results(sweep).SpikeWidth_FirstSpike(i,1), ~,~] = halfwidth(firstthreshold, pklocation,data,si);
        end    

    end
    
    %% Get Accommodation Results and export as excel
    
    
end
    
