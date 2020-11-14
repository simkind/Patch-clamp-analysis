function [Results] = IVanalysis(abffile,graph_on,start,stop,xminmax,channelidx,currentidx)
    if nargin ~= 7
        error('Not enough input arguments')
    end
    [~,filename,~] = fileparts(abffile);
    [d,si,h]=abfload(abffile); 
    numsweeps = size(d,3); % number of sweeps
    
    Results.numsweeps = numsweeps;
    Results.Data = NaN(numsweeps,size(d,1));
    Results.SI = si;
    %% For each sweep
    for sweep = 1:numsweeps
        data = [];
        current = [];
        data = d(:,channelidx,sweep);
        current = d(:,currentidx,sweep);
%         sweepdata(sweep).data = data;
        timemes = 1:length(data)*(si/1000);
        Results.Data(sweep,:) = data;
        %% Get baseline data
        bl = mean(data(start:stop,1));
        Results.Baseline(sweep,1) = bl;
        %% Find Steady State
        ss_start = 650/(si/1000)+1;%changed from 500 to 650ms 5/12/20 D.S. steady state 150ms
        ss = mean(data(ss_start:ss_start+(150/(si/1000))));
        steadystate = ss - bl;
        Results.steadystate(sweep,1) = steadystate;

        %% Get Current
        curr = mean(current(ss_start:ss_start+(150/(si/1000))));
        blcurr = mean(current(start:stop));
        Results.current(sweep,1) = curr - blcurr;
        
        %% Find Sag
        win = 500/(si/1000);% 200ms converted to points. changed to 500ms to cover full iv since 200 not long enough D.S. 5/13/20
        [minpoint, idx]= min(data(stop+1:stop+win));
        idx = idx+stop;
        sag = ss - minpoint;     
        Results.SAG(sweep,1) = sag;
        Results.Min_Point_Amplitude(sweep,1) = minpoint;
        Results.Min_Point_idx(sweep,1) = idx;
        Results.Min_Point_Time(sweep,1) = idx*(si/1000);
        %% Graph
        if graph_on == 1
            f = figure;
            plot(data)
            yminmax = get(gca,'ylim');
            blline = zeros(1,length(data));
            blline(:) = bl;
            ssline = zeros(1,length(data));
            ssline(:) = ss;
            pkline = zeros(1,length(data));
            pkline(:) = minpoint;
            x = zeros(1,length(data));
            x(1,idx) = min(get(gca,'ylim'));     
            xx = zeros(1,length(data));
            xx(1,stop+1) = min(get(gca,'ylim')); 
            xx(1,stop+win) = min(get(gca,'ylim'));
            xx(1,ss_start)= min(get(gca,'ylim'));
            xx(1,ss_start+(150/(si/1000)) )= min(get(gca,'ylim'));
            figure(f)
            hold on
            plot(blline)
            plot(ssline,'c')
            plot(pkline,'r')
            bar(x,'edgecolor','r','facecolor','r')
            bar(xx,'edgecolor','b','facecolor','b')
            xlim(xminmax)
            ylim(yminmax)
            xlabel(sprintf('Points (multiply by %g for ms)',si/1000 ))
            ylabel('Volts')
            title(sprintf('Sweep %g File:%s',sweep,filename))
        end

    end
    
    %% Linear Fit and Graph
    % find all data that is below -20pA current
    Results.I = Results.current(Results.current < -20);
    Results.V = Results.steadystate(Results.current < -20);
    %
    %%% 4/4/16 Ann and Dina added if statement below:
    % if no current was recorded, don't try to calculate input resistance
    if ~isempty(Results.I) && ~isempty(Results.V)
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
        Results.Slope = m;
        Results.Intercept = b;
        Results.Equation = text;
        if graph_on == 1
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
        end
    else
        Results.Slope = NaN;
        Results.Intercept = NaN;
        Results.Equation = NaN;
    end
end