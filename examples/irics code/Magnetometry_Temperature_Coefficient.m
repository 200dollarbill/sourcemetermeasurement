clear;

% Input parameters here
filename = 'TempTest_18082022.csv';
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
Time(T_initial+1:T_initial+T_comment,1)=Time1(:,1);
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

for i=1:1:80
    LT_change(:,i) = LT(2:T_initial+T_comment,i)./LT0(1,i);
    HT_change(:,i) = HT(2:T_initial+T_comment,i)./HT0(1,i);
    CT_change(:,i) = CT(2:T_initial+T_comment,i)./CT0(1,i)-ones(T_initial+T_comment-1,1);
%     LT_change(:,i) = LT(T_initial+5:T_initial+T_comment,i)./LT0(1,i);
%     HT_change(:,i) = HT(T_initial+5:T_initial+T_comment,i)./HT0(1,i);
%     CT_change(:,i) = CT(T_initial+5:T_initial+T_comment,i)./CT0(1,i)-ones(T_comment-4,1);
end


% % Remove Outliers
remove = [];%%[2,3,6:8,14,16,19,37,46:48,54,62,69,70,78,79];  % Sensor #s that need to be removed
remove = unique(remove);

% Loop through and remove sensors and save into xT_change1;
offset = 0;
for i = 1:size(CT_change,2)
    if ~all(remove~=i)
        offset=offset+1;
    else
        CT_change1(:,i-offset)=CT_change(:,i);
        LT_change1(:,i-offset)=LT_change(:,i);
    end
end

% CT_change1(:,1:4)=CT_change(:,41:44);
% CT_change1(:,5:11)=CT_change(:,46:52);
% CT_change1(:,12:18)=CT_change(:,54:60);
% CT_change1(:,19:25)=CT_change(:,62:68);
% LT_change1(:,1:4)=LT_change(:,41:44);
% LT_change1(:,5:11)=LT_change(:,46:52);
% LT_change1(:,12:18)=LT_change(:,54:60);
% LT_change1(:,19:25)=LT_change(:,62:68);

% for loop used to stop at 25
for i=1:1:size(CT_change1,2)
    TC(:,i)=polyfit(CT_change1(:,i),LT_change1(:,i),1); 
end
Temp_Coef = mean(abs(TC(1,:)));
Temp_offset = mean(TC(2,:));

for i=1:1:length(CT_change(:,1))
    CT_fit(i,1)=mean(CT_change(i,:));
end    
CT_LT_fit(:,1) = Temp_Coef.*CT_fit(:,1)+Temp_offset.*ones(length(CT_fit(:,1)),1);

CT(1,:)=CT(2,:);

figure;
subplot(2,1,1);
hold on;
for i=1:1:80
    plot(Time,LT(:,i));
end
title('LT Amplitude','FontSize',18,'FontWeight','bold');
xlabel('Time [min]','FontSize',18);
ylabel('Change in Amplitude [uV]','FontSize',18);
set(gca,'FontSize',18);

subplot(2,1,2);
hold on;
for i=1:1:80
    plot(Time,CT(:,i));
end
title('CT Amplitude','FontSize',18,'FontWeight','bold');
xlabel('Time [min]','FontSize',18);
ylabel('Change in Amplitude [uV]','FontSize',18);
set(gca,'FontSize',18);

figure;
hold on;
plot(CT_change1,LT_change1,'o');
plot(CT_fit,CT_LT_fit,'LineWidth',2);
title('Relationship between CT and LT','FontSize',18,'FontWeight','bold');
xlabel('delta CT/CT0','FontSize',18);
ylabel('delta LT/LT0','FontSize',18);
set(gca,'FontSize',18);




