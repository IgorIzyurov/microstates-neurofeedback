clear;
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-ICA'); end
vis_stream();
% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving chunked data...');
emptychunks = 0;
datachunks = 0;
DATA = nan(72,173500);
tic
while true
    % get chunk from the inlet
    [chunk,stamps] = inlet.pull_chunk();
    if ~isempty(chunk)
        ChLen = size(chunk,2);
        idxStart = find(isnan(DATA(1,:)));
        idxStart = idxStart(1);
        if idxStart + ChLen - 1 >= 173500
            disp('Finished!');
            break
        end
        DATA(:, idxStart:idxStart+ChLen-1 ) = chunk;
        DATA_uptomoment = [DATA_uptomoment chunk];
        if rem(round(toc),2) == 0
            clc;
            disp(['Recorded ' num2str(round(toc)) ' seconds']);
            plot(DATA_uptomoment(1:3,:));
        end
    else
        continue
    end
%     if ~isempty(chunk)
%         datachunks = datachunks + 1;
%     else
%         emptychunks = emptychunks + 1;
%     end
%     for s=1:length(stamps)
%         % and display it
%         fprintf('%.2f\t',chunk(:,s));
%         fprintf('%.5f\n',stamps(s));
%     end
end
