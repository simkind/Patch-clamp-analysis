function [result] = selectAHP1secmethod()
    choice = questdlg('Select method of calculating 1sec AHP',...
        'Select 1sec AHP Method',...
        'Input Last Stimulus Onset','Use Last Current Step',...
        'Input Last Stimulus Onset') ;
    if strcmp(choice,'') 
        error('Method for calculating 1sec AHP not selected')
    end
    
    switch choice
        case 'Input Last Stimulus Onset'
            title_text = 'Time of last stimulus onset (ms)';
            onset = str2double(inputdlg({'Enter time of last stimulus onset (ms):'},...
                title_text,[1,length(title_text)+25])); % input will be in ms
            result(1,1) = 1;
            result(2,1) = onset;
        case 'Use Last Current Step'
            result(1,1) = 2;
            result(2,1) = NaN;
    end
    
    
end