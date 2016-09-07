function varargout = HeFillControl(varargin)
% HEFILLCONTROL MATLAB code for HeFillControl.fig
%      HEFILLCONTROL, by itself, creates a new HEFILLCONTROL or raises the existing
%      singleton*.
%
%      H = HEFILLCONTROL returns the handle to a new HEFILLCONTROL or the handle to
%      the existing singleton*.
%
%      HEFILLCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HEFILLCONTROL.M with the given input arguments.
%
%      HEFILLCONTROL('Property','Value',...) creates a new HEFILLCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HeFillControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HeFillControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HeFillControl

% Last Modified by GUIDE v2.5 05-Sep-2016 15:59:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @HeFillControl_OpeningFcn, ...
    'gui_OutputFcn',  @HeFillControl_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before HeFillControl is made visible.
function HeFillControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HeFillControl (see VARARGIN)

% Choose default command line output for HeFillControl
handles.output = hObject;

%create timer to update helium level
handles.timer = timer('Name','heliumLevelTimer', ...
    'Period',60, ...
    'StartDelay',0, ...
    'TasksToExecute',inf, ...
    'ExecutionMode','fixedSpacing', ...
    'TimerFcn',{@timerCallback,hObject});

% Update handles structure
guidata(hObject, handles);

% start the timer
start(handles.timer);


% UIWAIT makes HeFillControl wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = HeFillControl_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function heliumLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'String',sprintf('%g%%\n',returnHeliumLevel));

% --- Executes on button press in pauseNow.
function pauseNow_Callback(hObject, eventdata, handles)
% hObject    handle to pauseNow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'String','F5 to resume');
eval('keyboard');
set(hObject,'String','Pause now');


% --- Executes on button press in pauseAtZero.
function pauseAtZero_Callback(hObject, eventdata, handles)
% hObject    handle to pauseAtZero (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pauseAtZero
button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
    set(hObject,'String','Pausing @ 0T');
elseif button_state == get(hObject,'Min')
    set(hObject,'String','Pause @ 0T');
end
%use h = findobj(guiHandle,'tag','pauseAtZero') to get this handle
%then h.value to find flag value


% --- Executes on button press in emergencyFill.
function emergencyFill_Callback(hObject, eventdata, handles)
% hObject    handle to emergencyFill (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of emergencyFill
button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
    set(hObject,'String','Ramping to 0T');
elseif button_state == get(hObject,'Min')
    set(hObject,'String','Emergency Fill');
end
%use h = findobj(guiHandle,'tag','emergencyFill') to get this handle
%then h.value to find flag value

function updateHelium(hObject, eventdata, handles)
set(handles.heliumLevel,'String',sprintf('%g%%\n',returnHeliumLevel))
guidata(hObject,handles);

function timerCallback(hTimer, eventdata, hFigure)
handles = guidata(hFigure);
set(handles.heliumLevel,'String',sprintf('%g%%\n',returnHeliumLevel));

guidata(hFigure,handles);

% --- Executes on button press in updateNow.
function updateNow_Callback(hObject, eventdata, handles)
% hObject    handle to updateNow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.heliumLevel,'String',sprintf('%g%%\n',returnHeliumLevel))
guidata(hObject,handles);

% --- Executes on button press in updateNow.
function txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to updateNow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
