% startsearch = peak_times(1,1)/(si/1000);
function [output] = PostBurstAHPanalysis(data,si,bl,startsearch)
numconsec = 50/(si/1000); % 50ms 
belowblidx = find(data(startsearch:end) < bl); % find below BL starting from first spike
if ~isempty(belowblidx)
    diffbtwn = diff(belowblidx); % if consecutive bins are below threshold, diff should be 1 for each
    AHPstart = [];
    counter = 1;
    if length(diffbtwn) > numconsec
        while isempty(AHPstart)
            if sum(diffbtwn(counter:counter+numconsec-1)) == numconsec
                AHPstart = counter
            end
            counter = counter + 1;
            if counter >= length(diffbtwn)-numconsec
                break
            end
        end
    else
        AHPstart = [];
    end
    if ~isempty(AHPstart)
        AHPstart_time = startsearch+belowblidx(AHPstart);
        AHPstart_amplitude = data(AHPstart_time);
        [AHPpeak_amplitude, C] = min(data(AHPstart_time:end));
        AHPpeak_time = C+AHPstart_time;
        % Find 1sAHP
        onesec = 1000/(si/1000);
        AHP1s_time = AHPstart_time+onesec;
        AHP1s_meanamplitude = mean(data(AHP1s_time-5:AHP1s_time+5));
        Output.AHPstart_time = AHPstart_time*(si/1000);
        Output.AHPstart_amplitude = AHPstart_amplitude;
        Output.AHPpeak_negative_amplitude = AHPpeak_amplitude;
        Output.AHPpeak_negative_time = AHPpeak_time*(si/1000);
        Output.AHP1s_time = AHP1s_time*(si/1000);
        Output.AHP1s_mean_amplitude = AHP1s_meanamplitude;
    else
        Output.AHPstart_time = [];
        Output.AHPstart_amplitude = [];
        Output.AHPpeak_negative_amplitude = [];
        Output.AHPpeak_negative_time = [];
        Output.AHP1s_time = [];
        Output.AHP1s_mean_amplitude = [];
    end
else
	Output.AHPstart_time = [];
    Output.AHPstart_amplitude = [];
    Output.AHPpeak_negative_amplitude = [];
    Output.AHPpeak_negative_time = [];
    Output.AHP1s_time = [];
    Output.AHP1s_mean_amplitude = [];
end

%% now find when it returns to baseline - slow AHP
if ~isempty(AHPstart_time)
    numconsecreturn = 10/(si/1000);
    returnAHPbelowblidx = find(data(AHPstart_time:end) >= bl); 
    if ~isempty(returnAHPbelowblidx)
        returnAHPdiffbtwn = diff(returnAHPbelowblidx); % if consecutive bins are below threshold, diff should be 1 for each
        returnAHPpossible = [];
        counter = 1;
        while isempty(returnAHPpossible)
            if sum(returnAHPdiffbtwn(counter:counter+numconsecreturn-1)) == numconsecreturn
                returnAHPpossible = counter
            end
            counter = counter + 1;
            if counter >= length(returnAHPdiffbtwn)-numconsecreturn
                break
            end
        end
        if ~isempty(returnAHPpossible)
            AHPend_time = AHPstart_time+returnAHPbelowblidx(returnAHPpossible);
            AHPend_amplitude = data(AHPend_time);
            AHPduration = AHPend_time - AHPstart_time;
            AHP_AUC = trapz(abs(data(AHPstart_time:AHPend_time))); % area under the curve using trapezoidal numerical integration
        else
            AHPend_time = [];
            AHPend_amplitude = [];
            AHPduration = [];
            AHP_AUC = [];
        end
        Results.AHPend_time = AHPend_time*(si/1000);
        Results.AHPend_amplitude = AHPend_amplitude;
        Results.AHPduration = AHPduration*(si/1000);
        Results.AHPpeak = Results.baseline_potential - Results.AHPpeak_negative_amplitude
        Results.AHPslow = Results.baseline_potential - Results.AHP1s_mean_amplitude
        Results.AHP_AreaUnderCurve = (AHP_AUC*(si/1000))/1000;
    end

    blline = zeros(1,length(data));
    blline(:) = bl;
    figure, 
    plot(1:length(data),data,'b',loc,pks,'r*')
    hold on
    plot(blline)
    xx = zeros(1,length(data));
    xx(1,AHPstart_time) = -100;
    xx(1,AHPpeak_time) = -100;
    xx(1,AHPend_time) = -100;
    bar(xx)
%     xlim([0 AHPend_time+
%     xlim(xminmax)
xlim([0 length(data)])
xlabel('points (multiply si/1000 for ms)')
%   	set(gca,'xticklabel',num2str(get(gca,'xtick')'))
%     set(gca,'yticklabel',num2str(get(gca,'ytick')'))
end
%% Find the time constant

timeconstantthresh = AHPpeak_amplitude + Results.AHPpeak*.632;
numconsec = 50;
% while isempty(taupoint)
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
Results.TimeConstant = AHPtau - AHPpeak_time;