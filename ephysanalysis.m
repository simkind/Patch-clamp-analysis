
function [Output] = ephysanalysis(disterhoft,same_baseline,graph_on)
%% Check input arguments
    if nargin < 1
        error('Variable "Disterhoft" undefined')
    elseif nargin < 2
        same_baseline = 0;
        graph_on = 1;
    elseif nargin < 3
        graph_on = 1;
    end
    if same_baseline == 0 || same_baseline == 1
    else
        error('Invalid input argument for variable "same_baseline"')
    end
    if graph_on == 0 || graph_on == 1
    else
        error('Invalid input argument for variable "graph_on"')
    end
%% Select files
    files = uipickfiles('Prompt','Select abf files');
    if isempty(files)
        error('Files not specified') % would happen if you hit 'done' without specifying files
    end
    if isnumeric(files)
        error('Files not specified') % would happen if you hit cancel button
    end
%% Disterhoft vs New Lab
    if disterhoft == 0 || disterhoft == 1
    else
        error('Invalid input argument for variable "graph_on"')
    end
    if disterhoft == 1 % if john disterhoft's rig
        channelidx = 2;
        currentidx = 1;
    elseif disterhoft == 0 % if evangelos' rig
        channelidx = 1;
        currentidx = 2;
    end

%% Select analysis
    str = {'Full AHP analysis', 'Post-Burst AHP only','Accommodation', 'I/V Analysis', 'AP Analysis','Drug Spikes','New Style Accommodation','Accommodation with PSP','AreaUnderCurve Spikes','Burstanalysis'};
    [selection,~] = listdlg('PromptString','Select analysis method','SelectionMode','single','ListString',str);
    if isempty(selection)
        error('Analysis not chosen')
    end
%% Perform Analysis
    if same_baseline == 1
        if selection == 1
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        AHP1schoice = selectAHP1secmethod;
        elseif selection == 2
            [start,stop,xminmax] = specifybaselineonce(char(files(1)),channelidx,0); % Specify baseline intervals + window (will use the first sweep of first file)
       AHP1schoice = selectAHP1secmethod;
        elseif selection == 3
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        elseif selection == 4 
            [start,stop,xminmax] = specifybaselineonce(char(files(1)),channelidx,0); % Specify baseline intervals + window (will use the first sweep of first file)
        elseif selection == 5
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        elseif selection == 6
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            ISIthreshold = str2double(inputdlg('Enter minimum ISI interval:','ISI',1,{'4'})); 
        elseif selection == 7
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        elseif selection == 8
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        elseif selection == 9
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        elseif selection == 10
            [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(1)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
        end
    end

    for i = 1:size(files,2)
        [path,filename,~] = fileparts(char(files(i)));                
        if selection == 1
            if same_baseline == 0
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
                AHP1schoice = selectAHP1secmethod;
            end
            [Results] = AHPanalysis(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,AHP1schoice,channelidx,currentidx);
            cd(path)
            [Results] = save_AHPanalysis(Results,filename);
        elseif selection == 2
            if same_baseline == 0
                [start,stop,xminmax] = specifybaselineonce(char(files(i)),channelidx,0); % Specify baseline intervals + window (will use the first sweep of first file)
                AHP1schoice = selectAHP1secmethod;
            end
            [Results] = PostBurstAHPonly(char(files(i)),graph_on,start,stop,xminmax,AHP1schoice,channelidx,currentidx);
            cd(path)
            [Results] = save_PostBurstAHPonly(Results,filename);
        elseif selection == 3
            if same_baseline == 0
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results] = accommodation(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,channelidx, currentidx);
            cd(path)
            [Results] = save_accommodation(Results,filename);
        elseif selection == 4 
            if same_baseline == 0
                [start,stop,xminmax] = specifybaselineonce(char(files(i)),channelidx,0); % Specify baseline intervals + window (will use the first sweep of first file)
            end
            [Results] = IVanalysis(char(files(i)),graph_on,start,stop,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_IVanalysis(Results,filename);
        elseif selection == 5
            if same_baseline == 0 
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results] = APanalysis(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_APanalysis(Results,filename);
        elseif selection == 6
            if same_baseline == 0
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
                ISIthreshold = str2double(inputdlg('Enter minimum ISI interval (ms):','ISI',1,{'4'})); 
            end
            [Results] = drugspikes(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,ISIthreshold,channelidx,currentidx);
            cd(path)
            [Results] = save_drugspikes(Results,filename);
        elseif selection == 7
            if same_baseline == 0
                [start,stop,xminmax] = specifybaselineonce(char(files(i)),channelidx,0); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results,accommresult] = newstyleaccom(char(files(i)),graph_on,start,stop,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_newstyleaccom(Results,accommresult,filename);
        elseif selection == 8
            if same_baseline == 0
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results] = accommodationPSP(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_accommodationPSP(Results,filename);
        elseif selection == 9
            if same_baseline == 0 
                [start,stop,xminmax,dvdtthreshold] = specifybaselineonce(char(files(i)),channelidx,1); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results] = AUCanalysis(char(files(i)),graph_on,start,stop,dvdtthreshold,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_AUC(Results,filename);
       elseif selection == 10
            if same_baseline == 0
                [start,stop,xminmax] = specifybaselineonce(char(files(i)),channelidx,0); % Specify baseline intervals + dvdtthreshold + window (will use the first sweep of first file)
            end
            [Results,accommresult] = newstyleaccom(char(files(i)),graph_on,start,stop,xminmax,channelidx,currentidx);
            cd(path)
            [Results] = save_Bursts(Results,accommresult,filename);
        end
        Output(i,1).Results = Results;
    end
end


