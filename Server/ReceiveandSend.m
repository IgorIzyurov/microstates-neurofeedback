clear
%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-ICA-d'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'EEG-bandp','EEG-bandp',63,500,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

disp('Now receiving data...');
while true
    [chunk,~] = inlet.pull_chunk();
    if ~isempty(chunk)
        % bandpass 2-20Hz
        chunkout = [];
        while true
            if isempty(chunkout)
                [chunk1,~] = inlet.pull_chunk();
                chunk = [chunk chunk1];
            else
                break
            end
            chunkout=egb_fftfilter_Igor(chunk, 500, 2,20,'bandp');
        end
        outlet.push_chunk(chunkout);
    end
end
