clear;

filename = 'MR_Ratio_Test_2022-12-23_1416.csv';
% filename = 'MR_Ratio_Test_C4_07092020.csv';
% figname_saved = 'MR_Ratio_Test_Michael_C4_New3.fig';

delimiterIn = '\t';
headerlinesIn = 21;
filedata = importdata(filename,delimiterIn,headerlinesIn);

Field = filedata.data(:,1);
Row1 = filedata.data(:,2);
Row2 = filedata.data(:,3);
Row3 = filedata.data(:,4);
Row4 = filedata.data(:,5);
Row5 = filedata.data(:,6);
Row6 = filedata.data(:,7);
Row7 = filedata.data(:,8);
Row8 = filedata.data(:,9);
Row = [Row1 Row2 Row3 Row4 Row5 Row6 Row7 Row8];
Row_mean = mean(Row,2);
Row_std = std(Row,0,2);

% Calculate Averaged R0 and MR
R0 = Row_mean(101,1);            % kOhm
MR = abs(Row_mean(91,1)-Row_mean(111,1))*1000/20;      % Unit: Ohm/Oe
MRp = MR/R0*100/1000;            % Unit: %/Oe

figure;
subplot(2,1,1);
plot(Field,Row1,Field,Row2,Field,Row3,Field,Row4,Field,Row5,Field,Row6,Field,Row7,Field,Row8);
legend('Row 1','Row 2','Row 3','Row 4','Row 5','Row 6','Row 7','Row 8');
title('MR Curve','FontSize',12);
xlabel('Field [Oe]','FontSize',12);
ylabel('Resistance [kOhms]','FontSize',12);
set(gca,'FontSize',12);
set(gcf,'color','w');
% 
subplot(2,1,2);
box on;
hold on;
Field_eb = Field(11:40:end);
Row_mean_eb = Row_mean(11:40:end);
Row_std_eb = Row_std(11:40:end);
p=plot(Field,Row_mean);
color = get(p,'Color');
h=errorbar(Field_eb,Row_mean_eb,Row_std_eb,'LineStyle','none');
h.CapSize = 6;
h.Color = color;
title('MR Curve','FontSize',12);
xlabel('Field [Oe]','FontSize',12);
ylabel('Resistance [kOhms]','FontSize',12);
set(gca,'FontSize',12);
set(gcf,'color','w');

% savefig(figname_saved);

