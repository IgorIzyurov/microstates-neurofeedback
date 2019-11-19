clear;
disp('RUNNING BANDPASS 2-20 Hz');
cd ([fileparts(which('BPF_2_20Hz.m')) '\']);
%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-ICA'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'EEG-BPF','EEG-BPF',63,500,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

disp('Now receiving data...');
SWSize = 100;
chunk1 = []; 
% c = 0;
% s = GetSecs;
while true
%         clc;
    
    [chunk,~] = inlet.pull_chunk();
    chunk1 = [chunk1 chunk];
    if ~isempty(chunk1) && size(chunk1,2) >= SWSize
        % bandpass 2-20Hz
        chunkout=egb_fftfilter_Igor(chunk1, 500, 2,20,'bandp');
        outlet.push_chunk(chunkout);
%         c = c+1; d = GetSecs - s;
%         disp(num2str([size(chunkout,2) c d]));
        chunk1 = [];
%         s = GetSecs;
    else
        continue
    end
end
