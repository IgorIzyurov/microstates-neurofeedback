clear
Receive = tcpip('192.168.1.1', 30000, 'NetworkRole', 'server');
Send = tcpip('192.168.1.1', 20000, 'NetworkRole', 'client');
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


TimeLine = cell(1,500000);
TimepointIdx = 0;
while true
    if Receive.BytesAvailable ~=0
        TimepointIdx = TimepointIdx+1;
        clc;
%         data = fscanf(Receive,Receive.BytesAvailable);
        input = fscanf(Receive);
        input = strcat(input);
        flag = input(1:3);
        data = str2double(input(4:end));
        TimeLine{1,TimepointIdx} = flag;
        TimeLine{2,TimepointIdx} = data(1);
        if isequal(flag,'END')
            break
        end
    end
end
fclose(Receive);

TL = []; TP = [];
for c=1:length(TimeLine)
    if ~isempty(TimeLine{1,c})
        TL = [TL TimeLine(1,c)];
        TP = [TP TimeLine(2,c)];
    end
end
    