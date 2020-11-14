% Results should be struct containing sweeps

function [Results] = save_accommodation(Results,filename)
    [Results] = bracket2nan(Results); % convert empty brackets into NaN
    label = {'ABF File','Sweep','Spike Number','Baseline (mV)','Spike Times (ms)','Spike Amplitude (mV)','Spike Threshold Time (ms)','Spike Threshold (mV)',...
        'Spike 1/2 Width-Baseline (ms)','Spike 1/2 Width-Threshold (ms)','Spike 1/2 Width 1st Width-Baseline (ms)','FastAHP Time (ms)','FastAHP Voltage(mV)','ISI (ms)'};
    writethis = [];
    for i = 1:length(Results) % for each sweep
        numspikes = Results(i).num_spikes;
       
        
        if numspikes > 1
            writethistemp = [];
            for s = 1:numspikes
                writethistempspike = [];
                writethistempspike = [cellstr(filename), i, s, num2cell(Results(i).baseline_potential),...
                    num2cell(Results(i).peak_times(s)), num2cell(Results(i).peak_to_baseline(s)),num2cell(Results(i).threshold_time(s)),...
                    num2cell(Results(i).threshold_amplitude(s)),num2cell(Results(i).SpikeWidth_Baseline(s)),num2cell(Results(i).SpikeWidth_Threshold(s)),...
                    num2cell(Results(i).SpikeWidth_FirstSpike(s)), num2cell(Results(i).FastAHP_Time(s)), num2cell(Results(i).FastAHP_Voltage(s))];
                writethistemp = [writethistemp; writethistempspike];
            end
            writethistemp = [writethistemp, num2cell([NaN;Results(i).ISI])];
        else
            if numspikes == 1
                s = 1;
            else
                s = NaN;
            end
            A = NaN;
            writethistemp = [];
            writethistemp = [cellstr(filename), i,s, num2cell(Results(i).baseline_potential),...
                num2cell(Results(i).peak_times), num2cell(Results(i).peak_to_baseline),num2cell(Results(i).threshold_time),...
                num2cell(Results(i).threshold_amplitude),num2cell(Results(i).SpikeWidth_Baseline),num2cell(Results(i).SpikeWidth_Threshold),...
                num2cell(Results(i).SpikeWidth_FirstSpike), num2cell(Results(i).FastAHP_Time), num2cell(Results(i).FastAHP_Voltage),num2cell(A)];
            
        end
        writethis = [writethis; writethistemp];
    end
    writethiswithlabel = [label; writethis];
    Table = writethiswithlabel;
    xlswrite(sprintf('%s Accommodation.xlsx',filename),writethiswithlabel)
    save(sprintf('%s Accommodation.mat',filename),'Results','Table')
end