
Receive = tcpip('10.171.11.132', 20000, 'NetworkRole', 'server');
Send = tcpip('10.171.11.132', 19000, 'NetworkRole', 'client');
set(Receive, 'InputBufferSize', 900000);
set(Send, 'InputBufferSize', 900000);

fopen(Send);
markerStart = 1;
pause(1)
fwrite(Send,markerStart)
fclose(Send);

fprintf('waiting\n');
fopen(Receive);
fprintf('connected');
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

TimeLine = cell(1,500000);
TimepointIdx = 0;
while true
    if Receive.BytesAvailable ~=0
        clc;
        input = fscanf(Receive);
        input = strcat(input);
        flag = input(1:3);
        data = str2num(input(4:end));
        data = data(2:end);
        disp(flag);
        disp(data);
        if isequal(flag(1:2),'CS')
            TimepointIdx = TimepointIdx + 1;
            TimeLine{1,TimepointIdx} = flag;
            if isequal(flag(3),'Z') && ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                Screen('DrawTexture', options.screen.windowPtr, PicRest.Texture, [], PicRest.Position);
                Screen('Flip', options.screen.windowPtr);
                sendEvent(markers.CSR);
            elseif isequal(flag(3),'U') && ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                Screen('DrawTexture', options.screen.windowPtr, PicRegUp.Texture, [], PicRegUp.Position);
                Screen('Flip', options.screen.windowPtr);
                sendEvent(markers.CSU);
            elseif isequal(flag(3),'D') && ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                Screen('DrawTexture', options.screen.windowPtr, PicRegDwn.Texture, [], PicRegDwn.Position);
                Screen('Flip', options.screen.windowPtr);
                sendEvent(markers.CSD);
            end
        elseif isequal(flag(1:2),'FB')
            TimepointIdx = TimepointIdx + 1;
            TimeLine{1,TimepointIdx} = flag;
            CurrentFB = data(1);
            PreviousFB = data(2);
            MaximalFB = data(3);
            if isequal(flag(3), 'Z')
                DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Rest');
                if ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                    sendEvent(markers.FBZ);
                end
            elseif isequal(flag(3), 'U')
                DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Upreg');
                if ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                    sendEvent(markers.FBU);
                end
            elseif isequal(flag(3), 'D')
                DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Downreg');
                if ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                    sendEvent(markers.FBD);
                end
            end
        elseif isequal(flag(1:2),'PA')
            TimepointIdx = TimepointIdx + 1;
            TimeLine{1,TimepointIdx} = flag;
                if ~isequal(TimeLine{1,TimepointIdx-1},TimeLine{1,TimepointIdx})
                    PauseEpochScreen(options);
                    sendEvent(markers.PAU);
                end
        elseif isequal(flag(1:2),'EN')
            TimepointIdx = TimepointIdx + 1;
            TimeLine{1,TimepointIdx} = flag;
            sendEvent(markers.END);
            break
        elseif isequal(flag(1:2),'RU')
            TimepointIdx = TimepointIdx + 1;
            TimeLine{1,TimepointIdx} = flag;
            sendEvent(markers.RUN);
        end
    end
end
fclose(Receive);

