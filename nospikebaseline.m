function [newbl, newbl_std, pointstouse] = nospikebaseline(data,si,start,stop,loc,withinbl)
    if nargin ~= 6
        error('Not enough input arguments')
    end
    % recalculate baseline potential with spike times removed
    violate_idx = loc(withinbl);
    back = 10/(si/1000);
    forward = 90/(si/1000);
    bltimepoints = data(start:stop);
    removeidx(:,1) = zeros(length(bltimepoints),1);
    for i = 1:length(violate_idx)
        if violate_idx(i)+forward <= length(bltimepoints) 
            goback = violate_idx(i) - back;
            goforward = violate_idx(i) + forward;
            if goback <= 0
                goback = 1;
            end
            removeidx(goback:goforward,1) = 1;
        else
            removeidx(violate_idx(i)-back:length(bltimepoints)) = 1;
        end
    end
    bltimepoints(logical(removeidx)) = [];
    newbl = mean(bltimepoints);
    newbl_std = std(bltimepoints);
    pointstouse = (start:stop)';
    pointstouse(logical(removeidx)) = [];
    
end


    
    