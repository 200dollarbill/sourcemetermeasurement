% clear; 
%function daq_measure_simple()
    %% ==== 使用者參數設定區 ====
    selectedChannel = 2;           % 在這一邊讓使用者選擇 1, 2, 或 3 (對應 ai0, ai1, ai2，所以說前面的selectedChannel是選0,1,2)
    outputVoltage = 1;           % AO 輸出電壓（V）
    measurementTime = 1;          % 測量時間（秒）
    samplingRate = 1000000;           % 取樣率（Hz）(DAQ data rate!!!)
    deviceID = "Dev1";             % 裝置名稱（要用 daq.getDevices 確認!!!!!）  

    %% ==== 建立 DAQ Session ====
    try
        d = daq("ni");

        % 加入 AI 通道
        aiChannelName = sprintf("ai%d", selectedChannel);
        addinput(d, deviceID, aiChannelName, "Voltage");

        % 加入 AO 通道
        addoutput(d, deviceID, "ao0", "Voltage");

        % 設定取樣率   
        d.Rate = samplingRate;

        % 計算擷取筆數
        numSamples = round(measurementTime * samplingRate);

        % 建立輸出資料
        outputData = repmat(outputVoltage, numSamples, 1);

        % 同時輸出並擷取資料
        fprintf("[INFO] 輸出 %.2f V 並擷取 %d 筆資料...\n", outputVoltage, numSamples);
        data = readwrite(d, outputData);

        % 計算平均電壓
        avgVoltage = mean(data{:,1});
        fprintf("[RESULT] Channel %d 平均電壓: %.4f V\n", selectedChannel+1, avgVoltage);

        % 儲存到 Workspace
        assignin('base', 'lastVoltageData', data);
        assignin('base', 'averageVoltage', avgVoltage);
        fprintf("[INFO] 資料已儲存為 'lastVoltageData' 和 'averageVoltage'。\n");
  
        
        % figure;
        % plot(data.Time,data{:,1});


    catch ME
        fprintf("[ERROR] %s\n", ME.message);
    end

