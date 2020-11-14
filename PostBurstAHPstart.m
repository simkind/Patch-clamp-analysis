
function [output] = PostBurstAHPstart(data,si,bl,startsearch)
startsearch = str2double(sprintf('%16.f',startsearch));
numconsec = 50/(si/1000); % 50ms 
belowblidx = find(data(startsearch:end) < bl); % find below BL starting from first spike
if ~isempty(belowblidx) % if there are points below BL, 
    diffbtwn = diff(belowblidx); % if consecutive bins are below threshold, diff should be 1 for each
    AHPstart = [];
    counter = 1;
    if length(diffbtwn) > numconsec % if it's consecutive for 50ms, then find AHP start
        while isempty(AHPstart)
            if sum(diffbtwn(counter:counter+numconsec-1)) == numconsec
                AHPstart = counter;
            end
            counter = counter + 1;
            if counter >= length(diffbtwn)-numconsec
                break
            end
        end
    else % if it's not consecutive for 50ms, there is not AHP start
        AHPstart = [];
    end
    
    if ~isempty(AHPstart) % if there is an AHP start, calculate values 
        AHPstart_time = startsearch+belowblidx(AHPstart);
        AHPstart_amplitude = data(AHPstart_time);
%         [AHPpeak_amplitude, C] = min(data(AHPstart_time:end));
%         AHPpeak_time = C+AHPstart_time;
        % Find 1sAHP
        onesec = 1000/(si/1000);
% % % % % % % % % %         AHP1s_time = AHPstart_time+onesec;
% % % % % % % % % %         AHP1s_meanamplitude = mean(data(AHP1s_time-5:AHP1s_time+5));
        
        output.AHPstart_time = AHPstart_time*(si/1000);
        output.AHPstart_idx = AHPstart_time;
        output.AHPstart_amplitude = AHPstart_amplitude;
%         output.AHPpeak_negative_amplitude = AHPpeak_amplitude;
%         output.AHPpeak_negative_amplitude_baseline = AHPpeak_amplitude-bl;
%         output.AHPpeak_negative_time = AHPpeak_time*(si/1000);
%         output.AHPpeak_negative_idx = AHPpeak_time;
% % % % % % % % % %         output.AHP1s_time = AHP1s_time*(si/1000);
% % % % % % % % % %         output.AHP1s_mean_amplitude = AHP1s_meanamplitude;
% % % % % % % % % %         output.AHP1s_mean_amplitude_baseline = AHP1s_meanamplitude-bl;
    else % if there is no AHP start, there are no values 
        output.AHPstart_time = [];
        output.AHPstart_idx = [];
        output.AHPstart_amplitude = [];
%         output.AHPpeak_negative_amplitude = [];
%         output.AHPpeak_negative_amplitude_baseline = [];
%         output.AHPpeak_negative_time = [];
%         output.AHPpeak_negative_idx = [];
        output.AHP1s_time = [];
        output.AHP1s_mean_amplitude = [];
        output.AHP1s_mean_amplitude_baseline = [];
    end
else % there are no points below BL so no AHP start
	output.AHPstart_time = [];
    output.AHPstart_idx = [];
    output.AHPstart_amplitude = [];
    output.AHPpeak_negative_amplitude = [];
    output.AHPpeak_negative_amplitude_baseline = [];
    output.AHPpeak_negative_time = [];
    output.AHPpeak_negative_idx = [];
    output.AHP1s_time = [];
    output.AHP1s_mean_amplitude = [];
    output.AHP1s_mean_amplitude_baseline = [];
end