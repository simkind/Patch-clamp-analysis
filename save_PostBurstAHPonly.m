% Results should be struct containing sweeps

function [Results] = save_PostBurstAHPonly(Results,filename)
    [Results] = bracket2nan(Results); % convert empty brackets into NaN
    
    label = {'ABF File','Sweep','Baseline (mV)',...
        'AHPstart Time (ms)','AHPpeak Time (ms)','AHPpeak Amplitude (mV)','AHP1s Time (ms)','AHP1s Amplitude (mV)'...
        'AHPend Time (ms)','AHPend Amplitude (mV)','AHP Duration (ms)','AHP AUC (mv/s)',...
        'AHPtau Return Time (ms)','AHP Tau (ms)','AHPtau Amplitude (mV)'};
    writethis = [];
    for i = 1:length(Results) % for each sweep
        if i == length(Results)
            sweep = cellstr('Mean Sweep');
        else
            sweep = num2cell(i);
        end

        writethistemp = [];
        writethistemp = [cellstr(filename), sweep, num2cell(Results(i).baseline_potential)];
        AHPstuff = NaN(1,12);
        AHPstuff = [Results(i).AHPstart_time, Results(i).AHPpeak_negative_time, Results(i).AHPpeak_negative_amplitude, Results(i).AHP1s_time,...
        Results(i).AHP1s_mean_amplitude, Results(i).AHPend_time,Results(i).AHPend_amplitude,Results(i).AHPduration,...
        Results(i).AHP_AreaUnderCurve, Results(i).Tau_time, Results(i).Tau_duration,Results(i).Tau_amplitude];
           
        writethistemp = [writethistemp, num2cell(AHPstuff)];
        writethis = [writethis; writethistemp];
    end
    writethiswithlabel = [label; writethis];
    Table = writethiswithlabel;
    xlswrite(sprintf('%s PostBurstAHPonly.xlsx',filename),writethiswithlabel)
    save(sprintf('%s PostBurstAHPonly.mat',filename),'Results','Table')
end