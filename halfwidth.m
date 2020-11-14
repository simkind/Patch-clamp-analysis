% threshold = peak_amps(i)/2 + bl
% pklocation = peak_times(i)/(si/1000) % need to go back to points
function [halfspikewidth, backward_time, forward_time] = halfwidth(threshold, pklocation,data,si)
   
    forward = [];
    counter = 1;
    while isempty(forward)
        if data(pklocation+counter) <= threshold
            forward = pklocation+counter;
        end
        counter = counter + 1;
        if counter >= length(data(pklocation:end))
            break
        end
    end
    backward = [];
    counter = 1;
    while isempty(backward) 
        if data(pklocation-counter) <= threshold
            backward = pklocation-counter;
        end
        counter = counter + 1;
        if counter >= length(data(1:pklocation))
            break
        end
    end
	if ~isempty(backward) || ~isempty(forward)
        halfspikewidth = (forward - backward)*(si/1000);
    else
        halfspikewidth = [];
    end
    backward_time = backward*(si/1000);
    forward_time = forward*(si/1000);
end  