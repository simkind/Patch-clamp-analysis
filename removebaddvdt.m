function [output outputdvdt1loc] = removebaddvdt(pklocations, timepointstouse,dvdt1loc)
output = [];
outputdvdt1loc = [];
for i = 1:length(pklocations)
	vector = timepointstouse;
    vectordvdt1loc = dvdt1loc;
    if ismember(output,vector)
        tf = ismember(output,vector);
        vector(tf) = [];
        vectordvdt1loc(tf) = [];
    end
    usethis = [];
    usethisdvdt1loc = [];
    b = pklocations(i); % the peak of one of the spikes
    while isempty(usethis)
        [~,I] = min(abs(vector-b)); % the closest threshold value to the peak
        c = vector(I);
        cdvdt1loc = vectordvdt1loc(I);
        if c < pklocations(i) % if peak happens after threshold
            usethis = c; % use that threshold
            usethisdvdt1loc = cdvdt1loc;
            vector(I) = []; % delete that threshold value from "vector"
            vectordvdt1loc(I) = [];
        else
            vector(I) = [];
            vectordvdt1loc(I) = [];
        end
        if isempty(vector)
            break % terminate while loop if vector becomes empty
        end
    end
    if ~isempty(usethis)
        output(1,i) = usethis;
        outputdvdt1loc(1,i) = usethisdvdt1loc;
    else
        output(1,i) = NaN;
        outputdvdt1loc(1,i) = NaN;
    end
end
outputdvdt1loc(isnan(outputdvdt1loc)) = []; % removes NaN
%% ORIGINAL COPY - only outputs thresholds. Newer version above outputs thresholds AND updated dvdt1loc
% function [output] = removebaddvdt(pklocations, timepointstouse)
% output = [];
% for i = 1:length(pklocations)
% 	vector = timepointstouse;
%     if ismember(output,vector)
%         tf = ismember(output,vector);
%         vector(tf) = [];
%     end
%     usethis = [];
%     b = pklocations(i);
%     while isempty(usethis)
%         [~,I] = min(abs(vector-b));
%         c = vector(I);
%         if c < pklocations(i) % if peak happens after threshold
%             usethis = c;
%             vector(I) = [];
%         else
%             vector(I) = [];
%         end
%         if isempty(vector)
%             break
%         end
%     end
%     if ~isempty(usethis)
%         output(1,i) = usethis;
%     else
%         output(1,i) = NaN;
%     end
% end