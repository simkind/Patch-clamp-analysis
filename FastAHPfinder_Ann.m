% dvdtpktime = Results(sweep).threshold_time

function [FastAHP] = FastAHPfinder_Ann(data,si,dvdtpkloc,dvdtthreshold)

%     dvdtpkloc = dvdtpktime/(si/1000); % convert dvdt1pktimes to index

    %% Find Peak Negative Smoothed dvdt1 - minimum dvdt - after each positive dvdt1 peak
	dvdt1 = diff(data)/(si/1000); % first derivative
    dvdt1v2 = dvdt1; % make a copy of dvdt1
    dvdt1v2 = smooth(dvdt1v2,8); % smoothed dvdt1 by 5 time points
    for i = 1:length(dvdtpkloc)
        start = dvdtpkloc(i)+1;
        if i == length(dvdtpkloc)
%             stop = length(dvdt1v2);
            stop = dvdtpkloc(i)+(30/(si/1000)); % search for minimum dvdt1 30ms after last spike
            if stop > length(dvdt1) % if stop occurs after end of data set
                stop = length(dvdt1); % set stop to end of data
            end
        else
            stop = dvdtpkloc(i+1);
        end
        
        [a b] = findpeaks(-1*(dvdt1v2(start:stop)),'minpeakheight',dvdtthreshold,'npeaks',1); % find the minimum by searching for peak in data * -1
        
        if ~isempty(a) && ~isempty(b)
            dvdtmin(i,1) = a*-1;
            dvdtmin(i,2) = b+dvdtpkloc(i);
        else
            dvdtmin(i,1) = NaN;
            dvdtmin(i,2) = NaN;
        end
        
%         [dvdtmin(i,1), b] = min(dvdt1v2(start:stop));
%         dvdtmin(i,2) = b+dvdtpkloc(i);
    end
% figure, plot(1:length(dvdt1v2),dvdt1v2,'b',dvdtmin(:,2),dvdtmin(:,1),'r*')
    %% Find When Smoothed dvdt1 Returns to 0

    wind = 10/(si/1000); % window size = 0.5ms (dina changed wind from 20 to 30 7/26/18)
    
    for i = 1:size(dvdtmin,1) % from each minimum value now
        
        % AEH: only do contents of loop if dvdtmin is not NaN
        if ~isnan(dvdtmin(i,1))
            
            start = dvdtmin(i,2)+1;
            if start+wind-1 > length(dvdt1v2)
                stop = length(dvdt1v2);
            else
                stop = start+wind-1;
            end
            counter = 0;
            found = [];
            while isempty(found)
                if stop+counter > length(dvdt1v2) %
                    figure, plot(data)
                    error('Sweep data ends during a spike. Check abffile')
                end
                if mean(dvdt1v2(start+counter:stop+counter)) > -.5 && mean(dvdt1v2(start+counter:stop+counter)) < .5 % plus or minus 0.5 relative to 0
                    found = start+counter + round(wind/2); % take the mid point of the window
                else
                    counter = counter + 1;
                end
                if i == length(dvdtpkloc) % if the last spike
                    if start + counter >= start+(30/(si/1000)) % search 30 ms after dvdtpk
                        break
                    end
                else % if other spikes
                    if start + counter >= dvdtmin(i+1,2)
                        break
                    end
                end
            end
            if isempty(found)
                warning('could not find dvdt1 = 0 so fAHP set at minimum dvdt')
                %             error('No fast AHP found in dvdt1. Try changing limits')
                FastAHP(i,1) = data(dvdtmin(i,2));
                FastAHP(i,2) = dvdtmin(i,2);
            else
                %             warning('fAHP set to dvdt1 = 0')
                FastAHP(i,1) = data(found);
                FastAHP(i,2) = found;
            end
        else
            FastAHP(i,1) = NaN;
            FastAHP(i,2) = NaN;
        end
    end


    % 
    % figure, plot(dvdt1v2)
    % hold on
    % plot(1:length(dvdt1v2),dvdt1v2,'b',FastAHP(:,2),dvdt1v2(FastAHP(:,2)),'m*')
    % ylim([-10 10])
    % xlim([25200 26500])
    %  
    % figure,
    % plot(1:length(data),data,'b',FastAHP(:,2),data(FastAHP(:,2)),'m*')
    % ylim([-70 30])
    % xlim([25200 26500])
end

