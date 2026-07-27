function Write_Header(hObject, eventdata, handles)
 
    % Header
    fid = fopen(handles.File_Name, 'w+');

    if(fid == -1)
        fprintf('ERROR: Error creating file: %s\r\n', handles.File_Name);
        return;
    end
    
    % Helper functions
    WriteBlank = @() fprintf(fid, '\r\n');
    WriteStr = @(Desc, Str) fprintf(fid, '%s\t%s\r\n', Desc, Str);
    WriteInt = @(Desc, Int) fprintf(fid, '%s\t%d\r\n', Desc, Int);
    WriteFloat = @(Desc, Num) fprintf(fid, '%s\t%g\r\n', Desc, Num);
    
    % Generic header for all files
    WriteStr('UCSD Magnetoresistive Biosensor v1.0', 'BioEE Group');  % Line 1
    WriteStr('Date:', date);
    WriteStr('Time:', datestr(now,'HH:MM'));
    WriteStr('Test Row:', handles.Test_Channel);
    WriteStr('Test Column:', handles.Test_Column);   % Line 5
    
    WriteInt('AC Magnetic Field Frequency [Hz]:', handles.Sine_Frequency);
    WriteInt('AC Magnetic Field Duratuin [s]:', handles.Sine_Duration);
    WriteInt('Maximum Positive Field [Oe]:', handles.Positive_Field);
    WriteInt('Maximum Negative Field [Oe]:', handles.Negative_Field);
    WriteBlank();       % Line 10
    WriteBlank();           
    WriteBlank();
    WriteBlank();
    WriteBlank();       
    WriteBlank();       % Line 15
    WriteBlank();       
    WriteBlank();
    WriteBlank();
    WriteBlank();
    WriteBlank();       % Line 20
            %Data Input starts at Line 21        
            
    fclose(fid);

end
