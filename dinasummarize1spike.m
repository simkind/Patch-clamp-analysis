function [Summary] = dinasummarize1spike
    files = uipickfiles('Prompt','Select combined excel files from dinacombinexlsoutput');
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
    %%
    clmn = 2:14; % the columns of "raw" where you want to keep the data
    maxnumspike = 1;
    blthresh1 = -65;
    blthresh2 = -91;
    tolerance = 5;
    %%
%     label = [{'ABF File'},txt(1,4:13), txt(1,4:13),txt(1,4:13),txt(1,4:13)]
    spikelabel = [];
    for d = 1:4
        xx = num2cell(NaN(1,10));
        if d == 1
            xx(:) = {'Single BL60'};
        elseif d==2
            xx(:) = {'Single BL70'};
        elseif d==3
            xx(:) = {'Doublet BL60'};
        elseif d==4
            xx(:) = {'Doublet BL70'};
        end  
        spikelabel = [spikelabel, xx];
    end
    spikelabel = [{'NaN'},spikelabel];

    
    %%
    for i = 1:length(files) % for each combined file
        [~,sheet] = xlsfinfo(char(files(i)));
        [~,filename,~] = fileparts(char(files(i)));
        if ismember('Summary',sheet)
            error('File %s already contains a "Summary" sheet. Delete "Summary" sheet and try again',filename)
        end
            
        Results = [];
        for s = 1:length(sheet) % for each sheet
            ResultsLabel = [];
            [~, txt, raw] = xlsread(char(files(i)),char(sheet(s)));
            label = [{'ABF File'},txt(1,4:13), txt(1,4:13),txt(1,4:13),txt(1,4:13)];
            ResultsLabel = [spikelabel; label];
            % figure out which row is start of new abffile
            [abfstart_idx,~] = find(strcmp(txt,'Sweep'));
            abfstart_idx = abfstart_idx + 1; % add 1 so the next row is the actual start
            % figure out which row abffile ends
%             [abfend_idx,~] = find(strcmp(txt,'Mean Sweep'));
            abfend_idx_temp = abfstart_idx - 4; % subtract 4 b/c size(header,1) + size(NAN,1) = 3
            abfend_idx = [abfend_idx_temp(abfend_idx_temp > 0); size(raw,1) ]; % 

            sheetresults = [];
            for abf = 1:length(abfstart_idx) % for each abffile

%                 vector = [];
                abffile = raw(abfstart_idx(abf),1);
                data = [];
                data = cell2mat(raw(abfstart_idx(abf):abfend_idx(abf),clmn));
                numsweep = max(data(:,1));
                %% Split data by baseline
                bl1 = data(data(:,3) <= blthresh1+tolerance & data(:,3) >= blthresh1-tolerance,:);
                bl2 = data(data(:,3) <= blthresh2+tolerance & data(:,3) >= blthresh2-tolerance,:);
                %% Split by doublet or singlet
                % for 1st baseline
                multispikeidx = find(~isnan(bl1(:,13)));
                doubleidx = multispikeidx(bl1(multispikeidx,13) < 6) ;% <----- 6ms ISI for doublet
                doubletidx = sort([doubleidx; doubleidx-1]);
                bl1doublet = bl1(doubletidx,:);
                bl1(doubletidx,:) = [];
                % for 2nd baseline
                multispikeidx = find(~isnan(bl2(:,13)));
                doubleidx = multispikeidx(bl2(multispikeidx,13) < 6) ;% <----- 6ms ISI for doublet
                doubletidx = sort([doubleidx; doubleidx-1]);
                bl2doublet = bl2(doubletidx,:);
                bl2(doubletidx,:) = [];
                datatouse(1).data = bl1;
                datatouse(2).data = bl2;
                datatouse(3).data = bl1doublet;
                datatouse(4).data = bl2doublet;
                
                %%
                fourgroupvector = [abffile];
                for d = 1:size(datatouse,2)
                    vector = [];
                    data2 = [];
                    data2 = datatouse(d).data;
                    for spike = 1:maxnumspike % for first spikes
                        spikeidx = data2(:,2)==spike;
                        spikedata.data = data2(spikeidx,:);
                    end
                    spikedata.meanspikedata = nanmean(spikedata.data(:,3:end-1),1);
                    spikedata.abffile = abffile;

                    
                    vector = [num2cell(spikedata.meanspikedata)];
                    fourgroupvector = [fourgroupvector, vector];
                end
                
    %             output(i).sheet(s).file(abf).spikedata = spikedata(:); % one big struct output
                sheetdata(s).file(abf).spikedata = spikedata(:);
                sheetresults = [sheetresults; fourgroupvector];
            end
            Results = [Results; sheetresults];
        end
        
        ResultsLabel = [ResultsLabel; Results];
        Summary(i).Results = ResultsLabel;
        Summary(i).Data = sheetdata;
        Summary(i).sheet = sheet;

        %% Write excel
        xlswrite(char(files(i)),ResultsLabel,'Summary')
    end
end
            