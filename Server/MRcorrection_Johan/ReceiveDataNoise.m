clear
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-MR-noise'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving chunked data...');
c=0;
QChunk = 100;
DATA = [];
while true
    % get chunk from the inlet
    [chunk,stamps] = inlet.pull_chunk();
    c=c+1;
    clc;
    disp(['chunk ' num2str(c) ' received']);
    DATA = [DATA chunk];
%     for s=1:length(stamps)
%         % and save it
%         
%     end
    pause(0.05);
    if c == QChunk
        break;
    end
end
figure;
plot(DATA(1,:))
save('DataNoise.mat','DATA');