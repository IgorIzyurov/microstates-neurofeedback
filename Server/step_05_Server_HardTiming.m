%%% EEG-MICROSTATES NEUROFEEDBACK %%%
%%% This code runs the single NF run, receives preprocessed signal,
%%% calculates the microstates occurence in trial and sends via TCP/IP the
%%% time, spent in a certain microstate to the Client

clear;
addpath([fileparts(which('step_05_Server_HardTiming.m')) '\functions\']);
%%%                                    %%%
%%% Generate subject ID and session N  %%%
%%%    If subj = 0, then ID = 'TEST'   %%%
load('NF_SubjID.mat');
Output.SubjN = input('Enter the Subject Number: ');
useTmpl = input('Use template MS? (1/0) ');
Output.Day = input('Enter the Session Number: ');
ExperimentFolder = 'D:\EEG-NF-DATA\PILOT\';
% Some parameters
Qchan = 63; % quantity of channels
ch = [1:Qchan]; % number of the channel, in which we are interested
Srate = 500; % Hz, Sampling rate of the incoming data

MSofInterest = 3;
if Output.Day == 0 || isstr(Output.Day) || Output.SubjN == 0
    Output.ID = input('Enter the Subject ID: ','s');
%     subjFolder = [ExperimentFolder Output.ID '\'];
else
    Output.ID = ID_pool{Output.SubjN};
    % Load generated sequence of trials
    subjFolder = [ExperimentFolder Output.ID '\'];
    load([subjFolder '\TimeLine\' Output.ID '_TimeLine_' num2str(Output.Day) '.mat']);
    EpochsTL = EpochsTL_OneSession{1}; TimePointsTL = TimePointsTL_OneSession{1};
end
disp(['Subject ' Output.ID ' Session ' num2str(Output.Day) ' started!']);
%%%

%%%% Script for Neurofeedback Run %%%%
if useTmpl
    TemplateMaps = load('MSMaps_temp.mat'); TemplateMaps = TemplateMaps.TemplateMaps;
else
    TemplateMaps = load([subjFolder '\MSmaps\MSMaps_ind.mat']); TemplateMaps = TemplateMaps.TemplateMaps;
end

MSparams.FitPar.nClasses = 4; % The number of classes to fit
MSparams.PeakFit = 1; % Whether to fit only the GFP peaks and interpolate in between, false otherwise
MSparams.b = 8; % Window size for label smoothing (0 for none) (in ms)
MSparams.lambda = 0.3; %  Penalty function for non-smoothness
MSparams.BControl = false; % % Kill microstates truncated by boundaries
MSparams.TemplateMaps = TemplateMaps;

%%%                                    %%%
%%%  Create connection to the client   %%%
%%%  and wait for the user to start    %%%
Receive = tcpip('10.171.11.125',19000,'NetworkRole','server');
% Receive = tcpip('192.168.1.2',19000,'NetworkRole','server');
Send = tcpip('10.171.11.125',20000,'NetworkRole','client');
% Send = tcpip('192.168.1.2',20000,'NetworkRole','client');
ICAStreamName = 'EEG-BPF';

%%%                                    %%%
%%% RECEIVE THE FEEDBACK SIGNAL ONLINE %%%
%%%                                    %%%
disp('Loading the library...');
lib = lsl_loadlib();
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type',ICAStreamName);
end

% create a new inlet
inlet = lsl_inlet(result{1});
disp('Now receiving chunked data...');




% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'TESTDELAY','TESTDELAY',63,500,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

%%%           %%%
%%% MAIN LOOP %%%
%%%           %%%
TrialCounter_Reg = 0;
WaitForFeedback = true;
StopRecording = false;
AllFB_DWN = []; AllFB_UP = [];

disp('Waiting for Participant to start...');
fopen(Receive);
while true
    pause(0.5);
    a = Receive.BytesAvailable;
    if Receive.BytesAvailable ~=0
        input = fscanf(Receive);
        input = strcat(input);
        flag = input(1:3);
        if isequal(flag,'RUN')
            data = str2num(input(4:end));
            ExpDurSec = data(1);
            ExpDurTimepts = ExpDurSec*Srate;
            RegSeconds = data(2);
            RegTimepoints = Srate*RegSeconds;
            Ntrials = data(3); % Ntrials - number of trials of EACH REGULATION type (Ntrials up, Ntrials down, 2*Ntrials rest)
            % define some variables
            DATA = nan(Qchan, RegTimepoints, Ntrials, 2);
            FB_DATA = nan(Qchan,RegTimepoints);
            GFP_DATA = nan(1,RegTimepoints);
            MicrostateTime = nan(4, RegTimepoints, Ntrials, 2);
            MicrostateClassTC = nan(RegTimepoints, Ntrials, 2);
            Feedback_Value = nan(2, Ntrials);
            Clues = {};
            break
        end
    end
end
disp('Client connected');
 fopen(Send);
disp('Run Started');
while true
    if Receive.BytesAvailable~=0
        input = fscanf(Receive);
        input = strcat(input);
        flag = input(1:3);
        if isequal(flag, 'CSR')
            WaitForFeedback = true;
            FB_DATA = nan(Qchan,RegTimepoints);
            GFP_DATA = nan(1,RegTimepoints);
            if exist('MSClass','var')
                MicrostateClassTC(1:length(MSClass), TrialCounter_Reg, UpOrDown) = MSClass;
            end
        elseif isequal(flag, 'END')
            break
        end
    end
    while WaitForFeedback
        disp('WaitForFeedback')
        [chunk,~] = inlet.pull_chunk();
        outlet.push_chunk(chunk);
        if Receive.BytesAvailable~=0
            input = fscanf(Receive);
            input = strcat(input);
            flag = input(1:3);
            if isequal(flag(1:2), 'FB')
                WaitForFeedback = false;
                fb_idx_start = 1;
                data = str2num(input(4:end));
                TrialCounter_Reg = data(2);
                if isequal(flag, 'FBU')
                    UpOrDown = 1;
                elseif isequal(flag, 'FBD')
                    UpOrDown = 2;
                end
                break
            end
        end
        clc
    end
    
    
    [chunk,~] = inlet.pull_chunk();
    if ~isempty(chunk)
        % averagereference
        chunk = AvgRef ( chunk );
        % Save data and GFP
        fb_idx_end = fb_idx_start + size(chunk,2) - 1;
        DATA(:, fb_idx_start:fb_idx_end, TrialCounter_Reg, UpOrDown) = chunk;
        FB_DATA(:,fb_idx_start:fb_idx_end) = chunk;
        GFP_DATA(:,fb_idx_start:fb_idx_end) = std(chunk,1,1);
        Clues = [Clues {flag}];
        % calculation of time spent in certain microstate
        GFP_uptomoment = GFP_DATA;
        GFP_uptomoment(:,isnan(GFP_uptomoment))=[];
        IsGFPPeak = find([false (GFP_uptomoment(1,1:end-2) < GFP_uptomoment(1,2:end-1) & GFP_uptomoment(1,2:end-1) > GFP_uptomoment(1,3:end)) false]);
        FB_uptomoment = FB_DATA;
        FB_uptomoment(:,isnan(FB_uptomoment(1,:)))=[];
        MSinSeconds = nan(4,1);
        SecondsInMS1 = 0; SecondsInMS2 = 0; SecondsInMS3 = 0; SecondsInMS4 = 0;
        if length(IsGFPPeak) > 1
            [MSClass, ~, ~] = AssignMStates_Igor(FB_uptomoment, Srate, TemplateMaps, MSparams, 1);
            TimepointsInMS1 = sum(MSClass == 1);
            SecondsInMS1 = TimepointsInMS1/Srate;
            MSinSeconds(1,1) = SecondsInMS1;
            TimepointsInMS2 = sum(MSClass == 2);
            SecondsInMS2 = TimepointsInMS2/Srate;
            MSinSeconds(2,1) = SecondsInMS2;
            TimepointsInMS3 = sum(MSClass == 3);
            SecondsInMS3 = TimepointsInMS3/Srate;
            MSinSeconds(3,1) = SecondsInMS3;
            TimepointsInMS4 = sum(MSClass == 4);
            SecondsInMS4 = TimepointsInMS4/Srate;
            MSinSeconds(4,1) = SecondsInMS4;
            Total = SecondsInMS1 + SecondsInMS2 + SecondsInMS3 + SecondsInMS4;
            MicrostateTime(:,fb_idx_start:fb_idx_end, TrialCounter_Reg,UpOrDown) = MSinSeconds.*ones(length(MSinSeconds),length(fb_idx_start:fb_idx_end));
            clc;
            disp(['A: ' num2str(SecondsInMS1,'%.2f') ' ' num2str(100*SecondsInMS1/Total,'%.1f') ' %']);
            disp(['B: ' num2str(SecondsInMS2,'%.2f') ' ' num2str(100*SecondsInMS2/Total,'%.1f') ' %']);
            disp(['C: ' num2str(SecondsInMS3,'%.2f') ' ' num2str(100*SecondsInMS3/Total,'%.1f') ' %']);
            disp(['D: ' num2str(SecondsInMS4,'%.2f') ' ' num2str(100*SecondsInMS4/Total,'%.1f') ' %']);
            disp(['Totl: ' num2str(Total)]);
            
            if isequal(flag,'FBU')
                disp(['Upreg trial ' num2str(TrialCounter_Reg) ' of ' num2str(Ntrials)]);
                Feedback_Value(1,TrialCounter_Reg) = MSinSeconds(MSofInterest);
                CurrentFB = Feedback_Value(1,TrialCounter_Reg);
                AllFB_UP = [AllFB_UP CurrentFB];
                if TrialCounter_Reg ~= 1
                    MaximalFB = max(Feedback_Value(1,1:TrialCounter_Reg-1),[],'omitnan');
                    PreviousFB = Feedback_Value(1,TrialCounter_Reg-1);
                else
                    MaximalFB = max(Feedback_Value(1,1:TrialCounter_Reg),[],'omitnan');
                    PreviousFB = Feedback_Value(1,TrialCounter_Reg);
                end
                MinOrMaxFB = MaximalFB;
            elseif isequal(flag,'FBD')
                disp(['Downreg trial ' num2str(TrialCounter_Reg) ' of ' num2str(Ntrials)]);
                Feedback_Value(2,TrialCounter_Reg) = MSinSeconds(MSofInterest);
                CurrentFB = Feedback_Value(2,TrialCounter_Reg);
                AllFB_DWN = [AllFB_DWN CurrentFB];
                if TrialCounter_Reg ~= 1
                    MinimalFB = min(Feedback_Value(2,1:TrialCounter_Reg-1),[],'omitnan');
                    PreviousFB = Feedback_Value(2,TrialCounter_Reg-1);
                else
                    MinimalFB = min(Feedback_Value(2,1:TrialCounter_Reg),[],'omitnan');
                    PreviousFB = Feedback_Value(2,TrialCounter_Reg);
                end
                MinOrMaxFB = MinimalFB;
            end
            SendWhat = [num2str(CurrentFB) ' ' num2str(PreviousFB) ' ' num2str(MinOrMaxFB) ' ' num2str(Total)];
            fprintf(Send,SendWhat);
            outlet.push_chunk(chunk);
        end
        fb_idx_start = fb_idx_end + 1;
    else
        % we do not want to deal with empty data
        continue
    end
    
end
fclose(Send);fclose(Receive);

% Saving the big Output with all nessesary information
Output.Srate = Srate;
Output.RegSeconds = RegSeconds;
Output.MSofInterest = MSofInterest;
Output.Ntrials = Ntrials;
% Output.EpochsTL = EpochsTL;
% Output.TimePointsTL = TimePointsTL;
Output.MSparams = MSparams;
Output.MicrostateTime = MicrostateTime;
Output.Feedback_Value = Feedback_Value;
Output.DATA = DATA;
Output.Clues = Clues;
Output.MicrostateClassTC = MicrostateClassTC;
% SaveFolder = [subjFolder 'Output\'];
% if ~exist(SaveFolder,'dir')
%     mkdir(SaveFolder);
% end
% save([SaveFolder  Output.ID '_' num2str(Output.Day) '_Output.mat', 'Output']);
save([ Output.ID '_' num2str(Output.Day) '_Output.mat'], 'Output');