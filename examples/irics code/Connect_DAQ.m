function Connect_DAQ(hObject,handles)
% remove previous channels
if strfind(handles.pre_Channel,'Row') > 0
% 1 AI channel, 2 AO channels, 10 DO channels
    handles.DAQSession1.removeChannel(1:3);
    handles.DAQSession2.removeChannel(1:10);
elseif strfind(handles.pre_Channel,'All') > 0
% 8 AI channels, 2 AO channels, 10 DO channels
    handles.DAQSession1.removeChannel(1:10);
    handles.DAQSession2.removeChannel(1:10);   
end

% clear figures for future plot
cla(handles.axes_magnetic_field);
cla(handles.axes_MR_ratio);
axis(handles.axes_magnetic_field,'auto y');
axis(handles.axes_MR_ratio,'auto y');
clearvars -global
% create new channels
if get(handles.checkbox_all,'Value')==true
        handles.DAQSession1.addAnalogInputChannel('Dev2', 7, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 6, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 5, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 4, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 3, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 2, 'Voltage');
        handles.DAQSession1.addAnalogInputChannel('Dev2', 1, 'Voltage'); 
        handles.DAQSession1.addAnalogInputChannel('Dev2', 0, 'Voltage');
else
    switch handles.Test_Channel
        case 'Row1' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 7, 'Voltage'); 
        case 'Row2' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 6, 'Voltage');
        case 'Row3' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 5, 'Voltage');
        case 'Row4' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 4, 'Voltage'); 
        case 'Row5' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 3, 'Voltage');
        case 'Row6' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 2, 'Voltage');
        case 'Row7' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 1, 'Voltage');  
        case 'Row8' 
            handles.DAQSession1.addAnalogInputChannel('Dev2', 0, 'Voltage');
        otherwise 
            disp('Error: No test channel setup @ connectDAQ');
            set(handles.test_information_text,'String', 'Error: No test channel setup @ connectDAQ');
            set(handles.pushbutton_start,'Enable','off');
            return;
    end
end
    set(handles.DAQSession1.Channels,'Range',[-10 10]);
    handles.DAQSession1.IsContinuous=false;
    handles.DAQSession1.DurationInSeconds=handles.Sine_Duration+2*(handles.Positive_Field-handles.Negative_Field);
    handles.DAQSession1.Rate=handles.DAQ_RATE;
    % add AO channels
    handles.DAQSession1.addAnalogOutputChannel('Dev2', 0, 'Voltage');    % TIA input bias
    handles.DAQSession1.addAnalogOutputChannel('Dev2', 1, 'Voltage');    % PA input bias
    % add DO channels
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line0', 'OutputOnly');      % Column Select1
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line1', 'OutputOnly');      % Column Select2
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line2', 'OutputOnly');      % Column Select3
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line3', 'OutputOnly');      % Column Select4
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line4', 'OutputOnly');      % Column Select5
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line5', 'OutputOnly');      % Column Select6
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line6', 'OutputOnly');      % Column Select7
    handles.DAQSession2.addDigitalChannel('Dev2', 'port1/line7', 'OutputOnly');      % Column Select8
    handles.DAQSession2.addDigitalChannel('Dev2', 'port2/line0', 'OutputOnly');      % Column Select9
    handles.DAQSession2.addDigitalChannel('Dev2', 'port2/line1', 'OutputOnly');      % Column Select10
    disp('Connect DAQ Successfully');
    set(handles.test_information_text,'String', 'Connect DAQ Successfully');

    % update handles
    guidata(hObject, handles);
end