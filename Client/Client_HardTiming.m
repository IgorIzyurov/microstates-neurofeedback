
Receive = tcpip('10.171.11.132', 20000, 'NetworkRole', 'server');
Send = tcpip('10.171.11.132', 19000, 'NetworkRole', 'client');
set(Receive, 'InputBufferSize', 900000);
set(Send, 'InputBufferSize', 900000);

% define markers
markers.PAU = 100;

markers.CSR = 10;
markers.CSD = 11;
markers.CSU = 12;

markers.FBZ = 20;
markers.FBD = 21;
markers.FBU = 22;

markers.RUN = 01;
markers.END = 02;

[EpochsTL, TimePointsTL] = GenSeq_MS(Ntrials, RegSeconds, Srate);
if isequal(Run, 1) || isequal(Run, 3)
    for tr = 1:length(EpochsTL)
        if isequal(EpochsTL(tr), 'D')
            EpochsTL(tr) = 'U';
        end
    end
elseif isequal(Run, 2) || isequal(Run, 4)
    for tr = 1:length(EpochsTL)
        if isequal(EpochsTL(tr), 'U')
            EpochsTL(tr) = 'D';
        end
    end
else
    % for transfer runs
    ExperimentDuration = ExperimentDuration/2;
    [EpochsTL, TimePointsTL] = GenSeq_MS(Ntrials/2, RegSeconds, Srate);
end




DrawFormattedText(options.screen.windowPtr,['Press any key to start!\nRun ' num2str(Run)], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
AnyKeyWait(allkeys);
% sca
pause(0.1)
fopen(Send);pause(0.1)
fprintf(Send,['RUN' ' ' num2str(ExperimentDuration) ' ' num2str(RegSeconds) ' ' num2str(Ntrials)]);
sendEvent(markers.RUN);
fopen(Receive);
fprintf('connected');
TimeStart = GetSecs;
TimePassed = GetSecs - TimeStart;
TrialCounter_Rest = 0;
TrialCounter_Reg = 0;
TrialCounter_Up = 0;
TrialCounter_Dwn = 0;
junk = 0;
while true
    TimePassed = GetSecs - TimeStart;
    if TimePassed >= ExperimentDuration
        break
    end
    % Show CS: Rest for 2 sec
    Screen('DrawTexture', options.screen.windowPtr, PicRest.Texture, [], PicRest.Position);
    Screen('Flip', options.screen.windowPtr);
    fprintf(Send,'CSR');
    sendEvent(markers.CSR);
    WaitSecs(2.0);
    % Show pause 2 sec
    PauseEpochScreen(options);
    sendEvent(markers.PAU);
    WaitSecs(2.0);
    % Show Rest Feedback for N s
    TrialCounter_Rest = TrialCounter_Rest + 1;
    CurrentFB = 1; PreviousFB = 1; MaximalFB = 1;
    DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Rest');
    sendEvent(markers.FBZ);
    WaitSecs(RegSeconds);
    % Show CS: Regulation 2 sec
    TrialCounter_Reg = TrialCounter_Reg + 1;
    WhichReg = EpochsTL(TrialCounter_Reg + TrialCounter_Rest);
    flag = ['FB' WhichReg];
    if isequal(flag, 'FBU')
        Screen('DrawTexture', options.screen.windowPtr, PicRegUp.Texture, [], PicRegUp.Position);
        sendEvent(markers.CSU);
    elseif isequal(flag, 'FBD')
        Screen('DrawTexture', options.screen.windowPtr, PicRegDwn.Texture, [], PicRegDwn.Position);
        sendEvent(markers.CSD);
    end
    Screen('Flip', options.screen.windowPtr);
    WaitSecs(2.0);
    clc
    % Show pause 2 sec
    PauseEpochScreen(options);
    sendEvent(markers.PAU);
    WaitSecs(2.0);
    if Receive.BytesAvailable ~=0
        input = fscanf(Receive);
        input = strcat(input);
        disp('junk input!');
        disp(input);
        junk = 1;
    end
    % Show Regulation Feedback for N s
    ALL_FB = [];
    if isequal(Run, 1) || isequal(Run, 3) || isequal(Run, 2) || isequal(Run, 4)
        if isequal(flag, 'FBU')
            TrialCounter_Up = TrialCounter_Up + 1;
            sendEvent(markers.FBU);
            fprintf(Send,[flag ' ' num2str(TrialCounter_Reg) ' ' num2str(TrialCounter_Up)]);
        elseif isequal(flag, 'FBD')
            TrialCounter_Dwn = TrialCounter_Dwn + 1;
            sendEvent(markers.FBD);
            fprintf(Send,[flag ' ' num2str(TrialCounter_Reg) ' ' num2str(TrialCounter_Dwn)]);
        else
            sca
            error('Wrong flag');
        end
        FB_Start = GetSecs; FB_Finish = 0;
        while FB_Finish <= RegSeconds
            FB_Finish = GetSecs - FB_Start;
            if Receive.BytesAvailable ~=0
                %             clc;
                input = fscanf(Receive);
                input = strcat(input);
                data = str2num(input);
                %             disp(flag);
                %             disp(input);
                CurrentFB = data(1);
                PreviousFB = data(2);
                MaximalFB = data(3);
                ALL_FB = [ALL_FB CurrentFB];
                if junk==0
                    if isequal(flag, 'FBU')
                        DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Upreg');
                    elseif isequal(flag, 'FBD')
                        DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Downreg');
                    end
                end
                junk=0;
            end
        end
    else
        if isequal(flag, 'FBU')
            TrialCounter_Up = TrialCounter_Up + 1;
            sendEvent(markers.FBU);
            fprintf(Send,[flag ' ' num2str(TrialCounter_Reg) ' ' num2str(TrialCounter_Up)]);
        elseif isequal(flag, 'FBD')
            TrialCounter_Dwn = TrialCounter_Dwn + 1;
            sendEvent(markers.FBD);
            fprintf(Send,[flag ' ' num2str(TrialCounter_Reg) ' ' num2str(TrialCounter_Dwn)]);
        else
            sca
            error('Wrong flag');
        end
        FB_Start = GetSecs; FB_Finish = 0;
        while FB_Finish <= RegSeconds
            FB_Finish = GetSecs - FB_Start;
            if Receive.BytesAvailable ~=0
                %             clc;
                input = fscanf(Receive);
                input = strcat(input);
                data = str2num(input);
                %             disp(flag);
                %             disp(input);
                CurrentFB = data(1);
                PreviousFB = data(2);
                MaximalFB = data(3);
                ALL_FB = [ALL_FB CurrentFB];
                if junk==0
                    if isequal(flag, 'FBU')
                        CurrentFB = 1; PreviousFB = 1; MaximalFB = 1;
                        DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Rest');
                    elseif isequal(flag, 'FBD')
                        CurrentFB = 1; PreviousFB = 1; MaximalFB = 1;
                        DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Rest');
                    end
                end
                junk=0;
            end
        end
    end
    delay = data(4) - RegSeconds;
    disp(['Delay ' num2str(delay)]);
end
fprintf(Send,'END');
sendEvent(markers.END);
fclose(Receive);
fclose(Send);

% DrawFormattedText(window,'END.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
% sca