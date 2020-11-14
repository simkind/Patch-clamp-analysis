% Results should be struct containing sweeps

function [Results] = save_IVanalysis(Results,filename)
%     [Results] = bracket2nan(Results); % convert empty brackets into NaN
    
    label = {'ABF File','Sweep','Baseline (mV)','Min Peak Amplitude (mV)','Min Peak Time (ms)',...
        'Steady State (mV)', 'SAG (mV)',' Current (pA)'};
    writethistemp = NaN(Results.numsweeps, 7);
    writethistemp(:,1) = 1:Results.numsweeps;
    writethistemp(:,2) = Results.Baseline;
    writethistemp(:,3) = Results.Min_Point_Amplitude;
    writethistemp(:,4) = Results.Min_Point_Time;
    writethistemp(:,5) = Results.steadystate;
    writethistemp(:,6) = Results.SAG;
    writethistemp(:,7) = Results.current;
    fnames = num2cell(NaN(Results.numsweeps,1));
    fnames(:) = cellstr(filename);
    writethis = [fnames, num2cell(writethistemp)];
    equations = num2cell(NaN(3,size(writethis,2)));
    equations(2,1) = {'Slope'};
    equations(2,2) = {'Intercept'};
    equations(3,1) = num2cell(Results.Slope);
    equations(3,2) = num2cell(Results.Intercept);
    
    writethiswithlabel = [label; writethis; equations];

    Table = writethiswithlabel;
    xlswrite(sprintf('%s IV.xlsx',filename),writethiswithlabel)
    save(sprintf('%s IV.mat',filename),'Results','Table')
end