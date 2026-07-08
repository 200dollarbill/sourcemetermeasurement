function Plot_Data(src, event,hObject, eventdata, handles)

global Tracker;
global Rstep;
global Vctrl;
global TotalRepetition;
TotalRepetition = floor(handles.Test_Duration/handles.RefreshRate);
       
    hold(handles.axes_magnetic_field,'on');

        fprintf('            Measuring %d s of %d s...\n',Tracker,TotalRepetition); 
        set(handles.test_information_text,'String',' Measuring...');
        x_val=double((Tracker-1)*handles.DAQ_RATE*handles.RefreshRate+1:1:Tracker*handles.DAQ_RATE*handles.RefreshRate)/handles.DAQ_RATE;   
    
    if Tracker<=handles.Sine_Duration+handles.Delay
        plot(handles.axes_magnetic_field,x_val,(0.5*25).*Vctrl((Tracker-1)*handles.DAQ_RATE*handles.RefreshRate+1:1:Tracker*handles.DAQ_RATE*handles.RefreshRate),'b');
        xlim(handles.axes_magnetic_field, [(Tracker-2)*handles.RefreshRate (Tracker-1)*handles.RefreshRate]);
    else
        data=[event.Data];
        if get(handles.checkbox_all,'Value')==true
            for i=1:1:8
                Rsensor(:,i)=42.2.*ones(handles.DAQ_RATE*handles.RefreshRate,1)./(((1.65.*ones(handles.DAQ_RATE*handles.RefreshRate,1)-data(:,i))./handles.VB+(42.2/1.246).*ones(handles.DAQ_RATE*handles.RefreshRate,1)));
                Rstep(Tracker-handles.Sine_Duration-handles.Delay,i)=mean(Rsensor(0.2*handles.DAQ_RATE*handles.RefreshRate:0.8*handles.DAQ_RATE*handles.RefreshRate,i));
            end    
        else    
            Rsensor(:,1)=42.2.*ones(handles.DAQ_RATE*handles.RefreshRate,1)./(((1.65.*ones(handles.DAQ_RATE*handles.RefreshRate,1)-data(:,1))./handles.VB+(42.2/1.246).*ones(handles.DAQ_RATE*handles.RefreshRate,1)));
            Rstep(Tracker-handles.Sine_Duration-handles.Delay,1)=mean(Rsensor(0.2*handles.DAQ_RATE*handles.RefreshRate:0.8*handles.DAQ_RATE*handles.RefreshRate,1));       
        end
        % collect output data every RefreshRate
        plot(handles.axes_magnetic_field,x_val,(0.5*25).*Vctrl((Tracker-1)*handles.DAQ_RATE*handles.RefreshRate+1:1:Tracker*handles.DAQ_RATE*handles.RefreshRate),'b');
        xlim(handles.axes_magnetic_field, [(Tracker-2)*handles.RefreshRate (Tracker-1)*handles.RefreshRate]);
    end
    axis 'auto y';
    hold(handles.axes_magnetic_field,'off');
    guidata(hObject, handles);
    Tracker=Tracker+1;    
%    xlim(handles.axes_magnetic_field, [0 (handles.Test_Duration/TotalRepetition*Tracker)]);
%    xlim(handles.axes_MR_ratio, [0 (handles.Test_Duration/TotalRepetition*Tracker)]);
end