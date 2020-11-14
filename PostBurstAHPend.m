%  AHPstart_time = Results(sweep).AHPstart_time
function [output] = PostBurstAHPend(data,si,bl,AHPstart_time)
    AHPstart_idx = AHPstart_time/(si/1000);
	AHPstart_idx = str2double(sprintf('%16.f',AHPstart_idx));
% if ~isempty(AHPstart_idx) % if there is an AHPstart - but you can do this in the script
    numconsecreturn = 10/(si/1000);
    returnAHPbelowblidx = find(data(AHPstart_idx:end) >= bl); % find data points above baseline after AHPstart_idx
    if ~isempty(returnAHPbelowblidx) && length(returnAHPbelowblidx) > numconsecreturn  % if there are points above
        returnAHPdiffbtwn = diff(returnAHPbelowblidx); % if consecutive bins are below threshold, diff should be 1 for each
        returnAHPpossible = [];
        counter = 1;
        while isempty(returnAHPpossible)
            if sum(returnAHPdiffbtwn(counter:counter+numconsecreturn-1)) == numconsecreturn
                returnAHPpossible = counter;
            end
            counter = counter + 1;
            if counter >= length(returnAHPdiffbtwn)-numconsecreturn
                break
            end
        end
        if ~isempty(returnAHPpossible) % if there is AHP end point that meets criteria
            AHPend_time = AHPstart_idx+returnAHPbelowblidx(returnAHPpossible);
        else % if there isn't an AHP end point
            AHPend_time = length(data);
        end
        AHPend_amplitude = data(AHPend_time);
        AHPduration = AHPend_time - AHPstart_idx;
        AHP_AUC = trapz(abs(data(AHPstart_idx:AHPend_time)-bl)); % area under the curve using trapezoidal numerical integration
        
        output.AHPend_time = AHPend_time*(si/1000);
        output.AHPend_idx = AHPend_time;
        output.AHPend_amplitude = AHPend_amplitude;
        output.AHPduration = AHPduration*(si/1000);
        output.AHP_AreaUnderCurve = (AHP_AUC*(si/1000))/1000;
    else
        output.AHPend_idx = length(data);
        output.AHPend_time = output.AHPend_idx*(si/1000);
        output.AHPend_amplitude = data(output.AHPend_idx);
        output.AHPduration = output.AHPend_time - AHPstart_time;
        output.AHP_AreaUnderCurve = ((trapz(abs(data(AHPstart_idx:output.AHPend_idx))))*(si/1000))/1000;
    end
end
 