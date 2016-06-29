% make an instance of the class corresponding to the VNA
VNA = deviceDrivers.AgilentE8363C();

%Connect using the IP adress (find the IP on the VNA LAN menu). 
%if instrumentis using GPIB replace ip address with gpib addess
%agrument must be a string
VNA.connect('140.247.189.158')

%initialize VNA
%if you place the VNA in manual mode it will only measure when you send a
%trigger.
VNA.trigger_source = 'manual';

%grab the frequency points
freq = VNA.getX;

%trigger the measurement and grab the data.
%this function only grabs the current selected measurement
VNA.trigger;
traces = single(VNA.getSingleTrace());
