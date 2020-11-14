% function zoomplot(data,correction)
% % Listen to zoom events
% plot(data);
% set(gca,'xticklabel',get(gca,'xtick')*correction)
% h = zoom;
% 
% set(h,'ActionPostCallback',@mypostcallback);
% set(h,'Enable','on');
% 
% function mypostcallback(obj,evd)
% c = get(gca,'xtick')
% set(gca,'xticklabel',c*correction)
function zoomplot(data,correction)
plot(data);
A = get(gca);

set(gca,'xticklabel',A.XTick*correction)
h = zoom;
set(h,'ActionPostCallback',{@mypostcallback,correction});

function mypostcallback(obj,evd,correction)
B = get(gca);
newlim = B.XLim;
xticky = B.XTick;
newlabels = xticky*correction;
set(gca,'xticklabel',newlabels)