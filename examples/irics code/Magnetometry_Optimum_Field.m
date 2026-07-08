clear;

% Input parameters here
filename = 'MR_Characterization_07092020.csv';
R_MR=34.5;      % R_MR at target HA (Check sqrt(2))
R0=1400;        % R0 of the sensor
% End input parameters

delimiterIn = ',';
headerlinesIn = 27;
filedata = importdata(filename,delimiterIn,headerlinesIn);
Time = filedata.data(:,2);
T_initial = length(Time);
% import data when comments added
headerlinesIn1 = T_initial;
filedata1 = importdata(filename,delimiterIn,(headerlinesIn+headerlinesIn1));
Time1 = filedata1.data(:,1);
T_comment = length(Time1);
Comment = filedata1.textdata((headerlinesIn+headerlinesIn1-3):end,1);
% import initial values
headerlinesIn_CT = 11;
headerlinesIn_LT = 13;
headerlinesIn_HT = 15;
filedata_CT = importdata(filename,delimiterIn,headerlinesIn_CT);
filedata_LT = importdata(filename,delimiterIn,headerlinesIn_LT);
filedata_HT = importdata(filename,delimiterIn,headerlinesIn_HT);
CT0(1,:) = filedata_CT.data(1,1:end);
LT0(1,:) = filedata_LT.data(1,1:end);
HT0(1,:) = filedata_HT.data(1,1:end);

Time(T_initial+1:T_initial+T_comment,1)=Time1(:,1);
LT = zeros(T_initial+T_comment,80);
HT = zeros(T_initial+T_comment,80);
CT = zeros(T_initial+T_comment,80);

for i=1:1:80
    LT(1:T_initial,i) = filedata.data(:,i+2);
    LT(T_initial+1:T_initial+T_comment,i) = filedata1.data(:,i+1);
    HT(1:T_initial,i) = filedata.data(:,i+85);
    HT(T_initial+1:T_initial+T_comment,i) = filedata1.data(:,i+84);
    CT(1:T_initial,i) = filedata.data(:,i+166);
    CT(T_initial+1:T_initial+T_comment,i) = filedata1.data(:,i+165);
end

% Take the useful data
% LT1(:,1:8)=LT(:,[2:3,10:11,18:19,26,34]);
% CT1(:,1:8)=CT(:,[2:3,10:11,18:19,26,34]);
LT1=LT;
CT1=CT;
CT1(1,:)=CT1(2,:);

% store the last 4 data points at each field amplitude
for i=1:1:length(Comment)
     if strcmp(Comment(i,1),'49 Oe')==1
        LT_before_49Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'46 Oe')==1
        LT_before_46Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'43 Oe')==1
        LT_before_43Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'40 Oe')==1
        LT_before_40Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'37 Oe')==1
        LT_before_37Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'34 Oe')==1
        LT_before_34Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'31 Oe')==1
        LT_before_31Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'28 Oe')==1
        LT_before_28Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'25 Oe')==1
        LT_before_25Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'22 Oe')==1
        LT_before_22Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'19 Oe')==1
        LT_before_19Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'16 Oe')==1
        LT_before_16Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 49Oe')==1
        LT_after_49Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 46Oe')==1
        LT_after_46Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 43Oe')==1
        LT_after_43Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 40Oe')==1
        LT_after_40Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 37Oe')==1
        LT_after_37Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 34Oe')==1
        LT_after_34Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 31Oe')==1
        LT_after_31Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 28Oe')==1
        LT_after_28Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 25Oe')==1
        LT_after_25Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 22Oe')==1
        LT_after_22Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 19Oe')==1
        LT_after_19Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
    if strcmp(Comment(i,1),'Add MNP 16Oe')==1
        LT_after_16Oe=LT1(T_initial+i-4:T_initial+i-1,:);
    end
end

% LT_Amp_before_49Oe(1,:)=mean(LT_before_49Oe);
% LT_Amp_before_46Oe(1,:)=mean(LT_before_46Oe);
% LT_Amp_before_43Oe(1,:)=mean(LT_before_43Oe);
% LT_Amp_before_40Oe(1,:)=mean(LT_before_40Oe);

LT_Amp_before_37Oe(1,:)=mean(LT_before_37Oe);
LT_Amp_before_34Oe(1,:)=mean(LT_before_34Oe);
LT_Amp_before_31Oe(1,:)=mean(LT_before_31Oe);
LT_Amp_before_28Oe(1,:)=mean(LT_before_28Oe);
LT_Amp_before_25Oe(1,:)=mean(LT_before_25Oe);
LT_Amp_before_22Oe(1,:)=mean(LT_before_22Oe);
LT_Amp_before_19Oe(1,:)=mean(LT_before_19Oe);
LT_Amp_before_16Oe(1,:)=mean(LT_before_16Oe);

% LT_Amp_after_49Oe(1,:)=mean(LT_after_49Oe);
% LT_Amp_after_46Oe(1,:)=mean(LT_after_46Oe);
% LT_Amp_after_43Oe(1,:)=mean(LT_after_43Oe);
% LT_Amp_after_40Oe(1,:)=mean(LT_after_40Oe);

LT_Amp_after_37Oe(1,:)=mean(LT_after_37Oe);
LT_Amp_after_34Oe(1,:)=mean(LT_after_34Oe);
LT_Amp_after_31Oe(1,:)=mean(LT_after_31Oe);
LT_Amp_after_28Oe(1,:)=mean(LT_after_28Oe);
LT_Amp_after_25Oe(1,:)=mean(LT_after_25Oe);
LT_Amp_after_22Oe(1,:)=mean(LT_after_22Oe);
LT_Amp_after_19Oe(1,:)=mean(LT_after_19Oe);
LT_Amp_after_16Oe(1,:)=mean(LT_after_16Oe);

% Signal_49Oe=LT_Amp_after_49Oe-LT_Amp_before_49Oe;
% Signal_46Oe=LT_Amp_after_46Oe-LT_Amp_before_46Oe;
% Signal_43Oe=LT_Amp_after_43Oe-LT_Amp_before_43Oe;
% Signal_40Oe=LT_Amp_after_40Oe-LT_Amp_before_40Oe;

Signal_37Oe=LT_Amp_after_37Oe-LT_Amp_before_37Oe;
Signal_34Oe=LT_Amp_after_34Oe-LT_Amp_before_34Oe;
Signal_31Oe=LT_Amp_after_31Oe-LT_Amp_before_31Oe;
Signal_28Oe=LT_Amp_after_28Oe-LT_Amp_before_28Oe;
Signal_25Oe=LT_Amp_after_25Oe-LT_Amp_before_25Oe;
Signal_22Oe=LT_Amp_after_22Oe-LT_Amp_before_22Oe;
Signal_19Oe=LT_Amp_after_19Oe-LT_Amp_before_19Oe;
Signal_16Oe=LT_Amp_after_16Oe-LT_Amp_before_16Oe;

% Signal_Amp_49Oe=mean([Signal_49Oe(1,55),Signal_49Oe(1,56),Signal_49Oe(1,62),Signal_49Oe(1,63),Signal_49Oe(1,64),Signal_49Oe(1,70),Signal_49Oe(1,71),Signal_49Oe(1,72),Signal_49Oe(1,78),Signal_49Oe(1,79),Signal_49Oe(1,80)]);
% Signal_Amp_46Oe=mean([Signal_46Oe(1,55),Signal_46Oe(1,56),Signal_46Oe(1,62),Signal_46Oe(1,63),Signal_46Oe(1,64),Signal_46Oe(1,70),Signal_46Oe(1,71),Signal_46Oe(1,72),Signal_46Oe(1,78),Signal_46Oe(1,79),Signal_46Oe(1,80)]);
% Signal_Amp_43Oe=mean([Signal_43Oe(1,55),Signal_43Oe(1,56),Signal_43Oe(1,62),Signal_43Oe(1,63),Signal_43Oe(1,64),Signal_43Oe(1,70),Signal_43Oe(1,71),Signal_43Oe(1,72),Signal_43Oe(1,78),Signal_43Oe(1,79),Signal_43Oe(1,80)]);
% Signal_Amp_40Oe=mean([Signal_40Oe(1,55),Signal_40Oe(1,56),Signal_40Oe(1,62),Signal_40Oe(1,63),Signal_40Oe(1,64),Signal_40Oe(1,70),Signal_40Oe(1,71),Signal_40Oe(1,72),Signal_40Oe(1,78),Signal_40Oe(1,79),Signal_40Oe(1,80)]);

Signal_Amp_37Oe=mean([Signal_37Oe(1,55),Signal_37Oe(1,56),Signal_37Oe(1,62),Signal_37Oe(1,63),Signal_37Oe(1,64),Signal_37Oe(1,70),Signal_37Oe(1,71),Signal_37Oe(1,72),Signal_37Oe(1,78),Signal_37Oe(1,79),Signal_37Oe(1,80)]);
Signal_Amp_34Oe=mean([Signal_34Oe(1,55),Signal_34Oe(1,56),Signal_34Oe(1,62),Signal_34Oe(1,63),Signal_34Oe(1,64),Signal_34Oe(1,70),Signal_34Oe(1,71),Signal_34Oe(1,72),Signal_34Oe(1,78),Signal_34Oe(1,79),Signal_34Oe(1,80)]);
Signal_Amp_31Oe=mean([Signal_31Oe(1,55),Signal_31Oe(1,56),Signal_31Oe(1,62),Signal_31Oe(1,63),Signal_31Oe(1,64),Signal_31Oe(1,70),Signal_31Oe(1,71),Signal_31Oe(1,72),Signal_31Oe(1,78),Signal_31Oe(1,79),Signal_31Oe(1,80)]);
Signal_Amp_28Oe=mean([Signal_28Oe(1,55),Signal_28Oe(1,56),Signal_28Oe(1,62),Signal_28Oe(1,63),Signal_28Oe(1,64),Signal_28Oe(1,70),Signal_28Oe(1,71),Signal_28Oe(1,72),Signal_28Oe(1,78),Signal_28Oe(1,79),Signal_28Oe(1,80)]);
Signal_Amp_25Oe=mean([Signal_25Oe(1,55),Signal_25Oe(1,56),Signal_25Oe(1,62),Signal_25Oe(1,63),Signal_25Oe(1,64),Signal_25Oe(1,70),Signal_25Oe(1,71),Signal_25Oe(1,72),Signal_25Oe(1,78),Signal_25Oe(1,79),Signal_25Oe(1,80)]);
Signal_Amp_22Oe=mean([Signal_22Oe(1,55),Signal_22Oe(1,56),Signal_22Oe(1,62),Signal_22Oe(1,63),Signal_22Oe(1,64),Signal_22Oe(1,70),Signal_22Oe(1,71),Signal_22Oe(1,72),Signal_22Oe(1,78),Signal_22Oe(1,79),Signal_22Oe(1,80)]);
Signal_Amp_19Oe=mean([Signal_19Oe(1,55),Signal_19Oe(1,56),Signal_19Oe(1,62),Signal_19Oe(1,63),Signal_19Oe(1,64),Signal_19Oe(1,70),Signal_19Oe(1,71),Signal_19Oe(1,72),Signal_19Oe(1,78),Signal_19Oe(1,79),Signal_19Oe(1,80)]);
Signal_Amp_16Oe=mean([Signal_16Oe(1,55),Signal_16Oe(1,56),Signal_16Oe(1,62),Signal_16Oe(1,63),Signal_16Oe(1,64),Signal_16Oe(1,70),Signal_16Oe(1,71),Signal_16Oe(1,72),Signal_16Oe(1,78),Signal_16Oe(1,79),Signal_16Oe(1,80)]);
% Signal_Amp_37Oe=mean(Signal_37Oe);
% Signal_Amp_34Oe=mean(Signal_34Oe);
% Signal_Amp_31Oe=mean(Signal_31Oe);
% Signal_Amp_28Oe=mean(Signal_28Oe);
% Signal_Amp_25Oe=mean(Signal_25Oe);
% Signal_Amp_22Oe=mean(Signal_22Oe);
% Signal_Amp_19Oe=mean(Signal_19Oe);
% Signal_Amp_16Oe=mean(Signal_16Oe);

Signal_Amp=[Signal_Amp_16Oe Signal_Amp_19Oe Signal_Amp_22Oe Signal_Amp_25Oe Signal_Amp_28Oe Signal_Amp_31Oe Signal_Amp_34Oe Signal_Amp_37Oe];%  Signal_Amp_40Oe Signal_Amp_43Oe Signal_Amp_46Oe Signal_Amp_49Oe];
Target_MR=2*R_MR/(R0-R_MR);

figure;
hold on;
box on;
Field=16:3:37;
plot(Field,Signal_Amp,'LineWidth',2);
scatter(Field,Signal_Amp,'o');
title('Signal vs. Field','FontSize',18,'FontWeight','bold');
xlabel('Field [Oe]','FontSize',18);
ylabel('Signal [uV]','FontSize',18);
set(gca,'FontSize',18);


