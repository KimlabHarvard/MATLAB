fn= @(a, b, c, x) c+a*exp(x-b);

xdata=[1:.1:10];
ydata=2.5.^(xdata-4)+7;
%plot(xdata,ydata,'*',xdata,fn(.6,4,xdata))
f11=fit(xdata',ydata',fn,'StartPoint',[.6 4 6])
plot(f11,xdata,ydata)
