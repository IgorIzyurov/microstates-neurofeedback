
function [] = plotEEGchan(DATA, doCWL, Titel, RecordTime)
counter = 0;
figure; hold on
timewindow = [1:size(DATA,2)];
if isequal(doCWL,'CWL')
    channels = [72-6:72];
    Titel = [Titel ' CW chans'];
else
    channels = [1:31,33:64];
end
for ch = channels
    plot(DATA(ch,timewindow) + counter)
    counter = counter - 50;
end
title(Titel)
end