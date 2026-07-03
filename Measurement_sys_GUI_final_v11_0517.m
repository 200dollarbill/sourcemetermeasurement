% 高斯計 475 解析度調整指令
 % RDGMODE 參數對應: <mode 1=DC>, <dc_res 1=3.75 digits>, <rms 1>, <peak 1>, <peak_disp 1>
 % 這樣設定能強制把 Time Constant 降到 0.01 秒！
 % fprintf(gm, 'RDGMODE 1,1,1,1,1'); 
 % Line183 防呆：直接寫死 0.1 秒，不再讀取 UI 數值

 function MagNES_App()
    % ====================================================
    % MagNES Automated Magnetic Field Measurement System
    % Features: Mode 1 (Sweep) & Mode 2 (Waveform)
    % Safety: Hard-coded 1.8A Current Limit Logic & No Reverse Scan
    % Performance: STRICT TIMING LOOP + 前饋預測控制 + 拔除即時繪圖堵塞
    % UI Update: 依據標準操作流程 (Top-Down) 重新排列面板順序
    % ====================================================
    
    %% 0. 建立主視窗
    fig = uifigure('Name', 'MagNES Automated Measurement System', 'Position', [100, 50, 950, 750], 'Color', 'w');
    % 關掉 MATLAB 自動調整 children，避免最大化後左側按鈕被系統重新排版。
    try fig.AutoResizeChildren = 'off'; catch; end
    
    % 全域變數
    kepco = []; gm = []; stop_flag = false; 

    % ====================================================
    % Plot display option
    % true  : plot lines with data markers
    % false : plot smooth lines only, no point markers
    % 只影響圖形顯示與匯出圖，不影響 Excel raw data。
    % ====================================================
    show_data_points_on_plot = false;
    show_legend_on_plot = false;             % true: show legends; false: hide legends for cleaner plots

    % ====================================================
    % Sine-wave display option
    % true  : display the measured sine-wave field with interpolation,
    %         giving a smoother V4-like visual curve.
    % false : display raw measured samples connected by straight lines.
    % 注意：只影響圖形顯示與匯出圖，不影響 Excel raw data。
    % ====================================================
    % Sine Wave 磁場圖使用 V4 畫法：直接連接量測資料，不做 interpolation。
    % Square/Pulse 仍保留後面的 transition anchor 修正。
    smooth_sine_field_plot = false;
    sine_plot_interp_factor = 12;   % V4-style sine display 不會用到；保留作為未來需要時的選項

    % ====================================================
    % Field plot display correction for Square / Pulse
    % true  : add display-only anchor points at actual current command times.
    %         This prevents the connected magnetic-field line from visually
    %         starting to change before the input-current transition.
    %         Raw Excel data is not modified.
    % false : plot raw measured points directly.
    % ====================================================
    add_field_transition_anchor_on_plot = true;

    % ====================================================
    % Input-current plot option for Square / Pulse
    % true  : plot the actual KEPCO command timeline.
    %         This is recommended when look_ahead_time is used,
    %         because it prevents the magnetic field from looking
    %         like it changes before the displayed input current.
    % false : plot the ideal mathematical waveform.
    % ====================================================
    plot_square_pulse_input_as_actual_command = true;

    % ====================================================
    % Timing compensation settings
    % look_ahead_time: 提前送 current command，用來補償 KEPCO/GPIB/量測延遲。
    %   設 0     : 不提前，照理想 transition time 送 command。
    %   設 0.009 : 在 transition 前約 9 ms 送 command。
    % step_settle_time: Square/Pulse 切換後等待多久才讀第一筆磁場。
    %   這個值來自你的 single-step response，大約 50~60 ms。
    % ====================================================
    look_ahead_time = 0.009;
    step_settle_time = 0.060;
    
    %% 1. 儀器連線區 (Step 1: Connection Setup) - 移到最上方
    pnl_conn = uipanel(fig, 'Title', '1. Connection Setup', 'Position', [20, 600, 260, 130], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    uilabel(pnl_conn, 'Position', [10, 75, 110, 22], 'Text', 'Kepco Addr:');
    edit_kepco = uieditfield(pnl_conn, 'numeric', 'Position', [120, 75, 50, 22], 'Value', 6);
    uilabel(pnl_conn, 'Position', [10, 45, 110, 22], 'Text', 'Gaussmeter Addr:');
    edit_gm = uieditfield(pnl_conn, 'numeric', 'Position', [120, 45, 50, 22], 'Value', 18);
    
    btn_connect = uibutton(pnl_conn, 'Position', [10, 10, 100, 30], 'Text', 'Connect', 'ButtonPushedFcn', @connectHW);
    lbl_status = uilabel(pnl_conn, 'Position', [120, 10, 130, 30], 'Text', '🔴 Disconnected', 'FontColor', 'r', 'FontWeight', 'bold');
    
    %% 2. 模式選擇區 (Step 2: Operating Mode) - 移到第二層
    pnl_mode = uipanel(fig, 'Title', '2. Operating Mode', 'Position', [20, 525, 260, 65], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    dd_mode = uidropdown(pnl_mode, 'Position', [10, 10, 240, 25], ...
        'Items', {'Mode 1: B-I DC Sweep', 'Mode 2: Waveform Generator'}, ...
        'ValueChangedFcn', @modeChanged);
        
    %% 3A. 參數面板：Mode 1 磁場掃描模式 (Step 3: Sweep Settings) - 移到第三層
    pnl_param_sweep = uipanel(fig, 'Title', '3. Sweep Settings', 'Position', [20, 165, 260, 350], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    
    uilabel(pnl_param_sweep, 'Position', [10, 295, 110, 22], 'Text', 'Current Limit (A):', 'FontWeight', 'bold', 'FontColor', 'r');
    uieditfield(pnl_param_sweep, 'numeric', 'Position', [120, 295, 120, 22], 'Value', 1.8, 'Enable', 'off');
    uilabel(pnl_param_sweep, 'Position', [10, 260, 110, 22], 'Text', 'Start Current (A):');
    edit_startI = uieditfield(pnl_param_sweep, 'numeric', 'Position', [120, 260, 120, 22], 'Value', -1.0);
    uilabel(pnl_param_sweep, 'Position', [10, 225, 110, 22], 'Text', 'End Current (A):');
    edit_endI = uieditfield(pnl_param_sweep, 'numeric', 'Position', [120, 225, 120, 22], 'Value', 1.0);
    uilabel(pnl_param_sweep, 'Position', [10, 190, 110, 22], 'Text', 'Step Current (mA):');
    edit_step = uieditfield(pnl_param_sweep, 'numeric', 'Position', [120, 190, 120, 22], 'Value', 100);
    uilabel(pnl_param_sweep, 'Position', [10, 155, 110, 22], 'Text', 'Settling Time (s):');
    uieditfield(pnl_param_sweep, 'numeric', 'Position', [120, 155, 120, 22], 'Value', 0.1, 'Enable', 'off');
    chk_hysteresis = uicheckbox(pnl_param_sweep, 'Position', [10, 120, 200, 22], 'Text', 'Bi-directional Scan', 'Value', true);
    chk_bg_sweep = uicheckbox(pnl_param_sweep, 'Position', [10, 90, 140, 22], 'Text', 'Subtract Background', 'Value', true);
    lbl_bg_info = uilabel(pnl_param_sweep, 'Position', [155, 90, 100, 22], 'Text', 'BG: --- G', 'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.8]);
    chk_linear_fit = uicheckbox(pnl_param_sweep, 'Position', [10, 60, 200, 22], 'Text', 'Show Linear Fit (R^2)', 'Value', true);
    uilabel(pnl_param_sweep, 'Position', [10, 25, 110, 22], 'Text', 'Filename:');
    edit_filename_sweep = uieditfield(pnl_param_sweep, 'text', 'Position', [120, 25, 120, 22], 'Value', 'BI_Curve');
    
    %% 3B. 參數面板：Mode 2 波形產生器 (Step 3: Waveform Settings) - 移到第三層
    pnl_param_wave = uipanel(fig, 'Title', '3. Waveform Settings', 'Position', [20, 165, 260, 350], 'Visible', 'off', 'BackgroundColor', 'w', 'FontWeight', 'bold');
    
    uilabel(pnl_param_wave, 'Position', [10, 295, 110, 22], 'Text', 'Wave Type:');
    dd_wave_type = uidropdown(pnl_param_wave, 'Position', [120, 295, 120, 22], 'Items', {'Square Wave', 'Pulse Wave', 'Sine Wave'});
    uilabel(pnl_param_wave, 'Position', [10, 260, 110, 22], 'Text', 'Current Limit (A):', 'FontWeight', 'bold', 'FontColor', 'r');
    uieditfield(pnl_param_wave, 'numeric', 'Position', [120, 260, 120, 22], 'Value', 1.8, 'Enable', 'off');
    uilabel(pnl_param_wave, 'Position', [10, 225, 110, 22], 'Text', 'Amplitude (A):');
    edit_amp = uieditfield(pnl_param_wave, 'numeric', 'Position', [120, 225, 120, 22], 'Value', 1.0);
    uilabel(pnl_param_wave, 'Position', [10, 190, 110, 22], 'Text', 'Wave Freq (Hz):');
    edit_freq = uieditfield(pnl_param_wave, 'numeric', 'Position', [120, 190, 120, 22], 'Value', 1.0);
    uilabel(pnl_param_wave, 'Position', [10, 155, 110, 22], 'Text', 'Total Run Time (s):');
    edit_wave_time = uieditfield(pnl_param_wave, 'numeric', 'Position', [120, 155, 120, 22], 'Value', 10.0);
    
    % (取樣率 UI 已拔除！硬體極限防呆機制啟動)
    
    chk_split_wave = uicheckbox(pnl_param_wave, 'Position', [10, 85, 200, 22], 'Text', 'Split Graphs', 'Value', true); 
    uilabel(pnl_param_wave, 'Position', [10, 25, 110, 22], 'Text', 'Filename:');
    edit_filename_wave = uieditfield(pnl_param_wave, 'text', 'Position', [120, 25, 120, 22], 'Value', 'Waveform_Data');
    
    %% 4. 執行控制區 (最下方)
    btn_start = uibutton(fig, 'Position', [20, 95, 260, 60], 'Text', '▶ START MEASUREMENT', ...
        'FontSize', 15, 'FontWeight', 'bold', 'BackgroundColor', [0.47, 0.67, 0.19], 'FontColor', 'w', ...
        'Enable', 'off', 'ButtonPushedFcn', @startMeasurement);
    btn_stop = uibutton(fig, 'Position', [20, 25, 260, 60], 'Text', '⏹ EMERGENCY STOP', ...
        'FontSize', 15, 'FontWeight', 'bold', 'BackgroundColor', [0.85, 0.33, 0.10], 'FontColor', 'w', ...
        'Enable', 'off', 'ButtonPushedFcn', @stopMeasurement);
        
    %% 5. 右側繪圖區面板
    % 改成 pixel layout + SizeChangedFcn：左側控制區維持固定寬度，
    % 視窗放大時主要只放大右側波形區。
    pnl_plot = uipanel(fig, 'Units', 'pixels', 'Position', [310, 25, 620, 700], 'BackgroundColor', 'w');
    ax_main = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.9]);
    setupAxis(ax_main); 
    title(ax_main, 'Waiting for setup...'); xlabel(ax_main, 'Input Current (A)', 'FontWeight', 'bold'); ylabel(ax_main, 'Magnetic Field (Gauss)', 'FontWeight', 'bold');
    fig.SizeChangedFcn = @(~,~) resizeLayout();
    resizeLayout();
    
    %% ==========================================
    %% 內部 Callback 邏輯
    %% ==========================================
    function setupAxis(ax_h)
        grid(ax_h, 'on'); hold(ax_h, 'on');
        enableDefaultInteractivity(ax_h); 
        ax_h.Interactions = [panInteraction, zoomInteraction, dataTipInteraction]; 
    end

    function resizeLayout()
        % 讓 GUI 放大時：左側控制區維持原本 top-down 對齊，
        % 右側 plot panel 自動變大。
        %
        % 原本問題：START/STOP 被固定在視窗底部，
        % 視窗最大化後會在左側中間留下很大空白。
        % 現在做法：左側所有 panel/button 都由上往下排列，間距固定。
        fig_pos = fig.Position;
        fig_w = fig_pos(3);
        fig_h = fig_pos(4);

        left_x = 20;
        left_w = 260;
        plot_x = 310;
        margin_r = 20;
        margin_b = 25;
        margin_t = 20;
        gap = 10;

        % 左側固定 top-down stack。750 px 高度時會回到原本版面。
        y_conn  = fig_h - margin_t - 130;
        y_mode  = y_conn - gap - 65;
        y_param = y_mode - gap - 350;
        y_start = y_param - gap - 60;
        y_stop  = y_start - gap - 60;

        % 防止視窗被縮太小時按鈕跑到視窗外。
        if y_stop < 25
            y_stop = 25;
            y_start = y_stop + 60 + gap;
            y_param = y_start + 60 + gap;
            y_mode = y_param + 350 + gap;
            y_conn = y_mode + 65 + gap;
        end

        % 明確指定 pixels，避免最大化後被 AutoResizeChildren 或預設單位干擾。
        pnl_conn.Units = 'pixels';
        pnl_mode.Units = 'pixels';
        pnl_param_sweep.Units = 'pixels';
        pnl_param_wave.Units = 'pixels';
        % uibutton does not support the Units property in some MATLAB versions.
        % Position is already interpreted in pixels for uifigure-based buttons.

        pnl_conn.Position = [left_x, y_conn, left_w, 130];
        pnl_mode.Position = [left_x, y_mode, left_w, 65];
        pnl_param_sweep.Position = [left_x, y_param, left_w, 350];
        pnl_param_wave.Position  = [left_x, y_param, left_w, 350];
        btn_start.Position = [left_x, y_start, left_w, 60];
        btn_stop.Position  = [left_x, y_stop, left_w, 60];

        % 右側：隨視窗放大。
        plot_w = max(400, fig_w - plot_x - margin_r);
        plot_h = max(300, fig_h - margin_b - margin_t);
        pnl_plot.Position = [plot_x, margin_b, plot_w, plot_h];
    end
    
    function modeChanged(~, ~)
        pnl_param_sweep.Visible = 'off'; pnl_param_wave.Visible = 'off';
        if contains(dd_mode.Value, 'Mode 1'); pnl_param_sweep.Visible = 'on'; else; pnl_param_wave.Visible = 'on'; end
        resizeLayout();
    end
    
    function connectHW(~, ~)
        try
            lbl_status.Text = 'Connecting...'; drawnow; try delete(instrfind); catch; end 
            kepco = gpib('adlink', 0, edit_kepco.Value); fopen(kepco); 
            gm = gpib('adlink', 0, edit_gm.Value); fopen(gm); 
            
            try 
                fprintf(gm, 'RANGE 2');  
                fprintf(gm, 'RDGMODE 1,1,1,1,1'); 
            catch
                disp('Gaussmeter setting failed.');
            end
            
            lbl_status.Text = '🟢 Connected';
            lbl_status.FontColor = [0.47, 0.67, 0.19];
            btn_start.Enable = 'on'; btn_connect.Enable = 'off';
        catch ME
            uialert(fig, ['Connection Failed: ', ME.message], 'Hardware Error'); lbl_status.Text = '🔴 Failed';
        end
    end
    
    function stopMeasurement(~, ~)
        stop_flag = true; btn_stop.Text = 'Stopping...'; drawnow;
    end
    
    function startMeasurement(~, ~)
        btn_start.Enable = 'off'; btn_stop.Enable = 'on'; stop_flag = false;
        btn_stop.Text = '⏹ EMERGENCY STOP'; dd_mode.Enable = 'off';
        delete(pnl_plot.Children); 
        resizeLayout();
        try
            if contains(dd_mode.Value, 'Mode 1')
                runMode1_Sweep(); 
            else
                runMode2_Waveform(); 
            end
        catch ME
            uialert(fig, ['Error: ', ME.message], 'Execution Error'); safeShutdown();
        end
    end
    
    % ==========================================
    % Mode 1: 磁場掃描
    % ==========================================
    function runMode1_Sweep()
        s_I = edit_startI.Value; e_I = edit_endI.Value; 
        
        if s_I >= e_I
            uialert(fig, 'Start Current must be less than End Current!', 'Invalid Range', 'Icon', 'warning');
            safeShutdown(); return;
        end
        if abs(s_I) > 1.8 || abs(e_I) > 1.8
            uialert(fig, 'Sweep range exceeds 1.8A limit! Please set current within +/- 1.8A.', 'Safety Warning', 'Icon', 'warning');
            safeShutdown(); return;
        end
        
        step_I_mA = abs(edit_step.Value); step_I = step_I_mA / 1000; 
        if step_I == 0; step_I = 0.1; end 
        num_points = round(abs(e_I - s_I) / step_I) + 1;
        pause_T = 0.1; do_hyst = chk_hysteresis.Value; do_bg = chk_bg_sweep.Value; do_fit = chk_linear_fit.Value; 
        
        if isempty(gm); uialert(fig, 'Gaussmeter connection lost!', 'Error'); safeShutdown(); return; end
        
        fwd = linspace(s_I, e_I, num_points);
        if do_hyst
            step_calc = (e_I - s_I) / (num_points - 1); 
            rev = (e_I - step_calc) : -step_calc : s_I; 
            I_steps = [fwd, rev]; 
        else
            I_steps = fwd; 
        end
        
        B_data = nan(1, length(I_steps));
        fprintf(kepco, 'FUNC:MODE CURR'); fprintf(kepco, 'VOLT 20.0'); fprintf(kepco, 'CURR 0.0'); fprintf(kepco, 'OUTP ON');
        ax = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.08, 0.08, 0.9, 0.85]); setupAxis(ax);
        xlabel(ax, 'Input Current (A)'); ylabel(ax, 'Magnetic Field (Gauss)'); title(ax, 'Mode 1: B-I DC Sweep');
        xlim(ax, [s_I - 0.1, e_I + 0.1]);
        
        bg_val = 0;
        if do_bg
            title(ax, '⏳ Measuring background field...'); drawnow;
            pause(pause_T); fprintf(gm, 'RDGFIELD?'); bg_val = str2double(fscanf(gm));
            lbl_bg_info.Text = sprintf('BG: %.3f G', bg_val); 
            title(ax, 'Mode 1: B-I DC Sweep'); 
        end
        
        hLine = plot(ax, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
        
        loop_cnt = 0;
        for i = 1:length(I_steps)
            if stop_flag; break; end
            loop_cnt = loop_cnt + 1;
            
            fprintf(kepco, sprintf('CURR %.3f', I_steps(i))); pause(pause_T);
            fprintf(gm, 'RDGFIELD?'); B_data(i) = str2double(fscanf(gm)) - bg_val;
            
            if mod(loop_cnt, 2) == 0 || i == length(I_steps)
                set(hLine, 'XData', I_steps(1:i), 'YData', B_data(1:i));
                drawnow limitrate;
            end
        end
        
        safeShutdown();
        
        if ~stop_flag 
            valid_idx = ~isnan(B_data); vI = I_steps(valid_idx); vB = B_data(valid_idx);
            if do_fit && length(vI) > 1
                p = polyfit(vI, vB, 1); yf = polyval(p, vI); R = corrcoef(vI, vB);
                plot(ax, vI, yf, '--b', 'LineWidth', 1.5);
                legend(ax, 'Measured Data', sprintf('Linear Fit (R^2=%.4f)', R(1,2)^2), 'Location', 'northwest');
            else
                legend(ax, 'Measured Data', 'Location', 'northwest');
            end
            saveData_Sweep(ax, [vI', vB'], {'Current_A', 'Field_Gauss'}, edit_filename_sweep.Value); 
        end
    end

    % ==========================================
    % Mode 2: 波形產生器 (無即時繪圖)
    % ==========================================
    % ==========================================
    % Mode 2: 波形產生器
    % 改善版：Sine 與 Square/Pulse 使用不同策略
    % ==========================================
    function runMode2_Waveform()
        amp = edit_amp.Value;
        if abs(amp) > 1.8
            uialert(fig, 'Amplitude exceeds 1.8A limit!', 'Safety Warning', 'Icon', 'warning');
            safeShutdown(); return;
        end
        
        freq = edit_freq.Value; 
        t_run = edit_wave_time.Value; 
        do_split = chk_split_wave.Value;
        w_type = dd_wave_type.Value; 
        period = 1 / freq;
        is_sine = contains(w_type, 'Sine');
        
        % =====================================================
        % 固定 timing 參數
        % =====================================================
        update_hz = 20;                 % 20 Hz -> 0.05 s，一般可用的實測更新/讀取間隔
        Ts = 1.0 / update_hz;
        % look_ahead_time 與 step_settle_time 已放在程式上方統一設定。
        do_flush_each_read = false;     % 正式 loop 內不每圈 flush，減少額外 overhead

        points_per_cycle = update_hz / freq;
        if is_sine && points_per_cycle < 20
            warning_msg = sprintf(['Sine wave has only %.1f points/cycle at %.2f Hz.\n', ...
                'The commanded current may not look smooth.'], points_per_cycle, freq);
            uialert(fig, warning_msg, 'Waveform Warning', 'Icon', 'warning');
        end
        
        % 在 GUI 介面上放一個等待提示，避免即時繪圖拖慢 loop
        ax_wait = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.08, 0.08, 0.9, 0.85]);
        title(ax_wait, '⏳ Measuring waveform... Please Wait', 'FontSize', 16, 'Color', 'b');
        ax_wait.XAxis.Visible = 'off'; ax_wait.YAxis.Visible = 'off'; drawnow;

        fprintf(kepco, 'FUNC:MODE CURR'); 
        fprintf(kepco, 'VOLT 20.0'); 
        fprintf(kepco, 'CURR 0.0'); 
        fprintf(kepco, 'OUTP ON');
        pause(0.2);
        
        try flushinput(gm); catch; end 
        fprintf(gm, 'RDGFIELD?'); fscanf(gm); 
        
        % =====================================================
        % 預先配置資料欄位
        % Raw data 只放「真正讀到 Gaussmeter 的資料」，不再塞畫圖用假點。
        % =====================================================
        max_samples = ceil(t_run / Ts) + 500; 
        rec_t = nan(1, max_samples);
        rec_val = nan(1, max_samples);
        rec_B = nan(1, max_samples);
        rec_interval = nan(1, max_samples);
        rec_query_time = nan(1, max_samples);
        rec_kepco_time = nan(1, max_samples);
        rec_cmd_sent = false(1, max_samples);
        rec_loop_elapsed = nan(1, max_samples);
        loop_cnt = 0;
        last_read_time = NaN;
        last_target = NaN;

        % 只給 Square/Pulse 用：記錄實際送出 CURR 的時間，用來畫上方 input current。
        % 這樣如果使用 look_ahead_time 提前送指令，圖上也會一起提前，
        % 不會出現「磁場看起來比 input current 早變」的假象。
        cmd_time_log = [];
        cmd_current_log = [];

        % =====================================================
        % Sine wave：電流連續變化，所以每圈都更新 CURR
        % =====================================================
        if is_sine
            startTime = tic;
            while toc(startTime) <= t_run
                if stop_flag; break; end
                t_loop_start = tic;
                curr_t = toc(startTime);
                loop_cnt = loop_cnt + 1;

                % look_ahead_time 用於前饋補償：根據稍後的時間點計算目標電流
                predict_t = curr_t + look_ahead_time;
                target = amp * sin(2*pi*freq*predict_t);

                t_kepco = tic;
                fprintf(kepco, sprintf('CURR %.3f', target));
                rec_kepco_time(loop_cnt) = toc(t_kepco);
                rec_cmd_sent(loop_cnt) = true;

                t_gm = tic;
                if do_flush_each_read
                    try flushinput(gm); catch; end
                end
                fprintf(gm, 'RDGFIELD?');
                meas_B = str2double(fscanf(gm));
                rec_query_time(loop_cnt) = toc(t_gm);

                % V4-style timestamp for Sine Wave:
                % 用 loop 開始時間 curr_t 當作這一筆資料的時間點。
                % 這會讓 Sine Wave 顯示方式回到 V4 的平滑視覺效果。
                % 真正 Gaussmeter query 花多久仍記錄在 rec_query_time / rec_loop_elapsed。
                read_t = toc(startTime); %#ok<NASGU>
                rec_t(loop_cnt) = curr_t;
                rec_val(loop_cnt) = target;
                rec_B(loop_cnt) = meas_B;
                if ~isnan(last_read_time)
                    rec_interval(loop_cnt) = curr_t - last_read_time;
                end
                last_read_time = curr_t;

                elapsed = toc(t_loop_start);
                rec_loop_elapsed(loop_cnt) = elapsed;
                if elapsed < Ts
                    pause(Ts - elapsed);
                end
            end

        % =====================================================
        % Square / Pulse wave：電流只在 transition 時更新
        % =====================================================
        else
            % 初始狀態：沿用原本定義，t=0 時 square 為 +A，pulse 為 +A
            init_target = waveformTarget(w_type, amp, freq, 0);
            t_kepco = tic;
            fprintf(kepco, sprintf('CURR %.3f', init_target));
            init_kepco_time = toc(t_kepco);
            last_target = init_target;

            % 因為這個 initial command 是在 startTime = tic 之前送出的，
            % 所以在量測時間軸上視為 t = 0 的輸入電流狀態。
            cmd_time_log(end+1) = 0.0;
            cmd_current_log(end+1) = init_target;

            % 起始先等一次 settling，讓 t=0 之後的第一筆比較接近初始穩態
            pause(step_settle_time);
            startTime = tic;

            half_T = period / 2;
            transition_times = half_T:half_T:t_run;
            cmd_idx = 1;
            next_read_time = 0.0;

            while toc(startTime) <= t_run
                if stop_flag; break; end

                % 下一個理想 transition time
                if cmd_idx <= length(transition_times)
                    ideal_transition_t = transition_times(cmd_idx);
                    % 提早 look_ahead_time 送出 command，但不要小於 0
                    next_cmd_time = max(0, ideal_transition_t - look_ahead_time);
                else
                    ideal_transition_t = Inf;
                    next_cmd_time = Inf;
                end

                % Case 1：下一個事件是 current transition command
                if next_cmd_time <= next_read_time && next_cmd_time <= t_run
                    while toc(startTime) < next_cmd_time
                        pause(0.0005);
                    end

                    % 根據 transition 之後的理想時間決定新的電流值
                    target = waveformTarget(w_type, amp, freq, ideal_transition_t + 1e-9);

                    t_kepco = tic;
                    fprintf(kepco, sprintf('CURR %.3f', target));
                    this_kepco_time = toc(t_kepco);
                    actual_cmd_time = toc(startTime);

                    last_target = target;

                    % 記錄實際 command time，之後畫 input current 用這個時間，
                    % 不再用 ideal transition time。
                    cmd_time_log(end+1) = actual_cmd_time;
                    cmd_current_log(end+1) = target;

                    % 電流剛切換後，下一筆磁場讀值延後 step_settle_time
                    next_read_time = actual_cmd_time + step_settle_time;
                    cmd_idx = cmd_idx + 1;

                    % 記錄 command event 本身，但不記成 Gaussmeter raw data
                    % 下一筆真正的 rec_kepco_time 會在 read event 中保留 0。
                    if loop_cnt == 0
                        init_kepco_time = this_kepco_time; %#ok<NASGU>
                    end

                % Case 2：下一個事件是 Gaussmeter read
                else
                    if next_read_time > t_run
                        break;
                    end
                    while toc(startTime) < next_read_time
                        pause(0.0005);
                    end

                    loop_cnt = loop_cnt + 1;
                    t_loop_start = tic;

                    t_gm = tic;
                    if do_flush_each_read
                        try flushinput(gm); catch; end
                    end
                    fprintf(gm, 'RDGFIELD?');
                    meas_B = str2double(fscanf(gm));
                    rec_query_time(loop_cnt) = toc(t_gm);

                    read_t = toc(startTime);
                    rec_t(loop_cnt) = read_t;
                    rec_val(loop_cnt) = last_target;
                    rec_B(loop_cnt) = meas_B;
                    rec_cmd_sent(loop_cnt) = false;
                    rec_kepco_time(loop_cnt) = 0;
                    if ~isnan(last_read_time)
                        rec_interval(loop_cnt) = read_t - last_read_time;
                    end
                    last_read_time = read_t;
                    rec_loop_elapsed(loop_cnt) = toc(t_loop_start);

                    % 穩態區間下一筆讀值仍以 0.05 s 排程
                    next_read_time = next_read_time + Ts;
                end
            end
        end
        
        safeShutdown();
        
        % =====================================================
        % 事後繪圖與資料裁切
        % =====================================================
        delete(ax_wait);
        rec_t = rec_t(1:loop_cnt);
        rec_val = rec_val(1:loop_cnt);
        rec_B = rec_B(1:loop_cnt);
        rec_interval = rec_interval(1:loop_cnt);
        rec_query_time = rec_query_time(1:loop_cnt);
        rec_kepco_time = rec_kepco_time(1:loop_cnt);
        rec_cmd_sent = rec_cmd_sent(1:loop_cnt);
        rec_loop_elapsed = rec_loop_elapsed(1:loop_cnt);
        
        ideal_t = linspace(0, t_run, 5000);
        ideal_val = waveformTarget(w_type, amp, freq, ideal_t);

        % Build display-only magnetic-field data.
        % For sine wave, optional interpolation is used only for visual display.
        [field_plot_t, field_plot_B] = buildFieldPlotData(rec_t, rec_B, cmd_time_log, is_sine);

        if do_split
            ax_in = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.08, 0.55, 0.88, 0.38]); setupAxis(ax_in);
            ax_out = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.08, 0.08, 0.88, 0.38]); setupAxis(ax_out);
            
            if is_sine
                plot(ax_in, ideal_t, ideal_val, '-b', 'LineWidth', 1.8);
                hold(ax_in, 'on');
                if show_data_points_on_plot
                    plot(ax_in, rec_t, rec_val, 'k.', 'MarkerSize', 8);
                    if show_legend_on_plot
                        legend(ax_in, 'Ideal Current', 'Commanded Samples', 'Location', 'best');
                    end
                else
                    if show_legend_on_plot
                        legend(ax_in, 'Ideal Current', 'Location', 'best');
                    end
                end
            else
                if plot_square_pulse_input_as_actual_command
                    cmd_t_plot = [cmd_time_log(:); t_run];
                    cmd_i_plot = [cmd_current_log(:); cmd_current_log(end)];
                    stairs(ax_in, cmd_t_plot, cmd_i_plot, '-b', 'LineWidth', 1.8);
                    if show_legend_on_plot
                        legend(ax_in, 'Actual Commanded Current', 'Location', 'best');
                    end
                else
                    plot(ax_in, ideal_t, ideal_val, '-b', 'LineWidth', 1.8);
                    if show_legend_on_plot
                        legend(ax_in, 'Ideal Current', 'Location', 'best');
                    end
                end
            end
            ylabel(ax_in, 'Target Current (A)', 'FontWeight', 'bold');
            title(ax_in, ['Input Current: ', w_type]);
            ylim(ax_in, [-amp*1.2, amp*1.2]); xlim(ax_in, [0, t_run]);
            
            if show_data_points_on_plot
                plot(ax_out, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.2);
                hold(ax_out, 'on');
                plot(ax_out, rec_t, rec_B, 'ro', 'MarkerSize', 3);
            else
                plot(ax_out, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.8);
            end
            xlabel(ax_out, 'Time (s)', 'FontWeight', 'bold');
            ylabel(ax_out, 'Field (Gauss)', 'FontWeight', 'bold');
            title(ax_out, 'Measured Magnetic Field Response');
            xlim(ax_out, [0, t_run]);
            ax_to_save = {ax_in, ax_out};
        else
            ax_in = uiaxes(pnl_plot, 'Units', 'normalized', 'Position', [0.08, 0.08, 0.9, 0.85]); setupAxis(ax_in);
            yyaxis(ax_in, 'left');
            if is_sine
                plot(ax_in, ideal_t, ideal_val, '-b', 'LineWidth', 1.8); hold(ax_in, 'on');
                if show_data_points_on_plot
                    plot(ax_in, rec_t, rec_val, 'k.', 'MarkerSize', 8);
                end
            else
                if plot_square_pulse_input_as_actual_command
                    cmd_t_plot = [cmd_time_log(:); t_run];
                    cmd_i_plot = [cmd_current_log(:); cmd_current_log(end)];
                    stairs(ax_in, cmd_t_plot, cmd_i_plot, '-b', 'LineWidth', 1.8); hold(ax_in, 'on');
                else
                    plot(ax_in, ideal_t, ideal_val, '-b', 'LineWidth', 1.8); hold(ax_in, 'on');
                end
            end
            ylabel(ax_in, 'Target Current (A)', 'FontWeight', 'bold'); ylim(ax_in, [-amp*1.2, amp*1.2]);
            yyaxis(ax_in, 'right');
            if show_data_points_on_plot
                plot(ax_in, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.2);
                hold(ax_in, 'on');
                plot(ax_in, rec_t, rec_B, 'ro', 'MarkerSize', 3);
            else
                plot(ax_in, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.8);
            end
            ylabel(ax_in, 'Field (Gauss)', 'FontWeight', 'bold');
            xlabel(ax_in, 'Time (s)', 'FontWeight', 'bold');
            title(ax_in, ['Waveform Response: ', w_type]);
            xlim(ax_in, [0, t_run]);
            ax_to_save = {ax_in};
        end
        
        if ~stop_flag
            data_out = [rec_t', rec_val', rec_B', rec_interval', rec_query_time', rec_kepco_time', double(rec_cmd_sent'), rec_loop_elapsed'];
            col_out = {'Time_s', 'Current_A', 'Field_Gauss', 'Read_Interval_s', 'Gaussmeter_Query_Time_s', 'Kepco_Command_Time_s', 'Command_Sent', 'Loop_Elapsed_s'};
            saveData_Waveform(ax_to_save, data_out, col_out, edit_filename_wave.Value, do_split, ideal_t, ideal_val, is_sine, cmd_time_log, cmd_current_log); 
        end
    end

    function target = waveformTarget(w_type, amp, freq, t)
        period = 1 / freq;
        if contains(w_type, 'Sine')
            target = amp .* sin(2*pi*freq.*t);
        else
            is_hi = mod(t, period) < (period*0.5);
            if contains(w_type, 'Square')
                target = (is_hi*2 - 1) .* amp;
            else
                target = is_hi .* amp;
            end
        end
    end


    function [field_plot_t, field_plot_B] = buildFieldPlotData(read_t, read_B, actual_cmd_t, is_sine_wave)
        % Build display-only data for magnetic-field plot.
        %
        % For sine wave:
        %   The raw samples are still saved to Excel, but the displayed curve can
        %   be interpolated to look like the older V4 smooth line. This does not
        %   create new measured data; it is only for visualization.
        %
        % For square/pulse:
        %   Insert display-only anchor points at current-command times so that
        %   the connected magnetic-field line does not visually start changing
        %   before the input-current transition.
        read_t = read_t(:);
        read_B = read_B(:);

        valid = ~isnan(read_t) & ~isnan(read_B);
        read_t = read_t(valid);
        read_B = read_B(valid);

        if isempty(read_t)
            field_plot_t = read_t;
            field_plot_B = read_B;
            return;
        end

        if is_sine_wave
            % V4-style sine display:
            % 直接用實際記錄的 rec_t / rec_B 畫紅線，不做 pchip interpolation，
            % 也不加入 Square/Pulse 用的 transition anchor。
            % 這樣 Sine Wave 的磁場圖會回到 V4 的畫法與視覺效果。
            field_plot_t = read_t;
            field_plot_B = read_B;
            return;
        end

        if ~add_field_transition_anchor_on_plot || isempty(actual_cmd_t)
            field_plot_t = read_t;
            field_plot_B = read_B;
            return;
        end
        cmd_t = actual_cmd_t(:);
        cmd_t = cmd_t(cmd_t > 0);  % ignore initial command at t = 0

        field_plot_t = [];
        field_plot_B = [];

        for ii = 1:length(read_t)
            if ii > 1
                % Commands that occurred between the previous measured point
                % and this measured point.
                cmd_between = cmd_t(cmd_t > read_t(ii-1) & cmd_t < read_t(ii));

                for jj = 1:length(cmd_between)
                    field_plot_t(end+1,1) = cmd_between(jj); %#ok<AGROW>
                    field_plot_B(end+1,1) = read_B(ii-1);    %#ok<AGROW>
                end
            end

            field_plot_t(end+1,1) = read_t(ii); %#ok<AGROW>
            field_plot_B(end+1,1) = read_B(ii); %#ok<AGROW>
        end
    end

    function safeShutdown()
        try fprintf(kepco, 'CURR 0.0'); pause(0.2); fprintf(kepco, 'OUTP OFF'); catch; end
        btn_start.Enable = 'on'; btn_stop.Enable = 'off'; dd_mode.Enable = 'on';
        btn_stop.Text = '⏹ EMERGENCY STOP'; 
        if stop_flag; uialert(fig, 'Measurement Aborted by User.', 'Stopped'); end
    end
    
    % (Mode 1 的存檔函數維持不變)
    function saveData_Sweep(target_ax, data_mat, col_names, base_name)
        file_idx = 0;
        while true
            if file_idx == 0; f_xlsx = sprintf('%s.xlsx', base_name); f_fig = sprintf('%s.fig', base_name);
            else; f_xlsx = sprintf('%s(%d).xlsx', base_name, file_idx); f_fig = sprintf('%s(%d).fig', base_name, file_idx); end
            if ~isfile(f_xlsx) && ~isfile(f_fig); break; end
            file_idx = file_idx + 1;
        end
        writetable(array2table(data_mat, 'VariableNames', col_names), f_xlsx);
        
        hf = figure('Visible', 'off', 'Color', 'w'); % 確保報告匯出時背景為純白
        ha = axes('Parent', hf);
        plot(ha, data_mat(:, 1), data_mat(:, 2), '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); grid on; hold on;
        if length(target_ax.Children) > 1
            fit_line = findobj(target_ax.Children, 'Color', 'b', 'LineStyle', '--');
            if ~isempty(fit_line); plot(ha, fit_line.XData, fit_line.YData, '--b', 'LineWidth', 1.5); end
            legend(ha, 'Measured Data', target_ax.Legend.String{2}, 'Location', 'northwest');
        else
            legend(ha, 'Measured Data', 'Location', 'northwest');
        end
        xlabel('Current (A)'); ylabel('Field (Gauss)'); title('B-I Sweep Result');
        set(hf, 'Visible', 'on'); savefig(hf, f_fig); close(hf);
        
        uialert(fig, sprintf('Success!\nSaved:\n%s\n%s', f_xlsx, f_fig), 'Complete', 'Icon', 'success');
    end
    
    function saveData_Waveform(~, data_mat, col_names, base_name, do_split, ideal_t, ideal_val, is_sine_wave, actual_cmd_t, actual_cmd_i)
        file_idx = 0;
        while true
            if file_idx == 0; f_xlsx = sprintf('%s.xlsx', base_name); f_fig = sprintf('%s.fig', base_name);
            else; f_xlsx = sprintf('%s(%d).xlsx', base_name, file_idx); f_fig = sprintf('%s(%d).fig', base_name, file_idx); end
            if ~isfile(f_xlsx) && ~isfile(f_fig); break; end
            file_idx = file_idx + 1;
        end
        writetable(array2table(data_mat, 'VariableNames', col_names), f_xlsx);
        
        hf = figure('Visible', 'off', 'Color', 'w'); %
        if do_split
            ha1 = subplot(2,1,1, 'Parent', hf);
            if is_sine_wave || isempty(actual_cmd_t) || ~plot_square_pulse_input_as_actual_command
                plot(ha1, ideal_t, ideal_val, '-b', 'LineWidth', 1.8);
                title(ha1, 'Ideal Input Current');
            else
                cmd_t_plot = [actual_cmd_t(:); max(data_mat(:,1))];
                cmd_i_plot = [actual_cmd_i(:); actual_cmd_i(end)];
                stairs(ha1, cmd_t_plot, cmd_i_plot, '-b', 'LineWidth', 1.8);
                title(ha1, 'Actual Commanded Current');
            end
            grid on;
            ylabel(ha1, 'Target Current (A)', 'FontWeight', 'bold');
            
            ha2 = subplot(2,1,2, 'Parent', hf);
            [field_plot_t, field_plot_B] = buildFieldPlotData(data_mat(:,1), data_mat(:,3), actual_cmd_t, is_sine_wave);
            if show_data_points_on_plot
                plot(ha2, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.2); hold(ha2, 'on');
                plot(ha2, data_mat(:,1), data_mat(:,3), 'ro', 'MarkerSize', 3);
            else
                plot(ha2, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.8);
            end
            grid on;
            xlabel(ha2, 'Time (s)', 'FontWeight', 'bold'); ylabel(ha2, 'Field (Gauss)', 'FontWeight', 'bold'); title(ha2, 'Measured Magnetic Field Response');
        else
            ha = axes('Parent', hf);
            yyaxis(ha, 'left');
            if is_sine_wave || isempty(actual_cmd_t) || ~plot_square_pulse_input_as_actual_command
                plot(ha, ideal_t, ideal_val, '-b', 'LineWidth', 1.8);
            else
                cmd_t_plot = [actual_cmd_t(:); max(data_mat(:,1))];
                cmd_i_plot = [actual_cmd_i(:); actual_cmd_i(end)];
                stairs(ha, cmd_t_plot, cmd_i_plot, '-b', 'LineWidth', 1.8);
            end
            ylabel(ha, 'Target Current (A)', 'FontWeight', 'bold');
            yyaxis(ha, 'right');
            [field_plot_t, field_plot_B] = buildFieldPlotData(data_mat(:,1), data_mat(:,3), actual_cmd_t, is_sine_wave);
            if show_data_points_on_plot
                plot(ha, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.2); hold(ha, 'on');
                plot(ha, data_mat(:,1), data_mat(:,3), 'ro', 'MarkerSize', 3);
            else
                plot(ha, field_plot_t, field_plot_B, '-r', 'LineWidth', 1.8);
            end
            ylabel(ha, 'Field (Gauss)', 'FontWeight', 'bold');
            xlabel(ha, 'Time (s)', 'FontWeight', 'bold'); title(ha, 'Waveform Response'); grid on;
        end
        set(hf, 'Visible', 'on'); savefig(hf, f_fig); close(hf);
        
        uialert(fig, sprintf('Success!\nSaved:\n%s\n%s', f_xlsx, f_fig), 'Complete', 'Icon', 'success');
    end
    
    fig.CloseRequestFcn = @(~,~) closeApp();
    function closeApp()
        try if ~isempty(kepco); fprintf(kepco, 'CURR 0.0'); pause(0.2); fprintf(kepco, 'OUTP OFF'); fclose(kepco); end; catch; end
        delete(fig);
    end
end