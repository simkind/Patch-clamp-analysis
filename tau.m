
function [output] = tau(data,si,bl,AHP_peak_negative_time)
    AHPpeak_idx = AHP_peak_negative_time/(si/1000);
    AHPpeak_idx = str2double(sprintf('%16.f',AHPpeak_idx));
    AHPpeak = data(AHPpeak_idx);
    tauthreshold = AHPpeak - ((AHPpeak-bl)*.623);

    tauidx = [];
	counter = 1;
        while isempty(tauidx)
            if data(AHPpeak_idx + counter) >= tauthreshold 
                tauidx = counter;
            end
            counter = counter + 1;
            if counter >= length(data)-AHPpeak_idx
                break
            end
        end
        if ~isempty(tauidx)
            tauidx = tauidx + AHPpeak_idx;
            output.tau_idx = tauidx;
            output.tau_time = tauidx*(si/1000);
            output.tau_duration = output.tau_time - AHP_peak_negative_time;
            output.tau_amplitude = tauthreshold;
            output.tau_amplitude_baseline = tauthreshold - bl;
        else       
            output.tau_idx = [];
            output.tau_time = [];
            output.tau_duration = [];
            output.tau_amplitude = [];
            output.tau_amplitude_baseline = [];
        end
end
