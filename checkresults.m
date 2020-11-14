function [] = checkresults()
    files = uipickfiles('Prompt','Select .mat files from ephysanalysis');
    if isempty(files)
        error('Files not specified') % would happen if you hit 'done' without specifying files
    end
    if isnumeric(files)
        error('Files not specified') % would happen if you hit cancel button
    end
    %%
    for f = 1:length(files)
        load(char(files(f)))
        [~,filename,~] = fileparts(char(files(f)));
        if ~exist('Results','var')
            error('Could not find variable "Results." Check input file.')
        end
        
        FIELDS = fields(Results); % for IV analysis
        if ismember('Equation',FIELDS) % only true for IV analysis
            x = Results.I;
            y = Results.V;
            xmm = round(max(abs(x)));
            ymm = round(max(abs(y)));
            % Set up fittype and options.
            ft = fittype( 'poly1' );
            opts = fitoptions( ft );
            opts.Lower = [-Inf -Inf];
            opts.Upper = [Inf Inf];
            % Fit model to data.
            [fitresult, gof] = fit( x, y, ft, opts );
            coeffvals = coeffvalues(fitresult);
            m = coeffvals(1,1);
            b = coeffvals(1,2);
            text = sprintf('%g*x + %g',m,b);
            figure, scatter(x,y,'filled')
            hold on
            h = plot( fitresult, x, y );
            legend( h, 'V vs. I', 'Linear Fit', 'Location', 'NorthEast' );  
            xlim([-xmm xmm])
            ylim([-ymm ymm])
            xlabel('Current (pA)');
            ylabel('Voltage (mV)');
            axescenter
            set(gcf,'toolbar','figure')
            uicontrol('Style','text','Position',[100 350 150 20],'String',text)
            legend('off')
            title(sprintf('File:%s',filename))
        else
            for sweep = 1:length(Results)
                FIELDS = fields(Results(sweep));          
                data = Results(sweep).data;
                si = Results(sweep).SI;

                A = {'peak_idx','peak_amplitudes','threshold_index','threshold_amplitude','FastAHP_Time','FastAHP_Voltage'};
                B = {'peak_idx','peak_amplitudes','threshold_index','threshold_amplitude','FastAHP_Time','FastAHP_Voltage','AHPstart_time',...
                    'baseline_potential','AHPend_time','AHPpeak_negative_idx','Tau_time','Tau_amplitude'};
                C = {'AHPstart_time','baseline_potential','AHPend_time','Tau_time','Tau_amplitude'};
                D = {'peak_idx','peak_amplitudes','threshold_index','threshold_amplitude','FastAHP_Time','FastAHP_Voltage','AHPstart_time',...
                    'baseline_potential','AHPend_time','AHPpeak_negative_idx','Tau_time','Tau_amplitude','ADPpeak_idx','ADPend_time','ADPpeak_amplitude'};

                if length(unique(ismember(A,FIELDS))) == 1 && ~ismember('Tau_time',FIELDS) % for accommodation
                    loc = Results(sweep).peak_idx;
                    pks = Results(sweep).peak_amplitudes;
                    thresholdidx = Results(sweep).threshold_index;
                    thresholdamp = Results(sweep).threshold_amplitude;
                    FAHPidx = Results(sweep).FastAHP_Time/(si/1000);
%                     FAHPidx = str2double(sprintf('%16.f',FAHPidx));
                    FAHPamp = Results(sweep).FastAHP_Voltage;

                    f = figure;
                    zoomplot(data,(si/1000));
                    hold on
                    plot(1:length(data),data,'b',loc,pks,'r*')
                    plot(1:length(data),data,'b',thresholdidx,thresholdamp,'m*')
                    plot(FAHPidx,FAHPamp,'g.')
                    xlabel('Time (ms)')
                    ylabel('Voltage (mV)')
                    title(sprintf('Sweep %g File:%s',sweep,filename))
                    xlim([0 length(data)])                    
                elseif length(unique(ismember(B,FIELDS))) == 1  && ismember('Tau_time',FIELDS) && ~ismember('ADPpeak_idx',FIELDS) % for full AHP
                    loc = Results(sweep).peak_idx;
                    pks = Results(sweep).peak_amplitudes;
                    thresholdidx = Results(sweep).threshold_index;
                    thresholdamp = Results(sweep).threshold_amplitude;
                    FAHPidx = Results(sweep).FastAHP_Time/(si/1000);
%                     FAHPidx = str2double(sprintf('%16.f',FAHPidx));
                    FAHPamp = Results(sweep).FastAHP_Voltage;
                    AHPstart_idx = Results(sweep).AHPstart_time/(si/1000);
                    AHPstart_idx = str2double(sprintf('%16.f',AHPstart_idx));
                    bl = Results(sweep).baseline_potential;
                    AHPend_idx = Results(sweep).AHPend_time/(si/1000);
                    AHPend_idx = str2double(sprintf('%16.f',AHPend_idx));
                    AHPpeak_idx = Results(sweep).AHPpeak_negative_idx;
                    AHPtau_idx = Results(sweep).Tau_time/(si/1000);
                    AHPtau_idx = str2double(sprintf('%16.f',AHPtau_idx));
                    AHPtau_amp = Results(sweep).Tau_amplitude;

                    f = figure;
                    zoomplot(data,(si/1000));
                    hold on
                    plot(1:length(data),data,'b',loc,pks,'r*')
                    plot(1:length(data),data,'b',thresholdidx,thresholdamp,'m*')
                    plot(FAHPidx,FAHPamp,'g.')
                    xlabel('Time (ms)')
                    ylabel('Voltage (mV)')
                    if sweep == length(Results)
                        title(sprintf('Mean Sweep File:%s',filename))     
                    else
                        title(sprintf('Sweep %g File:%s',sweep,filename))     
                    end
                    blline = zeros(1,length(data));
                    blline(:) = Results(sweep).baseline_potential;
                    xx = zeros(1,length(data));
                    xx(1,AHPstart_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    blline = zeros(1,length(data));
                    blline(:) = bl;
                    xx = zeros(1,length(data));
                    xx(1,AHPend_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    xx = zeros(1,length(data));
                    xx(1,AHPpeak_idx) = min(get(gca,'ylim')); % -100;
                    bar(xx,'edgecolor','k','facecolor','k')
                    blline = zeros(1,length(data));
                    blline(:) = AHPtau_amp;
                    xx = zeros(1,length(data));
                    xx(1,AHPtau_idx) = min(get(gca,'ylim'));%  -100;
                    plot(blline,'r')
                    bar(xx,'edgecolor','r','facecolor','r')
                    xlim([0 length(data)])
                elseif length(unique(ismember(C,FIELDS))) == 1   && ~ismember('peak_idx',FIELDS) % for AHP only
                    AHPstart_idx = Results(sweep).AHPstart_time/(si/1000);
                    AHPstart_idx = str2double(sprintf('%16.f',AHPstart_idx));
                    bl = Results(sweep).baseline_potential;
                    AHPend_idx = Results(sweep).AHPend_time/(si/1000);
                    AHPend_idx = str2double(sprintf('%16.f',AHPend_idx));
                    AHPpeak_idx = Results(sweep).AHPpeak_negative_time;
                    AHPpeak_idx = str2double(sprintf('%16.f',AHPpeak_idx));
                    AHPtau_idx = Results(sweep).Tau_time/(si/1000);
                    AHPtau_idx = str2double(sprintf('%16.f',AHPtau_idx));
                    AHPtau_amp = Results(sweep).Tau_amplitude;

                    f = figure;
                    zoomplot(data,(si/1000));
                    hold on
                    xlabel('Time (ms)')
                    ylabel('Voltage (mV)')
                    if sweep == length(Results)
                        title(sprintf('Mean Sweep File:%s',filename))     
                    else
                        title(sprintf('Sweep %g File:%s',sweep,filename))     
                    end      
                    blline = zeros(1,length(data));
                    blline(:) = Results(sweep).baseline_potential;
                    xx = zeros(1,length(data));
                    xx(1,AHPstart_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    blline = zeros(1,length(data));
                    blline(:) = bl;
                    xx = zeros(1,length(data));
                    xx(1,AHPend_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    xx = zeros(1,length(data));
                    xx(1,AHPpeak_idx) = min(get(gca,'ylim')); % -100;
                    bar(xx,'edgecolor','k','facecolor','k')
                    blline = zeros(1,length(data));
                    blline(:) = AHPtau_amp;
                    xx = zeros(1,length(data));
                    xx(1,AHPtau_idx) = min(get(gca,'ylim'));%  -100;
                    plot(blline,'r')
                    bar(xx,'edgecolor','r','facecolor','r')
                    xlim([0 length(data)])
            elseif length(unique(ismember(D,FIELDS))) == 1   % for AP analysis
                    loc = Results(sweep).peak_idx;
                    pks = Results(sweep).peak_amplitudes;
                    thresholdidx = Results(sweep).threshold_index;
                    thresholdamp = Results(sweep).threshold_amplitude;
                    FAHPidx = Results(sweep).FastAHP_Time/(si/1000);
%                     FastAHP_Time = str2double(sprintf('%16.f',FastAHP_Time))
                    FAHPamp = Results(sweep).FastAHP_Voltage;
                    AHPstart_idx = Results(sweep).AHPstart_time/(si/1000);
                    AHPstart_idx = str2double(sprintf('%16.f',AHPstart_idx));
                    bl = Results(sweep).baseline_potential;
                    AHPend_idx = Results(sweep).AHPend_time/(si/1000);
                    AHPend_idx = str2double(sprintf('%16.f',AHPend_idx));
                    AHPpeak_idx = Results(sweep).AHPpeak_negative_idx;
                    AHPtau_idx = Results(sweep).Tau_time/(si/1000);
                    AHPtau_idx = str2double(sprintf('%16.f',AHPtau_idx));
                    AHPtau_amp = Results(sweep).Tau_amplitude;
                    ADPend_idx = Results(sweep).ADPend_time/(si/1000);
                    ADPend_idx = str2double(sprintf('%16.f',ADPend_idx));
                    ADPpeak_idx = Results(sweep).ADPpeak_idx;
                    ADPpeak_amp = Results(sweep).ADPpeak_amplitude;

                    f = figure;
                    zoomplot(data,(si/1000));
                    hold on
                    plot(1:length(data),data,'b',loc,pks,'r*')
                    plot(1:length(data),data,'b',thresholdidx,thresholdamp,'m*')
                    plot(FAHPidx,FAHPamp,'g.')
                    xlabel('Time (ms)')
                    ylabel('Voltage (mV)')
                    title(sprintf('Sweep %g File:%s',sweep,filename))               
                    blline = zeros(1,length(data));
                    blline(:) = Results(sweep).baseline_potential;
                    xx = zeros(1,length(data));
                    xx(1,AHPstart_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    blline = zeros(1,length(data));
                    blline(:) = bl;
                    xx = zeros(1,length(data));
                    xx(1,AHPend_idx) = min(get(gca,'ylim')); %-100;
                    plot(blline)
                    bar(xx)
                    xx = zeros(1,length(data));
                    xx(1,AHPpeak_idx) = min(get(gca,'ylim')); % -100;
                    bar(xx,'edgecolor','k','facecolor','k')
                    blline = zeros(1,length(data));
                    blline(:) = AHPtau_amp;
                    xx = zeros(1,length(data));
                    xx(1,AHPtau_idx) = min(get(gca,'ylim'));%  -100;
                    plot(blline,'r')
                    bar(xx,'edgecolor','r','facecolor','r')
                    ADPpeakline = zeros(1,length(data));
                    ADPpeakline(:) = ADPpeak_amp;
                    xx = zeros(1,length(data));
                    xx(1,ADPpeak_idx) = min(get(gca,'ylim')); %-100; 
                    plot(ADPpeakline,'c')
                    bar(xx,'edgecolor','c','facecolor','c')
                    xlim([0 length(data)])
                else
                    error('Unknown analysis output')
                end
            end
        end
    end
end
%             elseif length(unique(ismember({'peak_idx','peak_amplitudes','threshold_index','threshold_amplitude','FastAHP_Time','FastAHP_Voltage'},FIELDS))) == 1