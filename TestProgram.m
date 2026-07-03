clear;
clc;

addr = 24;

smu = gpib('adlink', 0, addr);
fopen(smu);

%  ALWAYS clear instrument state first
fprintf(smu, '*CLS');
fprintf(smu, '*RST');
pause(1);

%  Set resistance mode
fprintf(smu, ':SENS:FUNC "RES"');
fprintf(smu, ':FORM:ELEM RES');

%  IMPORTANT: flush buffer BEFORE query
flushinput(smu);

%  Send query
fprintf(smu, ':READ?');

%  Read response (THIS is critical)
data = fscanf(smu);

disp(data);

resistance = str2double(data);

fprintf('Resistance = %.6f Ohms\n', resistance);

fclose(smu);
delete(smu);
clear smu;