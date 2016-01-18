function makeplot(hObject,event,x,hplot)
n = get(hObject,'Value');
set(hplot,'ydata',x.^n);
drawnow;