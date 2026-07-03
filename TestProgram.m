%% Read Resistance (Ohms) from Keithley/Tektronix 2400 SourceMeter
clear;
clc;

% Clean up any previous unclosed instrument connections
try delete(instrfind); catch; end

% Create ADLINK GPIB object (Board 0, Address 24)
smu = gpib('adlink', 0, 24);

% Optional: Set timeout
smu.Timeout = 10;

% Open the connection
fopen(smu);

%% Reset instrument
fprintf(smu, '*RST');
pause(1);

%% Configure for resistance measurement
% These commands conform to the SCPI Signal Oriented Measurement Commands
fprintf(smu, ":SENS:FUNC 'RES'");
fprintf(smu, ":FORM:ELEM RES");

%% Trigger a measurement and read the buffer
fprintf(smu, ':READ?');

%% Read measured resistance
resistance_str = fscanf(smu);
resistance = str2double(resistance_str);

fprintf('Measured Resistance = %.6f Ohms\n', resistance);

%% Close and clear object
fclose(smu);
delete(smu);
clear smu;