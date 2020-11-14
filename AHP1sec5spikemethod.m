function [AHP1s_meanamplitude, AHP1s_time, AHP1s_idx] = AHP1sec5spikemethod(data,si,last_stim_time)    
    onesec = 1000/(si/1000);
    AHP1s_idx = (last_stim_time/(si/1000)) + onesec;
    AHP1s_time = AHP1s_idx*(si/1000);
	AHP1s_meanamplitude = mean(data(AHP1s_idx-5:AHP1s_idx+5));
end