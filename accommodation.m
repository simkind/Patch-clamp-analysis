% 
function [Results] = accommodation(abffile,graph_on,start,stop,dvdtthreshold,xminmax,channelidx,currentidx)

    if nargin ~= 8
        error('Not enough input arguments')
    end
    [~,filename,~] = fileparts(abffile);    
    % abffile = '12d06012.abf'
    [d,si,h]=abfload(abffile);
    
    numsweeps = size(d,3); % number of sweeps
%%    
    for sweep = 1:numsweeps
            Results(sweep).filename = abffile;
            data = [];
            data = d(:,channelidx,sweep);
            timemes = 1:length(data)*(si/1000);
            Results(sweep).data = data;
            Results(sweep).SI = si;
            Results(sweep).currentstimulus = d(:,currentidx,sweep);
            %Results(sweep).currentstimulus = d(:,2,sweep);
            %% Get baseline data
            [Results(sweep).baseline_potential, Results(sweep).baseline_potentialstd] = baseline(data,start,stop);
            Results(sweep).baseline_timerange = [start*(si/1000); stop*(si/1000)]; % need to convert to time. 
            meantracebl(sweep,1) = Results(sweep).baseline_potential;
            Results(sweep).current = mean(d(start:stop,currentidx,sweep));
            %% Find peak relative to holding potential
            thresh = 10;
            [pks, loc] = findpeaks(data,'minpeakheight',thresh,'minpeakdistance',5/(si/1000)); %changed 3 to 5 10/16/18
            %% Check to make sure peaks aren't occuring within 1ms of each other
            IPI = diff(loc);%
            violates = [];
            violates = find(IPI < (1000/si));
            if ~isempty(violates)
                violates(:,2) = violates + 5; %changed 3 to 5 8/2/18dsi
                for i = 1:size(violates,1)
                    if pks(violates(i,1)) > pks(violates(i,2))
                        violates(i,1) = 0;
                    elseif pks(violates(i,1)) < pks(violates(i,2))
                        violates(i,2) = 0;
                    elseif pks(violates(i,1)) == pks(violates(i,2))
                        violates(i,2) = 0;
                    end
                end
                violates = violates(:,1) + violates(:,2);
                pks(violates) = [];
                loc(violates) = [];
            end
            %% Check if spikes occuring during baseline
            withinbl = ismember(loc,start:stop+1/(si/1000));
            if ismember(1,withinbl) % if there are spikes within baseline interval
                % calculate new baseline without spikes within it
                [Results(sweep).baseline_potential, Results(sweep).baseline_potentialstd, pointstouse]...
                    = nospikebaseline(data,si,start,stop+1/(si/1000),loc,withinbl);
                meantracebl(sweep,1) = Results(sweep).baseline_potential;
                Results(sweep).current = mean(d(pointstouse,currentidx,sweep));
                % removes peaks that are occuring within bl interval
                pks(withinbl) = [];
                loc(withinbl) = []; 
            end
            %%
            if ~isempty(pks)
                peak_times = loc*(si/1000);
                peak_amps = pks-Results(sweep).baseline_potential; 
                numspikes = length(peak_times);
                Results(sweep).num_spikes = numspikes;
                Results(sweep).peak_times = peak_times;
                Results(sweep).peak_idx = loc;
                Results(sweep).peak_amplitudes = pks;
                Results(sweep).peak_to_baseline = peak_amps;

                wind = 30/(si/1000); % look into 10ms past peak points. If spikes are wide increase wind. Dina changed wind from 10 to 30 (7/16/18 ish) to 20 9/4/18
                FastAHP = [];
                for i = 1:numspikes
                    pklocation = loc(i);
                    if length(data) < (pklocation+wind)
                        stoppage = length(data);
                    else
                        stoppage = pklocation+wind;
                    end
                   [FastAHP(i,1) FastAHP(i,2)] = min(data(pklocation:stoppage));
                   FastAHP(i,2) = FastAHP(i,2) + pklocation;
                end
                Results(sweep).FastAHP_Voltage = FastAHP(:,1);
                Results(sweep).FastAHP_Time = FastAHP(:,2)*(si/1000);
                Results(sweep).FastAHP_Baseline = FastAHP(:,1) - Results(sweep).baseline_potential;
                %% Threshold
                [Results(sweep).threshold_time, Results(sweep).threshold_amplitude,Results(sweep).threshold_index,...
                    Results(sweep).dvdtthreshold,Results(sweep).dvdt1,Results(sweep).dvdt2, Results(sweep).dvdt1loc, Results(sweep).dvdt1pks] = ...
                    SpikeThreshold(data,dvdtthreshold,si,numspikes,xminmax,sweep,0,stop,loc);
                % plot the results with the fast AHP and peaks as well
                Results(sweep).threshold_baseline = Results(sweep).threshold_amplitude - Results(sweep).baseline_potential;
                
                %%%%%%%%%%%%%%%%%%%%add FastAHP here %%%%%%%%%%%%%%%%%%
%                [FastAHP] = FastAHPfinder(data,si,Results(sweep).dvdt1loc,dvdtthreshold);
% %                 [FastAHP] = FastAHPfinder_Ann(data,si,Results(sweep).dvdt1loc,dvdtthreshold);
% %                  Results(sweep).FastAHP_Voltage = FastAHP(:,1);
% %                  Results(sweep).FastAHP_Time = FastAHP(:,2)*(si/1000);
% %                  Results(sweep).FastAHP_Baseline = FastAHP(:,1) - Results(sweep).baseline_potential;
                
                if graph_on == 1
                    fff = figure;
                    plot(1:length(data),data,'b',loc,pks,'r*')
                    hold on
                    plot(1:length(data),data,'b',Results(sweep).threshold_index,Results(sweep).threshold_amplitude,'m*')
                    xlim([xminmax])
                    plot(FastAHP(:,2),FastAHP(:,1),'g.')
                    xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
                    ylabel('Volts')
%                     movegui('northwest')
                    title(sprintf('Sweep %g File:%s',sweep,filename))
                end
                %% Spikewidth from Baseline
                for i = 1:numspikes
                    threshold = (peak_amps(i)/2) + Results(sweep).baseline_potential;
                    pklocation = loc(i);
                    [Results(sweep).SpikeWidth_Baseline(i,1), ~, ~] = halfwidth(threshold,pklocation,data,si);
                end     
                %% Spikewidth from Threshold
                for i = 1:numspikes
                    pklocation = loc(i); % need to go back to points 
                    if ~isnan(Results(sweep).threshold_amplitude(i))
                        threshold = ((pks(i) - Results(sweep).threshold_amplitude(i))/2) + Results(sweep).threshold_amplitude(i);
                        [Results(sweep).SpikeWidth_Threshold(i,1), ~,~] = halfwidth(threshold, pklocation,data,si);
                    else
                        Results(sweep).SpikeWidth_Threshold(i,1) = NaN;
                    end
                end    
                %% Spikewidth from First Spikewidth-Baseline 
                firstthreshold = (peak_amps(1)/2) + Results(sweep).baseline_potential;
                for i = 1:numspikes
                    pklocation = loc(i); % need to go back to points 
                    [Results(sweep).SpikeWidth_FirstSpike(i,1), ~,~] = halfwidth(firstthreshold, pklocation,data,si);
                end    
                
                %% Calculate ISI
                if numspikes > 1
                    Results(sweep).ISI = diff(peak_times) ;
                else
                    Results(sweep).ISI = NaN;
                end

 %%
            else
                Results(sweep).num_spikes = NaN;
                Results(sweep).peak_times = NaN;
                Results(sweep).peak_idx = NaN;
                Results(sweep).peak_amplitudes = NaN;
                Results(sweep).peak_to_baseline = NaN;
                Results(sweep).FastAHP_Voltage = NaN;
                Results(sweep).FastAHP_Time = NaN;
                Results(sweep).FastAHP_Baseline = NaN;
                Results(sweep).threshold_time = NaN;
                Results(sweep).threshold_amplitude = NaN;
                Results(sweep).threshold_index = NaN;
                Results(sweep).threshold_baseline = NaN;
                Results(sweep).dvdtthreshold = NaN;
                Results(sweep).dvdt1 = NaN;
                Results(sweep).dvdt2= NaN;
                Results(sweep).SpikeWidth_Baseline = NaN;
                Results(sweep).SpikeWidth_Threshold = NaN;
                Results(sweep).SpikeWidth_FirstSpike = NaN;
                Results(sweep).ISI = NaN;

            end
    end
end