function varargout = Main_MRratio_GUI(varargin)
% MAIN_MRRATIO_GUI MATLAB code for Main_MRratio_GUI.fig
%      MAIN_MRRATIO_GUI, by itself, creates a new MAIN_MRRATIO_GUI or raises the existing
%      singleton*.
%
%      H = MAIN_MRRATIO_GUI returns the handle to a new MAIN_MRRATIO_GUI or the handle to
%      the existing singleton*.
%
%      MAIN_MRRATIO_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN_MRRATIO_GUI.M with the given input arguments.
%
%      MAIN_MRRATIO_GUI('Property','Value',...) creates a new MAIN_MRRATIO_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Main_MRratio_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Main_MRratio_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Main_MRratio_GUI

% Last Modified by GUIDE v2.5 20-Dec-2017 13:02:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Main_MRratio_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Main_MRratio_GUI_OutputFcn, ...
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


% --- Executes just before Main_MRratio_GUI is made visible.
function Main_MRratio_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Main_MRratio_GUI (see VARARGIN)

% initialize parameters
handles.DAQSession1=daq.createSession('ni');
handles.DAQSession2=daq.createSession('ni');
handles.DAQ_RATE=10e3;
handles.File_Name='none.csv';
handles.Test_Channel='Row4';
handles.pre_Channel='NONE';
handles.Test_Column='Column4';
handles.Sine_Duration=60;
handles.Sine_Frequency=100;
handles.Positive_Field=50;
handles.Negative_Field=-50;
handles.Delay=1;
handles.Cycles=1;
handles.VB=0.1;
handles.RefreshRate=1;

% initialize control box
set(handles.popupmenu_column,'Value',4);
set(handles.popupmenu_row,'Value',4);
set(handles.popupmenu_sweep_cycles,'Value',1);
% initialize figures
cla(handles.axes_magnetic_field,'reset');
Title=sprintf('Applied Magnetic Field');
title(handles.axes_magnetic_field, Title, 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
xlabel(handles.axes_magnetic_field, 'Time [s]', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
ylabel(handles.axes_magnetic_field, 'Magnetic Field [Oe]', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
set(handles.axes_magnetic_field, 'Box', 'Off', 'TickDir', 'out', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow', 'XDir', 'normal');

cla(handles.axes_MR_ratio,'reset');
Title=sprintf('MR Ratio of Tested Sensor');
title(handles.axes_MR_ratio, Title, 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
xlabel(handles.axes_MR_ratio, 'Magnetic Field [Oe]', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
ylabel(handles.axes_MR_ratio, 'Sensor Resistance [KOhms]', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow');
set(handles.axes_MR_ratio, 'Box', 'Off', 'TickDir', 'out', 'FontSize', 12, 'FontWeight', 'Bold', 'FontName', 'Arial Narrow', 'XDir', 'normal');

% disable button "start" and "stop"
set(handles.pushbutton_start,'Enable','off');
set(handles.pushbutton_stop,'Enable','off');

% Choose default command line output for Main_MRratio_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Main_MRratio_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Main_MRratio_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_stop.
function pushbutton_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IsRunning;
set(handles.pushbutton_stop,'Enable','off');
IsRunning=0;
handles.DAQSession.stop();
disp('Measurement stopped by user!');
set(handles.test_information_text,'String', 'Measurement stopped by user!');
guidata(hObject, handles);

% --- Executes on button press in pushbutton_connect_daq.
function pushbutton_connect_daq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_connect_daq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Connect_DAQ(hObject,handles);
set(handles.pushbutton_start,'Enable','on');
if get(handles.checkbox_all,'Value')==false
    handles.pre_Channel=handles.Test_Channel;
else
    set(handles.popupmenu_row,'Value',4);
    set(handles.popupmenu_row,'Enable','off');
    handles.pre_Channel='All';
end
guidata(hObject, handles);

% --- Executes on button press in pushbutton_start.
function pushbutton_start_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IsRunning;
global file_id;
IsRunning=1;
set(handles.pushbutton_connect_daq,'Enable','off');
set(handles.pushbutton_start,'Enable','off');
set(handles.checkbox_save_data,'Enable','off');
set(handles.checkbox_save_figure,'Enable','off');
set(handles.checkbox_all,'Enable','off');
set(handles.edit_sine_frequency,'Enable','off');
set(handles.edit_sine_duration_time,'Enable','off');
set(handles.edit_maximum_positive_field,'Enable','off');
set(handles.edit_maximum_negative_field,'Enable','off');
set(handles.edit_delay,'Enable','off');
set(handles.popupmenu_column,'Enable','off');
set(handles.popupmenu_row,'Enable','off');
set(handles.popupmenu_sweep_cycles,'Enable','off');
set(handles.pushbutton_stop,'Enable','on');

if get(handles.checkbox_save_data,'Value')==true
    handles.File_Name=['MR_Ratio_Test' datestr(now,'_yyyy-mm-dd_HHMM') '.csv'];
    Write_Header(hObject, eventdata, handles);
    file_id= fopen(handles.File_Name,'a');
else
    file_id= 0;
end

% Start_Running(hObject, eventdata, handles);
Start_Running(hObject, eventdata, handles);

set(handles.pushbutton_connect_daq,'Enable','on');
set(handles.checkbox_save_data,'Enable','on');
set(handles.checkbox_save_figure,'Enable','on');
set(handles.checkbox_all,'Enable','on');
set(handles.edit_sine_frequency,'Enable','on');
set(handles.edit_sine_duration_time,'Enable','on');
set(handles.edit_maximum_positive_field,'Enable','on');
set(handles.edit_maximum_negative_field,'Enable','on');
set(handles.edit_delay,'Enable','on');
set(handles.popupmenu_column,'Enable','on');
set(handles.popupmenu_row,'Enable','on');
set(handles.popupmenu_sweep_cycles,'Enable','on');
set(handles.pushbutton_stop,'Enable','off');

IsRunning=0;
% close file
if file_id~=0
    fclose(file_id);
end
guidata(hObject, handles);

% --- Executes on selection change in popupmenu_column.
function popupmenu_column_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_column (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_column contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_column
    str = get(hObject,'String');
    val = get(hObject,'Value');
    handles.Test_Column=char(str(val));
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_column_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_column (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_column.
function popupmenu_row_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_column (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_column contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_column
    str = get(hObject,'String');
    val = get(hObject,'Value');
    handles.Test_Channel=char(str(val));
    guidata(hObject, handles);

    
% --- Executes during object creation, after setting all properties.
function popupmenu_row_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_column (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_save_data.
function checkbox_save_data_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_save_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_save_data



function edit_maximum_negative_field_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maximum_negative_field (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maximum_negative_field as text
%        str2double(get(hObject,'String')) returns contents of edit_maximum_negative_field as a double
Negative_Field=str2double(get(hObject,'String'));
if Negative_Field >= -100 && Negative_Field <= 0
    if rem(Negative_Field,1) == 0 ; % check if it is an integer
        handles.Negative_Field=Negative_Field;
        set(handles.pushbutton_connect_daq,'Enable','on');  
    else    
        handles.Negative_Field=-1;
        disp('            Warning: Negative_Field is not an integer, set Negative_Field to -1!!');
        set(handles.test_information_text,'String', '            Warning: Negative_Field has to be an integer !!');
        set(handles.pushbutton_connect_daq,'Enable','off');
    end  
else
    handles.Negative_Field=-1;
    disp('            Warning: Negative_Field>0 or Negative_Field<-100, set Negative_Field to -1!!');
    set(handles.test_information_text,'String', '            Warning: Negative_Field>0 or Negative_Field<-100 is not allowed !!');
    set(handles.pushbutton_connect_daq,'Enable','off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_maximum_negative_field_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maximum_negative_field (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_maximum_positive_field_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maximum_positive_field (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maximum_positive_field as text
%        str2double(get(hObject,'String')) returns contents of edit_maximum_positive_field as a double
Positive_Field=str2double(get(hObject,'String'));
if Positive_Field >= 0 && Positive_Field <= 100
    if rem(Positive_Field,1) == 0  % check if it is an integer
        handles.Positive_Field=Positive_Field;
        set(handles.pushbutton_connect_daq,'Enable','on');  
    else    
        handles.Positive_Field=1;
        disp('            Warning: Positive_Field is not an integer, set Positive_Field to 1!!');
        set(handles.test_information_text,'String', '            Warning: Positive_Field has to be an integer !!');
        set(handles.pushbutton_connect_daq,'Enable','off');
    end    
else
    handles.Positive_Field=1;
    disp('            Warning: Positive_Field>100 or Positive_Field<0, set Positive_Field to 1!!');
    set(handles.test_information_text,'String', '            Warning: Positive_Field>100 or Positive_Field<0 is not allowed !!');
    set(handles.pushbutton_connect_daq,'Enable','off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_maximum_positive_field_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maximum_positive_field (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_sine_frequency_Callback(hObject, eventdata, handles)
% hObject    handle to edit_sine_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sine_frequency as text
%        str2double(get(hObject,'String')) returns contents of edit_sine_frequency as a double
Sine_Frequency=str2double(get(hObject,'String'));
if Sine_Frequency >= 10 && Sine_Frequency <= 1000
    handles.Sine_Frequency=Sine_Frequency;
    set(handles.pushbutton_connect_daq,'Enable','on');  
else
    handles.Sine_Frequency=100;
    disp('            Warning: Sine_Frequency>1000 or Sine_Frequency<10, set Sine_Frequency to 100!!');
    set(handles.test_information_text,'String', '            Warning: Sine_Frequency>1000 or Sine_Frequency<10 is not allowed !!');
    set(handles.pushbutton_connect_daq,'Enable','off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_sine_frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_sine_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_sine_duration_time_Callback(hObject, eventdata, handles)
% hObject    handle to edit_sine_duration_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sine_duration_time as text
%        str2double(get(hObject,'String')) returns contents of edit_sine_duration_time as a double
Sine_Duration=str2double(get(hObject,'String'));
if Sine_Duration >= 0 && Sine_Duration <= 1000
    if rem(Sine_Duration,1) == 0  % check if it is an integer
        handles.Sine_Duration=Sine_Duration;
        set(handles.pushbutton_connect_daq,'Enable','on');  
    else    
        handles.Sine_Duration=60;
        disp('            Warning: Sine_Duration is not an integer, set Sine_Duration to 60!!');
        set(handles.test_information_text,'String', '            Warning: Sine_Duration has to be an integer !!');
        set(handles.pushbutton_connect_daq,'Enable','off');
    end    
else
    handles.Sine_Duration=60;
    disp('            Warning: Sine_Duration>1000 or Sine_Duration<0, set Sine_Duration to 60!!');
    set(handles.test_information_text,'String', '            Warning: Sine_Duration>1000 or Sine_Duration<0 is not allowed !!');
    set(handles.pushbutton_connect_daq,'Enable','off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_sine_duration_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_sine_duration_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_save_figure.
function checkbox_save_figure_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_save_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_save_figure


% --- Executes on button press in checkbox_all.
function checkbox_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_all



function edit_delay_Callback(hObject, eventdata, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_delay as text
%        str2double(get(hObject,'String')) returns contents of edit_delay as a double
Delay=str2double(get(hObject,'String'));
if Delay >= 0 && Delay <= 100
    if rem(Delay,1) == 0  % check if it is an integer
        handles.Delay=Delay; 
        set(handles.pushbutton_connect_daq,'Enable','on');  
    else    
        handles.Delay=1;
        disp('            Warning: Delay is not an integer, set Delay to 1!!');
        set(handles.test_information_text,'String', '            Warning: Delay has to be an integer !!');
        set(handles.pushbutton_connect_daq,'Enable','off');
    end 
else
    handles.Delay=1;
    disp('            Warning: Delay>100 or Delay<0, set Delay to 1!!');
    set(handles.test_information_text,'String', '            Warning: Delay>100 or Delay<0 is not allowed !!');
    set(handles.pushbutton_connect_daq,'Enable','off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_delay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function popupmenu_sweep_cycles_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_sweep_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenu_sweep_cycles as text
%        str2double(get(hObject,'String')) returns contents of popupmenu_sweep_cycles as a double
    str = get(hObject,'String');
    val = get(hObject,'Value');
    handles.Cycles=str2num(char(str(val)));
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_sweep_cycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_sweep_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
