% AHPpeak_amplitude = Results.AHPpeak_negative_amplitude
% AHPpeak_amplitude_time = Results.AHPpeak_negative_time

function [] = PostBurstAHPtau(data,si,bl,AHPpeak_amplitude,AHPpeak_amplitude_time)
    AHPpeak_time = AHPpeak_amplitude_time/(si/1000);
    AHPpeak_time = str2double(sprintf('%16.f',AHPpeak_time));
    AHPpeak2bl = AHPpeak_amplitude-bl;
    timeconstantthresh = AHPpeak_amplitude - AHPpeak2bl*.632;
    numconsec = 50;
    belowtau = [];
	belowtau = find(timeconstantthresh <= data(AHPpeak_time:end))+ AHPpeak_time-1 ;
    belowtau(:,2) = data(belowtau(:,1));

    if ~isempty(belowtau)
        diffbtwntau = diff(belowtau(:,1));
        AHPtau = [];
        counter = 1;
        while isempty(AHPtau)
            if sum(diffbtwntau(counter:counter+numconsec-1)) == numconsec
                AHPtau = belowtau(counter,1);
            end
            counter = counter + 1;
            if counter >= length(diffbtwntau)-numconsec
                break
            end
        end
    end
Results.TimeConstant_Threshold = timeconstantthresh;
Results.TimeConstant_Location = AHPtau*(si/1000);
Results.TimeConstant_Amplitude = data(AHPtau);
Results.TimeConstant = (AHPtau - AHPpeak_time)*(si/1000);