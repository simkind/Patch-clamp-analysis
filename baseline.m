function [bl bl_std] = baseline(data,start,stop)
	bl = mean(data(start:stop,1));
    bl_std = std(data(start:stop,1));
end