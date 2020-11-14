function [output] = dinacombinexlsoutput(savename)
    if nargin < 1
        error('No savename specified')
    end

    files = uipickfiles('Prompt','Select excel files from ephys analysis function');
    if isempty(files)
        error('File(s) not specified')
    end
    files = files';
    % Check if input files are excel
    for i = 1:length(files)
        [status] = xlsfinfo(char(files(i)));
        type(i,1) = cellstr(status);
    end
    if length(unique(type)) ~= 1
        error('Selected file types are not consistent. Check to make sure all files are excel files')
    end
    
    %% Get filenames
    for i = 1:length(files)
        [~, a, ~] = fileparts(char(files(i)));
        fnames(i,1) = cellstr(a);
    end
    [pre, post] = strtok(fnames,' ');
    
    if length(unique(post)) ~= 1
        error('Different analyses detected. Make sure selected files are from same analysis type')
    end
    %% Split filename by year, month, day, file#
    for i = 1:length(pre)
        date{i,1} = pre{i,1}(1:5);
    end
    unsorteddate = date;
    date = sort(date);
    %% Specify save directory
    savein = uigetdir('C:\Users','Save data in');
	cd(savein)
    
    %% find indices with same date
    [C, ~, ~] = unique(date);
    numdays = length(C);
    filestouse = [];
    output = [];
    for n = 1:numdays;
        index = strcmp(unsorteddate,C(n));
        sheet = C(n);
        filestouse = files(index);
        filestouse = sort(filestouse); % sort order of files
        %% Import data and figure out how many max columns
        numrows = [];
        numcolumns = [];
        raw = [];
        for i = 1:length(filestouse)       
            [~,~,raw(i).raw] = xlsread(char(filestouse(i)));      
            [numrows(i,1), numcolumns(i,1)] = size(raw(i).raw);
        end
        maxcolumns = max(numcolumns);
        totalrows = sum(numrows)+(2*length(filestouse)-1);
        %% Prep output
        output = num2cell(NaN(totalrows,maxcolumns));

        startrow = 1;
        for i = 1:length(raw)
            stopcolumn = numcolumns(i);
            stoprow = startrow + numrows(i)-1;
            output(startrow:stoprow,1:stopcolumn) = raw(i).raw;
            startrow = startrow + numrows(i) + 2;
        end
        %% Write excel   
       xlswrite(sprintf('%s.xlsx',savename),output,char(sheet))
    end
    deletesheet1(sprintf('%s.xlsx',savename));
end
    
    
        