clear; close all;
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
resultnoise = {};
while isempty(resultnoise)
    resultnoise = lsl_resolve_byprop(lib,'type','EEG-MR-noise'); end

resultclean = {};
while isempty(resultclean)
    resultclean = lsl_resolve_byprop(lib,'type','EEG-MR-clean'); end

resultmarkers = {};
while isempty(resultmarkers)
    resultmarkers = lsl_resolve_byprop(lib,'type','Markers'); end

% create a new inlet
disp('Opening an inlet...');
inletnoise = lsl_inlet(resultnoise{1});
inletclean = lsl_inlet(resultclean{1});
inletmrk = lsl_inlet(resultmarkers{1});

disp('Now receiving chunked data...');

vis_stream();
% vis_stream();
% vis_stream('EEG-MR-noise',5,150,[1:64],5000,10);
DATA_uptomoment_noise = [];
DATA_uptomoment_clean = [];
while true
    % get chunk from the inlet
    [chunk_noise,stamps_noise] = inletnoise.pull_chunk();
    [chunk_clean,stamps_clean] = inletclean.pull_chunk();
    [mrks,ts] = inletmrk.pull_sample();
    if ~isempty(chunk_noise)
        DATA_uptomoment_noise = [DATA_uptomoment_noise chunk_noise];
    else
        continue
    end
    if ~isempty(chunk_clean)
        DATA_uptomoment_clean = [DATA_uptomoment_clean chunk_clean];
    else
        continue
    end
end
figure;
plot(DATA_uptomoment_clean(1:3,100000:110000)');
title('MR corrected double64')
figure;
plot(DATA_uptomoment_noise');
title('Uncorrected double64')
save('Uncorr.mat','DATA_uptomoment_noise')
save('Corr.mat','DATA_uptomoment_clean')