
% abffile = '12d06012.abf'
function [Results] = APanalysis(abffile,graph_on,start,stop,dvdtthreshold,xminmax,channelidx,currentidx)
    
    if nargin ~= 8
        error('Not enough input arguments')
    end
    [~,filename,~] = fileparts(abffile);
    [d,si,h]=abfload(abffile); 
    numsweeps = size(d,3); % number of sweeps
    %% For each sweep
%     meansweepdata = zeros(numsweeps,size(d,1));
    for sweep = 1:numsweeps
        Results(sweep).filename = abffile;
        data = [];
        data = d(:,channelidx,sweep);
        timemes = 1:length(data)*(si/1000);
        Results(sweep).data = data;
        Results(sweep).SI = si;
        Results(sweep).currentstimulus = d(:,currentidx,sweep);
        %% Get baseline data
        [Results(sweep).baseline_potential, Results(sweep).baseline_potentialstd] = baseline(data,start,stop);
        Results(sweep).baseline_timerange = [start*(si/1000); stop*(si/1000)]; % need to convert to time. 
        meantracebl(sweep,1) = Results(sweep).baseline_potential;
        Results(sweep).current = mean(d(start:stop,currentidx,sweep));
        %% Find peak relative to holding potential
        thresh = -10;
        [pks, loc] = findpeaks(data,'minpeakheight',thresh,'minpeakdistance',1/(si/1000));
        %% CHeck to make sure peaks aren't occuring within 1ms of each other
        IPI = diff(loc);%
        violates = [];
        violates = find(IPI < (1000/si));
        if ~isempty(violates)
            violates(:,2) = violates + 1;
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
            if length(unique(withinbl)) > 1 % if there are spikes within baseline interval
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
        if ~isempty(pks) % if there are spikes
            peak_times = loc*(si/1000);
            peak_amps = pks-Results(sweep).baseline_potential; 
            numspikes = length(peak_times);
            Results(sweep).num_spikes = numspikes;
            Results(sweep).peak_times = peak_times;
            Results(sweep).peak_idx = loc;
            Results(sweep).peak_amplitudes = pks;
            Results(sweep).peak_to_baseline = peak_amps;
            
% % % % % % %             wind = 10/(si/1000); % look into 10ms past peak points
% % % % % % %             FastAHP = [];
% % % % % % %             for i = 1:numspikes
% % % % % % %                 pklocation = loc(i);
% % % % % % %                 if length(data) < (pklocation+wind)
% % % % % % %                     stoppage = length(data);
% % % % % % %                 else
% % % % % % %                     stoppage = pklocation+wind;
% % % % % % %                 end
% % % % % % %                 [FastAHP(i,1) FastAHP(i,2)] = min(data(pklocation:stoppage));
% % % % % % %                 FastAHP(i,2) = FastAHP(i,2) + pklocation;
% % % % % % %             end
% % % % % % %             Results(sweep).FastAHP_Voltage = FastAHP(:,1);
% % % % % % %             Results(sweep).FastAHP_Time = FastAHP(:,2)*(si/1000);
% % % % % % %             Results(sweep).FastAHP_Baseline = FastAHP(:,1) - Results(sweep).baseline_potential;
            %% Threshold
            [Results(sweep).threshold_time, Results(sweep).threshold_amplitude,Results(sweep).threshold_index,...
                Results(sweep).dvdtthreshold,Results(sweep).dvdt1,Results(sweep).dvdt2, Results(sweep).dvdt1loc, Results(sweep).dvdt1pks] = ...
                SpikeThreshold(data,dvdtthreshold,si,numspikes,xminmax,sweep,0,stop,loc);
            % plot the results with the fast AHP and peaks as well
            Results(sweep).threshold_baseline = Results(sweep).threshold_amplitude - Results(sweep).baseline_potential;
            
            %%%%%%%%%%%%%%%%%%%%add FastAHP here %%%%%%%%%%%%%%%%%%
            [FastAHP] = FastAHPfinder(data,si,Results(sweep).dvdt1loc,dvdtthreshold);
            Results(sweep).FastAHP_Voltage = FastAHP(:,1);
            Results(sweep).FastAHP_Time = FastAHP(:,2)*(si/1000);
            Results(sweep).FastAHP_Baseline = FastAHP(:,1) - Results(sweep).baseline_potential;
                
            if graph_on == 1
            	fff = figure;
                plot(1:length(data),data,'b',loc,pks,'r*')
                hold on
                plot(1:length(data),data,'b',Results(sweep).threshold_index,Results(sweep).threshold_amplitude,'m*')
                xlim([xminmax])
                plot(FastAHP(:,2),FastAHP(:,1),'g.')
                xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
                ylabel('Volts')
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
            %% Start index for search ADP - if there is spikes, search from fast AHP of that single spike
            startsearch = (FastAHP(:,2)+1)*(si/1000); % start search from Fast AHP + 1 bin - this variable is in time, not points 
        else % if no spikes 
            numspikes = 0;
            %% start index for search ADP - if there is no spike, search ADP from end of baseline interval
            startsearch = (stop+1)*(si/1000); % IN TIME, NOT POINTS
            %% Plot it if graph_on == 1
            if graph_on == 1
            	fff = figure;
                plot(data)
                xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
                ylabel('Volts')
                title(sprintf('Sweep %g File:%s',sweep,filename))
            end
            %% All results based on spikes are blank
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
        end
        %% Make sure theres only 1 spike
        if numspikes > 1
            error('Sweep %g contains more than 1 spike',sweep)
        end
        
        %% When does ADP return to baseline
        if ~isempty(startsearch) %if there is a FAHP, then run next code 
        	[ADPendoutput] = ADPend(data,si,Results(sweep).baseline_potential,startsearch);
            Results(sweep).ADPend_time = ADPendoutput.ADPend_time;
            Results(sweep).ADPend_amplitude = ADPendoutput.ADPend_amplitude;
            Results(sweep).ADPduration = ADPendoutput.ADPduration;
            Results(sweep).ADP_AreaUnderCurve = ADPendoutput.ADP_AreaUnderCurve;
            Results(sweep).ADPenddata = ADPendoutput;
            if ~isempty(ADPendoutput.ADPend_idx) && graph_on == 1
            	blline = zeros(1,length(data));
                blline(:) = Results(sweep).baseline_potential;
                xx = zeros(1,length(data));
                if ~isempty(pks)
                    xx(1,FastAHP(:,2)+1) = min(get(gca,'ylim'));
                end
                xx(1,ADPendoutput.ADPend_idx) = min(get(gca,'ylim')); %-100;
                figure(fff)
                hold on
                plot(blline)
                bar(xx,'edgecolor','k','facecolor','k')
                xlim([0 length(data)])
            end
        else
            Results(sweep).ADPend_time = [];
            Results(sweep).ADPend_amplitude = [];
            Results(sweep).ADPduration = [];
            Results(sweep).ADP_AreaUnderCurve = [];
            Results(sweep).ADPenddata = [];
        end

        %% Find the Peak of ADP
        ADPend_idx = ADPendoutput.ADPend_idx;
        if ~isempty(pks) % if there is a spike
            FastAHPidx = FastAHP(:,2);
            [ADPpeak, ADPloc] = max(data(FastAHPidx+1:ADPend_idx));
            ADPloc = ADPloc + FastAHPidx;
            if ADPpeak < data(FastAHPidx) % if ADP found is smaller than the fast AHP amplitude, set ADP to fast AHP
                ADPloc = FastAHPidx;
                ADPpeak = data(FastAHPidx);
            end
        else % if no spike
            [ADPpeak, ADPloc] = max(data(stop+1:ADPend_idx));
            ADPloc = ADPloc + stop+1;
        end
        Results(sweep).ADPpeak_amplitude = ADPpeak;
        Results(sweep).ADPpeak_idx = ADPloc;
        Results(sweep).ADPpeak_time = ADPloc*(si/1000);
        if graph_on == 1
            ADPpeakline = zeros(1,length(data));
            ADPpeakline(:) = Results(sweep).ADPpeak_amplitude;
            xx = zeros(1,length(data));
            xx(1,ADPloc) = min(get(gca,'ylim')); %-100;
            figure(fff)
            hold on
            plot(ADPpeakline,'c')
            bar(xx,'edgecolor','c','facecolor','c')
            xlim([0 length(data)])
        end
            
        
        %% Post-Burst AHP Start 
        [AHPstartoutput] = PostBurstAHPstart(data,si,Results(sweep).baseline_potential,ADPend_idx);
%         Results(sweep).AHPstart_time = AHPstartoutput.AHPstart_time; % the AHPstart time should be the same as the ADP end time
        Results(sweep).AHPstart_time = Results(sweep).ADPend_time; 
%         Results(sweep).AHPpeak_negative_amplitude = AHPstartoutput.AHPpeak_negative_amplitude;
%         Results(sweep).AHPpeak_negative_time = AHPstartoutput.AHPpeak_negative_time;

        Results(sweep).AHPstartData = AHPstartoutput;
        if graph_on == 1
            xx = zeros(1,length(data));
            xx(1,ADPend_idx) = min(get(gca,'ylim')); %-100;
            figure(fff)
            hold on
            bar(xx,'edgecolor','k','facecolor','k')
            xlim([0 length(data)])
        end
        
        %% Post-Burst AHP Return
        if ~isempty(Results(sweep).AHPstart_time) %if there is AHP start, then run next code 
        	[AHPendoutput] = PostBurstAHPend(data,si,Results(sweep).baseline_potential,Results(sweep).AHPstart_time);
            Results(sweep).AHPend_time = AHPendoutput.AHPend_time;
            Results(sweep).AHPend_amplitude = AHPendoutput.AHPend_amplitude;
            Results(sweep).AHPduration = AHPendoutput.AHPduration;
            Results(sweep).AHP_AreaUnderCurve = AHPendoutput.AHP_AreaUnderCurve;
            Results(sweep).AHPenddata = AHPendoutput;
            if ~isempty(AHPendoutput.AHPend_idx) && graph_on == 1
            	blline = zeros(1,length(data));
                blline(:) = Results(sweep).baseline_potential;
                xx = zeros(1,length(data));
                xx(1,AHPendoutput.AHPend_idx) = min(get(gca,'ylim')); %-100;
                figure(fff)
                hold on
                plot(blline)
                bar(xx,'edgecolor','k','facecolor','k')
                xlim([0 length(data)])
            end
        else
            Results(sweep).AHPend_time = [];
            Results(sweep).AHPend_amplitude = [];
            Results(sweep).AHPduration = [];
            Results(sweep).AHP_AreaUnderCurve = [];
            Results(sweep).AHPenddata = [];
        end
        %% Find Peak Negative of AHP
        AHPstart_idx = ADPend_idx;
        AHPstart_idx = str2double(sprintf('%16.f',AHPstart_idx));
        AHPend_idx = AHPendoutput.AHPend_idx;
        AHPend_idx = str2double(sprintf('%16.f',AHPend_idx));
        [AHPpeak_amplitude, C] = min(data(AHPstart_idx+1:AHPend_idx));
        AHPpeak_idx = C+AHPstart_idx;
        Results(sweep).AHPpeak_negative_amplitude = AHPpeak_amplitude - Results(sweep).baseline_potential;
        Results(sweep).AHPpeak_negative_amplitude_nonbaseline = AHPpeak_amplitude;
        Results(sweep).AHPpeak_negative_time = AHPpeak_idx*(si/1000);
        Results(sweep).AHPpeak_negative_idx = AHPpeak_idx;
        if graph_on == 1
            xx = zeros(1,length(data));
            xx(1,AHPpeak_idx) = min(get(gca,'ylim')); % -100;
            figure(fff)
            hold on
            bar(xx,'edgecolor','k','facecolor','k')
            xlim([0 length(data)])
        end
        
        %% Tau 
        if ~isempty(Results(sweep).AHPpeak_negative_time)
            [TAU] = tau(data,si,Results(sweep).baseline_potential,Results(sweep).AHPpeak_negative_time);
            Results(sweep).Tau_duration = TAU.tau_duration;
            Results(sweep).Tau_time = TAU.tau_time;
            Results(sweep).Tau_amplitude = TAU.tau_amplitude;
            Results(sweep).Tau_amplitude_baseline = TAU.tau_amplitude_baseline;
            if ~isempty(Results(sweep).Tau_time) && graph_on == 1
                blline = zeros(1,length(data));
                blline(:) = Results(sweep).Tau_amplitude;
                xx = zeros(1,length(data));
                xx(1,TAU.tau_idx) = min(get(gca,'ylim'));%  -100;
                figure(fff)
                hold on
                plot(blline,'r')
                bar(xx,'edgecolor','r','facecolor','r')
                xlim([0 length(data)])
            end
        else
            Results(sweep).Tau_duration = [];
            Results(sweep).Tau_time = [];
            Results(sweep).Tau_amplitude = [];
            Results(sweep).Tau_amplitude_baseline = [];
        end
            
        %% Prep data for mean trace
%         meansweepdata(sweep,:) = data - Results(sweep).baseline_potential;

    end
    
%     %% Calculate Post-Burst AHP on the mean Trace
%     sweep = numsweeps + 1;    
%     meansweep = mean(meansweepdata,1);
%     meansweepbl = mean(meansweep(start:stop));
%     if graph_on == 1
%         mfff = figure;
%         plot(meansweep)
%         title('Mean Sweep')
%         ylabel('Volts')
%     %   movegui('northwest')
%         xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
%     end
%     Results(1,sweep).data = meansweep;
%     Results(1,sweep).baseline_potential = meansweepbl;
%     Results(1,sweep).THIS_IS_MEAN_SWEEP = 1;
%     Results(1,sweep).SI = si;
%     Results(1,sweep).baseline_potentialstd = std(meansweep(start:stop));
%     Results(1,sweep).filename = abffile;
% 	Results(sweep).baseline_timerange = [start*(si/1000); stop*(si/1000)];
% 	Results(sweep).num_spikes = NaN;
%     Results(sweep).peak_times = NaN;
% 	Results(sweep).peak_idx = NaN;
%     Results(sweep).peak_amplitudes = NaN;
%     Results(sweep).peak_to_baseline = NaN;
%     Results(sweep).FastAHP_Voltage = NaN;
%     Results(sweep).FastAHP_Time = NaN;
%     Results(sweep).FastAHP_Baseline = NaN;
%     Results(sweep).threshold_time = NaN;
%     Results(sweep).threshold_amplitude = NaN;
%     Results(sweep).threshold_index = NaN;
%     Results(sweep).threshold_baseline = NaN;
%     Results(sweep).dvdtthreshold = NaN;
%     Results(sweep).dvdt1 = NaN;
%     Results(sweep).dvdt2= NaN;
%     Results(sweep).SpikeWidth_Baseline = NaN;
%     Results(sweep).SpikeWidth_Threshold = NaN;
%     Results(sweep).SpikeWidth_FirstSpike = NaN;
%     Results(sweep).ISI = NaN;
%     %% Postburst AHP start for mean sweep
% 	[mAHPstartoutput] = PostBurstAHPstart(meansweep,si,meansweepbl,stop);
%     Results(sweep).AHPstart_time = mAHPstartoutput.AHPstart_time;
%     Results(sweep).AHPpeak_negative_amplitude = mAHPstartoutput.AHPpeak_negative_amplitude;
%     Results(sweep).AHPpeak_negative_time = mAHPstartoutput.AHPpeak_negative_time;
%     Results(sweep).AHP1s_time = mAHPstartoutput.AHP1s_time;
%     Results(sweep).AHP1s_mean_amplitude = mAHPstartoutput.AHP1s_mean_amplitude;
%     Results(sweep).AHPstartData = mAHPstartoutput;
% 	if graph_on == 1
%         blline = zeros(1,length(data));
%         blline(:) = Results(sweep).baseline_potential;
%         xx = zeros(1,length(data));
%         xx(1,AHPstartoutput.AHPstart_idx) = min(get(gca,'ylim')); %-100;
%         xx(1,AHPstartoutput.AHPpeak_negative_idx) = min(get(gca,'ylim')); % -100;
%         figure(mfff)
%         hold on
%         plot(blline)
%         bar(xx)
%         xlim([0 length(data)])
%     end
%     %% Postburst AHP Tau for mean sweep
% 	if ~isempty(Results(sweep).AHPpeak_negative_time)
%         [mTAU] = tau(meansweep,si,meansweepbl,Results(sweep).AHPpeak_negative_time);
%         Results(sweep).Tau_duration = mTAU.tau_duration;
%         Results(sweep).Tau_time = mTAU.tau_time;
%         Results(sweep).Tau_amplitude = mTAU.tau_amplitude;
%         Results(sweep).Tau_amplitude_baseline = mTAU.tau_amplitude_baseline;
%         if ~isempty(Results(sweep).Tau_time) && graph_on == 1
%         	blline = zeros(1,length(data));
%             blline(:) = Results(sweep).Tau_amplitude;
%             xx = zeros(1,length(data));
%             xx(1,mTAU.tau_idx) = min(get(gca,'ylim'));%  -100;
%             figure(mfff)
%             hold on
%             plot(blline,'r')
%             bar(xx,'edgecolor','r','facecolor','r')
%             xlim([0 length(data)])
%         end
%     else
%         Results(sweep).Tau_duration = [];
%         Results(sweep).Tau_time = [];
%     	Results(sweep).Tau_amplitude = [];
%         Results(sweep).Tau_amplitude_baseline = [];
% 	end
%     %% Postburst AHP return for mean sweep
% 	if ~isempty(Results(sweep).AHPstart_time) %if there is AHP start, then run next code 
%     	[mAHPendoutput] = PostBurstAHPend(meansweep,si,meansweepbl,Results(sweep).AHPstart_time);
%         Results(sweep).AHPend_time = mAHPendoutput.AHPend_time;
%         Results(sweep).AHPend_amplitude = mAHPendoutput.AHPend_amplitude;
%         Results(sweep).AHPduration = mAHPendoutput.AHPduration;
%         Results(sweep).AHP_AreaUnderCurve = mAHPendoutput.AHP_AreaUnderCurve;
%         Results(sweep).AHPenddata = mAHPendoutput;
%         if ~isempty(mAHPendoutput.AHPend_idx) && graph_on == 1
%         	blline = zeros(1,length(data));
%             blline(:) = Results(sweep).baseline_potential;
%             xx = zeros(1,length(data));
%             xx(1,mAHPendoutput.AHPend_idx) = min(get(gca,'ylim')); %-100;
%             figure(mfff)
%             hold on
%             plot(blline)
%             bar(xx)
%             xlim([0 length(data)])
%         end
%     else
%         Results(sweep).AHPend_time = [];
%         Results(sweep).AHPend_amplitude = [];
%         Results(sweep).AHPduration = [];
%         Results(sweep).AHP_AreaUnderCurve = [];
%         Results(sweep).AHPenddata = [];
% 	end

        
    
    
end
    
