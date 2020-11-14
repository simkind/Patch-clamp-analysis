% Converts empty brackets [] (no data) into NaN. Useful when writing
% results to excel 

function [Output] = bracket2nan(Results)

    for i = 1:length(Results)
        vars = fieldnames(Results(i));
        for j = 1:numel(vars)
            stuff = Results(i).(vars{j});
            thisField = vars{j};
            if isempty(stuff)
                replace = NaN;
                commandLine = sprintf('Results(%g).%s = replace',i,thisField);
                eval(commandLine);
            end
        end
    end
    Output = Results;
end            