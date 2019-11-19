clear; close all;
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
resultnoise = {};
while isempty(resultnoise)
    resultnoise = lsl_resolve_byprop(lib,'type','EEG-MR'); end

resultclean = {};
while isempty(resultclean)
    resultclean = lsl_resolve_byprop(lib,'type','EEG-MR-CWL'); end

% create a new inlet
disp('Opening an inlet...');
inletnoise = lsl_inlet(resultnoise{1});
inletclean = lsl_inlet(resultclean{1});

disp('Now receiving chunked data...');

% vis_stream();
% vis_stream();
% vis_stream('EEG-MR-noise',5,150,[1:64],5000,10);
DATA_uptomoment_noise = nan(72,5000000);
DATA_uptomoment_clean = nan(72,5000000);
RecordTime = 20;
tic
while true
    % get chunk from the inlet
    [chunk_noise,stamps_noise] = inletnoise.pull_chunk();
%     chunk_noise = chunk_noise([1:31 33:64], :);
    [chunk_clean,stamps_clean] = inletclean.pull_chunk();
%     chunk_clean = chunk_clean([1:31 33:64], :);
%     chunk_clean = chunk_clean([1:31 33:64], :);
    if ~isempty(chunk_noise)
        idx_start = find(isnan(DATA_uptomoment_noise(1,:)),1);
        idx_end = idx_start + size(chunk_noise,2) - 1;
        DATA_uptomoment_noise(:,idx_start:idx_end) = chunk_noise;
    else
        continue
    end
    if ~isempty(chunk_clean)
        idx_start = find(isnan(DATA_uptomoment_clean(1,:)),1);
        idx_end = idx_start + size(chunk_clean,2) - 1;
        DATA_uptomoment_clean(:,idx_start:idx_end) = chunk_clean;
    else
        continue
    end
    clc;
    disp(round(toc))
    if round(toc) >= RecordTime
        break
    end
end
DATA_uptomoment_clean = DATA_uptomoment_clean(:,all(~isnan(DATA_uptomoment_clean)));
DATA_uptomoment_noise = DATA_uptomoment_noise(:,all(~isnan(DATA_uptomoment_noise)));

plotEEGchan(DATA_uptomoment_noise, 'All ch', 'MR-corrected');
plotEEGchan(DATA_uptomoment_noise, 'CWL', 'MR-corrected');
plotEEGchan(DATA_uptomoment_clean, 'All ch', 'MR + CWL');
plotEEGchan(DATA_uptomoment_clean, 'CWL', 'MR + CWL');

save('MR.mat','DATA_uptomoment_noise')
save('MR_CWL.mat','DATA_uptomoment_clean')


function [] = plotEEGchan(DATA, doCWL, Titel)
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