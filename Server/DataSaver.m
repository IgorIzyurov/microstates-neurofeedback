clear;
fs_RAW = 5000;
fs_MR = 5000;
fs_CWL = 500;
fs_ICA = 500;
fs_BPF = 500;
% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve stream: RAW DATA
disp('Resolving a stream: RAW EEG ...');
result_RAW = {};
while isempty(result_RAW)
    result_RAW = lsl_resolve_byprop(lib,'type','EEG'); end
% create a new inlet
disp('Opening an inlet...');
inlet_RAW = lsl_inlet(result_RAW{1});

% resolve stream: MR-corrected DATA
disp('Resolving a stream: MR EEG ...');
result_MR = {};
while isempty(result_MR)
    result_MR = lsl_resolve_byprop(lib,'type','EEG-MR'); end
% create a new inlet
disp('Opening an inlet...');
inlet_MR = lsl_inlet(result_MR{1});

% resolve stream: CWL-corrected DATA
disp('Resolving a stream: CWL EEG ...');
result_CWL = {};
while isempty(result_CWL)
    result_CWL = lsl_resolve_byprop(lib,'type','EEG-MR-CWL'); end
% create a new inlet
disp('Opening an inlet...');
inlet_CWL = lsl_inlet(result_CWL{1});

% resolve stream: ICA-corrected DATA
disp('Resolving a stream: ICA EEG ...');
result_ICA = {};
while isempty(result_ICA)
    result_ICA = lsl_resolve_byprop(lib,'type','EEG-ICA'); end
% create a new inlet
disp('Opening an inlet...');
inlet_ICA = lsl_inlet(result_ICA{1});

% resolve stream: BPF (2-20 Hz) DATA
disp('Resolving a stream: BPF EEG ...');
result_BPF = {};
while isempty(result_BPF)
    result_BPF = lsl_resolve_byprop(lib,'type','EEG-BPF'); end
% create a new inlet
disp('Opening an inlet...');
inlet_BPF = lsl_inlet(result_BPF{1});

DATA_RAW = nan(72,500000);  TIMESTAMP_RAW = nan(1,500000);
DATA_MR = nan(72,500000);  TIMESTAMP_MR = nan(1,500000);
DATA_CWL = nan(72,50000);  TIMESTAMP_CWL = nan(1,500000);
DATA_ICA = nan(63,50000);  TIMESTAMP_ICA = nan(1,500000);
DATA_BPF = nan(63,50000);  TIMESTAMP_BPF = nan(1,500000);

tstart_RAW = 1; tend_RAW = 1;
tstart_MR = 1; tend_MR = 1;
tstart_CWL = 1; tend_CWL = 1;
tstart_ICA = 1; tend_ICA = 1;
tstart_BPF = 1; tend_BPF = 1;
disp('Start recording');
secsrecorded_RAW = 0;
secsrecorded_MR = 0;
secsrecorded_CWL = 0;
secsrecorded_ICA = 0;
secsrecorded_BPF = 0;
lastts_RAW = 0;
lastts_MR = 0;
lastts_CWL = 0;
lastts_ICA = 0;
lastts_BPF = 0;
while true
    [chunk_RAW,timestamp_RAW] = inlet_RAW.pull_chunk();
    [chunk_MR,timestamp_MR] = inlet_MR.pull_chunk();
    [chunk_CWL,timestamp_CWL] = inlet_CWL.pull_chunk();
    [chunk_ICA,timestamp_ICA] = inlet_ICA.pull_chunk();
    [chunk_BPF,timestamp_BPF] = inlet_BPF.pull_chunk();

    if ~isempty(chunk_RAW)
        
        tend_RAW = tstart_RAW + length(timestamp_RAW) - 1;
        DATA_RAW(:,tstart_RAW:tend_RAW) = chunk_RAW;
        TIMESTAMP_RAW(1,tstart_RAW:tend_RAW) = timestamp_RAW;
        tstart_RAW = tend_RAW + 1;
        secsrecorded_RAW = length(TIMESTAMP_RAW(:,(~isnan(TIMESTAMP_RAW))))/fs_RAW;
        lastts_RAW = timestamp_RAW(end);
    end
    if ~isempty(chunk_MR)

        tend_MR = tstart_MR + length(timestamp_MR) - 1;
        DATA_MR(:,tstart_MR:tend_MR) = chunk_MR;
        TIMESTAMP_MR(1,tstart_MR:tend_MR) = timestamp_MR;
        tstart_MR = tend_MR + 1;
        secsrecorded_MR = length(TIMESTAMP_MR(:,(~isnan(TIMESTAMP_MR))))/fs_MR;
        lastts_MR = timestamp_MR(end);
    end
    if ~isempty(chunk_CWL)

        tend_CWL = tstart_CWL + length(timestamp_CWL) - 1;
        DATA_CWL(:,tstart_CWL:tend_CWL) = chunk_CWL;
        TIMESTAMP_CWL(1,tstart_CWL:tend_CWL) = timestamp_CWL;
        tstart_CWL = tend_CWL + 1;
        secsrecorded_CWL = length(TIMESTAMP_CWL(:,(~isnan(TIMESTAMP_CWL))))/fs_CWL;
        lastts_CWL = timestamp_CWL(end);
    end
    if ~isempty(chunk_ICA)

        tend_ICA = tstart_ICA + length(timestamp_ICA) - 1;
        DATA_ICA(:,tstart_ICA:tend_ICA) = chunk_ICA;
        TIMESTAMP_ICA(1,tstart_ICA:tend_ICA) = timestamp_ICA;
        tstart_ICA = tend_ICA + 1;
        secsrecorded_ICA = length(TIMESTAMP_ICA(:,(~isnan(TIMESTAMP_ICA))))/fs_ICA;
        lastts_ICA = timestamp_ICA(end);
    end
    if ~isempty(chunk_BPF)

        tend_BPF = tstart_BPF + length(timestamp_BPF) - 1;
        DATA_BPF(:,tstart_BPF:tend_BPF) = chunk_BPF;
        TIMESTAMP_BPF(1,tstart_BPF:tend_BPF) = timestamp_BPF;
        tstart_BPF = tend_BPF + 1;
        secsrecorded_BPF = length(TIMESTAMP_BPF(:,(~isnan(TIMESTAMP_BPF))))/fs_BPF;
        lastts_BPF = timestamp_BPF(end);
    end
    clc
    disp(['RAW ' num2str(secsrecorded_RAW)]);
    disp(['MR ' num2str(secsrecorded_MR)]);
    disp(['CWL ' num2str(secsrecorded_CWL)]);
    disp(['ICA ' num2str(secsrecorded_ICA)]);
    disp(['BPF ' num2str(secsrecorded_BPF)]);
    disp(['Delay RAW-BPF ' num2str(lastts_RAW - lastts_BPF)]);
end

