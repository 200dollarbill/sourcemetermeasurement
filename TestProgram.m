%% Read Resistance (Ohms) from Keithley/Tektronix 2400 SourceMeter
clear;
clc;

% Create VISA-GPIB object
% Change "NI" to "AGILENT" if using Keysight/Agilent VISA
smu = visadev("GPIB0::24::INSTR");

% Optional: Set timeout
smu.Timeout = 10;

%% Reset instrument
writeline(smu, "*RST");
pause(1);

%% Configure for resistance measurement
writeline(smu, ":SENS:FUNC 'RES'");
writeline(smu, ":FORM:ELEM RES");

%% Trigger a measurement
writeline(smu, ":READ?");

%% Read measured resistance
resistance = str2double(readline(smu));

fprintf("Measured Resistance = %.6f Ohms\n", resistance);

%% Clear object
clear smu;
%% 
visadevlist

