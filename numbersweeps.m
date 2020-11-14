function [numsweeps] = numbersweeps(abffile)
    [d,~,~]=abfload(abffile); 
    numsweeps = size(d,3);
end