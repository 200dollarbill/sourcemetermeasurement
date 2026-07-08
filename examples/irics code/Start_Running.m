function Start_Running(hObject, eventdata, handles)

global Tracker;
global TotalRepetition;
global file_id;
global IsRunning;  
global Vctrl;
global Rstep;

% Select test column
switch handles.Test_Column            
    case 'Column1' 
        outputSingleScan(handles.DAQSession2,[1 0 0 0 0 0 0 0 0 0]);
    case 'Column2' 
        outputSingleScan(handles.DAQSession2,[0 1 0 0 0 0 0 0 0 0]);
    case 'Column3' 
        outputSingleScan(handles.DAQSession2,[0 0 1 0 0 0 0 0 0 0]);
    case 'Column4' 
        outputSingleScan(handles.DAQSession2,[0 0 0 1 0 0 0 0 0 0]);
    case 'Column5' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 1 0 0 0 0 0]);
    case 'Column6' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 0 1 0 0 0 0]);
    case 'Column7' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 0 0 1 0 0 0]);
    case 'Column8' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 0 0 0 1 0 0]);
    case 'Column9' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 0 0 0 0 1 0]);
    case 'Column10' 
        outputSingleScan(handles.DAQSession2,[0 0 0 0 0 0 0 0 0 1]);    
    otherwise 
        % If no column is checked, error is given
        disp('Error: No test column setup @ connectDAQ');
        set(handles.test_information_text,'String', 'Error: No test column setup @ connectDAQ');
        return;
end

Tracker = 1;
hold(handles.axes_MR_ratio,'on');
% generate analog output signals
% Current/Field=1A/25Oe
Positive_Output_Current=handles.Positive_Field/25;
Negative_Output_Current=handles.Negative_Field/25;
% Control Voltage/Current=1V/0.5A
Positive_Control_Voltage=Positive_Output_Current/0.5;
Negative_Control_Voltage=Negative_Output_Current/0.5;

% steps for MR sweep
step_positive=handles.Positive_Field/1;         % 0->+H_max
step_negative=-handles.Negative_Field/1;        % +H_max->-H_max
step_total=(step_positive+step_negative)*2;   % 0->+H_max->-H_max->0

if get(handles.checkbox_all,'Value')==true
    Rstep=zeros((step_total+1)*handles.Cycles,8);
else
    Rstep=zeros((step_total+1)*handles.Cycles,1);
end    
handles.Test_Duration=handles.Sine_Duration+handles.Delay+2*handles.Cycles*(handles.Positive_Field-handles.Negative_Field)+1;
handles.DAQSession1.Rate = handles.DAQ_RATE;
dt = 1/handles.DAQSession1.Rate;
t_sin = 0:dt:handles.Sine_Duration-dt;
% generate DC bias for TIA input
Vbias(1:1:handles.DAQSession1.Rate*handles.Test_Duration)=handles.VB; 
% generate sine wave (+-50Oe)
Vsine = (50/25/0.5).*sin(2*pi*handles.Sine_Frequency*t_sin);

% generate control signal for Kepco BOP
Vctrl(1:1:handles.DAQSession1.Rate*handles.Sine_Duration)=Vsine;
Vctrl(handles.DAQSession1.Rate*handles.Sine_Duration+1:1:handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay))=0;
for j=1:1:handles.Cycles
    for i=0:1:step_positive        
        Vctrl(handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i)+1:1:handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i+1))=i/25/0.5;
    end
    for i=step_positive+1:1:(2*step_positive+step_negative)
        Vctrl(handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i)+1:1:handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i+1))=Positive_Control_Voltage-(i-step_positive)/25/0.5;
    end
    for i=(2*step_positive+step_negative)+1:1:step_total
        Vctrl(handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i)+1:1:handles.DAQSession1.Rate*(handles.Sine_Duration+handles.Delay+(j-1)*(step_total+1)+i+1))=Negative_Control_Voltage+(i-(2*step_positive+step_negative))/25/0.5;
    end
end
queueOutputData(handles.DAQSession1,[transpose(Vbias) transpose(Vctrl)]);

% process analog input signals
     ls = handles.DAQSession1.addlistener('DataAvailable', @(src,event) ...
             Plot_Data(src,event, hObject, eventdata, handles));
  
    handles.DAQSession1.NotifyWhenDataAvailableExceeds = handles.RefreshRate * handles.DAQSession1.Rate;
    
    handles.DAQSession1.startBackground(); 
     while handles.DAQSession1.IsRunning          % check trigger of Stop Button every 1 sec
         pause(handles.RefreshRate);
     end   
    guidata(hObject, handles);
   	pause(0.2);
    
    Field=zeros(handles.Cycles*(step_total+1));
    for j=1:1:handles.Cycles
        for i=1:1:step_positive
            Field((j-1)*(step_total+1)+i+1)=i;
        end
        for i=step_positive+1:1:(2*step_positive+step_negative)
        	Field((j-1)*(step_total+1)+i+1)=handles.Positive_Field-(i-step_positive);
        end
        for i=(2*step_positive+step_negative)+1:1:step_total
            Field((j-1)*(step_total+1)+i+1)=handles.Negative_Field+(i-(2*step_positive+step_negative));
        end 
    end
    
    if get(handles.checkbox_all,'Value')==true
        plot(handles.axes_MR_ratio,Field,Rstep(:,1),'b');
        plot(handles.axes_MR_ratio,Field,Rstep(:,2),'k');
        plot(handles.axes_MR_ratio,Field,Rstep(:,3),'r');
        plot(handles.axes_MR_ratio,Field,Rstep(:,4),'m');
        plot(handles.axes_MR_ratio,Field,Rstep(:,5),'b');
        plot(handles.axes_MR_ratio,Field,Rstep(:,6),'k');
        plot(handles.axes_MR_ratio,Field,Rstep(:,7),'r');
        plot(handles.axes_MR_ratio,Field,Rstep(:,8),'m');
        xlim(handles.axes_MR_ratio, [handles.Negative_Field handles.Positive_Field]);
        ylim(handles.axes_MR_ratio, [min(min(Rstep)) max(max(Rstep))]);
    else
        plot(handles.axes_MR_ratio,Field,Rstep(:,1));
        xlim(handles.axes_MR_ratio, [handles.Negative_Field handles.Positive_Field]);
        ylim(handles.axes_MR_ratio, [min(Rstep(:,1)) max(Rstep(:,1))]);
    end
    xlim(handles.axes_magnetic_field, [0 (handles.Test_Duration/TotalRepetition*(Tracker-1))]);
    delete(ls);

% Write data    
    if get(handles.checkbox_save_data,'Value')==true  
        %   write Rsensor
        disp('Saving data ...');    
        if file_id>0
            if get(handles.checkbox_all,'Value')==true
                fprintf(file_id, 'Field (Oe)\tRow1 (KOhms)\tRow2 (KOhms)\tRow3 (KOhms)\tRow4 (KOhms)\tRow5 (KOhms)\tRow6 (KOhms)\tRow7 (KOhms)\tRow8 (KOhms)\r\n');    % Line 21
                for i=0:1:step_total
                    fprintf(file_id,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n',Field(i+1),Rstep(i+1,1),Rstep(i+1,2),Rstep(i+1,3),Rstep(i+1,4),Rstep(i+1,5),Rstep(i+1,6),Rstep(i+1,7),Rstep(i+1,8));
                end    
            else    
                fprintf(file_id, 'Field (Oe)\tR_sensor (KOhms)\r\n');    % Line 21
                for i=0:1:step_total
                    fprintf(file_id,'%f\t%f\r\n',Field(i+1),Rstep(i+1,1));
                end
            end    
        end
    end   

    % save figure
    if get(handles.checkbox_save_figure,'Value')==true
        handles.Figure_Name=['Saved_Figure' datestr(now,'_yyyy-mm-dd_HHMM') '.fig'];
        Fig = figure;
        h=handles.axes_MR_ratio;
        copyobj(h, Fig);
        hgsave(Fig,handles.Figure_Name);        
    end    
    hold(handles.axes_magnetic_field,'off');
    hold(handles.axes_MR_ratio,'off');

    % finish measuring
    guidata(hObject, handles);
    if IsRunning
    disp('Measurement finished! :)');
    set(handles.test_information_text,'String', 'Measurement finished! :) ');
    end
end