% Results should be struct containing sweeps

function [Results] = save_AHPanalysis(Results,filename)
    [Results] = bracket2nan(Results); % convert empty brackets into NaN
    label = {'ABF File','Sweep','Spike Number','Baseline (mV)','Spike Times (ms)',...
        'Spike Amplitude (mV)','Spike Threshold Time (ms)','Spike Threshold (mV)',...
        'Spike 1/2 Width-Baseline (ms)','Spike 1/2 Width-Threshold (ms)',...
        'Spike 1/2 Width-First Width (ms)','FastAHP Time (ms)','FastAHP Voltage(mV)',...
        'ISI (ms)','AHPstart Time (ms)','AHPpeak Time (ms)','AHPpeak Amplitude (mV)','AHP1s Time (ms)','AHP1s Amplitude (mV)'...
        'AHPend Time (ms)','AHPend Amplitude (mV)','AHP duration (ms)','AHP AUC (mv/s)',...
        'AHPtau Return Time (ms)','AHP Tau (ms)','AHPtau Amplitude (mV)'};
    writethis = [];
    for i = 1:length(Results) % for each sweep
        numspikes = Results(i).num_spikes;
        if i == length(Results)
            sweep = cellstr('Mean Sweep');
        else
            sweep = num2cell(i);
        end
        if numspikes > 1 % if more than 1 spike in the sweep
            writethistemp = [];
            for s = 1:numspikes
                writethistempspike = [];
                writethistempspike = [cellstr(filename), sweep s, num2cell(Results(i).baseline_potential),...
                    num2cell(Results(i).peak_times(s)), num2cell(Results(i).peak_to_baseline(s)),num2cell(Results(i).threshold_time(s)),...
                    num2cell(Results(i).threshold_amplitude(s)),num2cell(Results(i).SpikeWidth_Baseline(s)),num2cell(Results(i).SpikeWidth_Threshold(s)),...
                    num2cell(Results(i).SpikeWidth_FirstSpike(s)), num2cell(Results(i).FastAHP_Time(s)), num2cell(Results(i).FastAHP_Voltage(s))];
                writethistemp = [writethistemp; writethistempspike];
            end
            AHPstuff = NaN(numspikes,12);
            AHPstuff(1,1) = Results(i).AHPstart_time;
            AHPstuff(1,2) = Results(i).AHPpeak_negative_time;
            AHPstuff(1,3) = Results(i).AHPpeak_negative_amplitude;
            AHPstuff(1,4) = Results(i).AHP1s_time;
            AHPstuff(1,5) = Results(i).AHP1s_mean_amplitude;
            AHPstuff(1,6) = Results(i).AHPend_time;
            AHPstuff(1,7) = Results(i).AHPend_amplitude;
            AHPstuff(1,8) = Results(i).AHPduration;
            AHPstuff(1,9) = Results(i).AHP_AreaUnderCurve;
            AHPstuff(1,10) = Results(i).Tau_time;
            AHPstuff(1,11) = Results(i).Tau_duration;
            AHPstuff(1,12) = Results(i).Tau_amplitude;
            writethistemp = [writethistemp, num2cell([NaN;Results(i).ISI]),num2cell(AHPstuff)];
    
        else
            if numspikes == 1
                s = 1;
            else
                s = NaN;
            end
            writethistemp = [];
            writethistemp = [cellstr(filename), sweep,s, num2cell(Results(i).baseline_potential),...
                num2cell(Results(i).peak_times), num2cell(Results(i).peak_to_baseline),num2cell(Results(i).threshold_time),...
                num2cell(Results(i).threshold_amplitude),num2cell(Results(i).SpikeWidth_Baseline),num2cell(Results(i).SpikeWidth_Threshold),...
                num2cell(Results(i).SpikeWidth_FirstSpike), num2cell(Results(i).FastAHP_Time), num2cell(Results(i).FastAHP_Voltage)];
            AHPstuff = NaN(1,12);
            AHPstuff = [Results(i).AHPstart_time, Results(i).AHPpeak_negative_time, Results(i).AHPpeak_negative_amplitude, Results(i).AHP1s_time,...
            Results(i).AHP1s_mean_amplitude, Results(i).AHPend_time,Results(i).AHPend_amplitude,Results(i).AHPduration,...
            Results(i).AHP_AreaUnderCurve, Results(i).Tau_time, Results(i).Tau_duration,Results(i).Tau_amplitude];
            
            writethistemp = [writethistemp, NaN,num2cell(AHPstuff)];
            
        end
        writethis = [writethis; writethistemp];
    end
    writethiswithlabel = [label; writethis];
    Table = writethiswithlabel;
    xlswrite(sprintf('%s AHPanalysis.xlsx',filename),writethiswithlabel)
    save(sprintf('%s AHPanalysis.mat',filename),'Results','Table')
end