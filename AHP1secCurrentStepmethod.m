function [AHP1s_meanamplitude, AHP1s_time, AHP1s_idx] = AHP1secCurrentStepmethod(data,current,si)    


    dvdtcurrent = -1*diff(current); % inverse the dvdt
    maxdvdtcurrent = max(dvdtcurrent);
    dvdtcurrentthresh = maxdvdtcurrent / 4 ;
    [pp, ll] = findpeaks(dvdtcurrent,'minpeakheight',dvdtcurrentthresh,'minpeakdistance',1/(si/1000));
%     figure, plot(1:length(dvdtcurrent),dvdtcurrent,'b',ll,pp,'r*'); % In case you want to graph it 
    if isempty(pp)
        error('No current steps detected. Check file or change parameters')
    end
    laststep = ll(end);
    laststeppk = pp(end);
    found = [];
    window = 10; % points
    counter = 1;
    while isempty(found)
        windowmean = mean(dvdtcurrent(laststep+counter:laststep+counter+window-1));
        if windowmean < 0.5 && windowmean > -0.5;
            found = laststep+counter;
            break
        end
        counter = counter + 1;
        if counter+laststep >= length(dvdtcurrent-window)
            break
        end
    end
    if isempty(found)
        error('Could not find offset of last current step')
    end
%     figure, plot(1:length(dvdtcurrent),dvdtcurrent,'b',found,dvdtcurrent(found),'r*'); % plot last current step end with dvdt of current  
    figure, plot(1:length(current),current,'b',found,current(found),'r*'); % plot last current step end with current  
    idx = found;
    onesec = 1000/(si/1000);
    AHP1s_idx =  idx + onesec;
    AHP1s_time = AHP1s_idx*(si/1000);
	AHP1s_meanamplitude = mean(data(AHP1s_idx-5:AHP1s_idx+5));
end