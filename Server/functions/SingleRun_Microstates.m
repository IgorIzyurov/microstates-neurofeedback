%%%% Script for Neurofeedback Run %%%%

% Some parameters
Qchan = 63; % quantity of channels
ch = [1:Qchan]; % number of the channel, in which we are interested
Srate = 5000; % Hz, Sampling rate of the incoming data
RegSeconds = 6; % Seconds, time of each feedback regulation period
Ntrials = 14; % quantity of trials of each type of regulation (Ntrials - up, Ntrials - down, 2*Ntrials - rest)
window = options.screen.windowPtr;
options.Srate = Srate;
options.TrialLengthSeconds = RegSeconds;
RegTimepoints = Srate*RegSeconds;
MSofInterest = 3;
% define markers
markers.PAU = 100;

markers.CSR = 10;
markers.CSD = 11;
markers.CSU = 12;

markers.FBE = 20;
markers.FBD = 21;
markers.FBU = 22;

% Generate random sequence of trials
[EpochsTL, TimePointsTL] = GenSeq_MS(Ntrials, RegSeconds, Srate);

% define some variables
DATA = nan(Qchan, length(TimePointsTL));
FB_DATA = nan(Qchan,RegTimepoints);
GFP_DATA = nan(1,RegTimepoints);
if useTmpl
    TemplateMaps = load([subjFolder '\MSmaps\MSMaps_temp.mat']); TemplateMaps = TemplateMaps.TemplateMaps;
else
    TemplateMaps = load([savePath '\MSmaps\MSMaps_ind.mat']); TemplateMaps = TemplateMaps.TemplateMaps;
end

MicrostateTime = nan(4, length(TimePointsTL));
MSparams.FitPar.nClasses = 4; % The number of classes to fit
MSparams.PeakFit = 1; % Whether to fit only the GFP peaks and interpolate in between, false otherwise
MSparams.b = 8; % Window size for label smoothing (0 for none) (in ms)
MSparams.lambda = 0.3; %  Penalty function for non-smoothness
MSparams.BControl = false; % % Kill microstates truncated by boundaries
Feedback_Value = nan(2, Ntrials);

    
% Load condition stimuli pictures
scaling = 1.0;

PicRegUp.Pic = imread('RegUp.jpg');
PicRegUp.Texture = Screen('MakeTexture', window, PicRegUp.Pic);
[PicRegUp.height, PicRegUp.width, ~] = size(PicRegUp.Pic);
PicRegUp.Position = [round(options.screen.xCenter-PicRegUp.width*scaling/2),...
    round(options.screen.yCenter-PicRegUp.height*scaling/2),...
    round(PicRegUp.width*scaling)+round(options.screen.xCenter-PicRegUp.width*scaling/2),...
    round(PicRegUp.height*scaling)+round(options.screen.yCenter-PicRegUp.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]

PicRegDwn.Pic = imread('RegDwn.jpg');
PicRegDwn.Texture = Screen('MakeTexture', window, PicRegDwn.Pic);
[PicRegDwn.height, PicRegDwn.width, ~] = size(PicRegDwn.Pic);
PicRegDwn.Position = [round(options.screen.xCenter-PicRegDwn.width*scaling/2),...
    round(options.screen.yCenter-PicRegDwn.height*scaling/2),...
    round(PicRegDwn.width*scaling)+round(options.screen.xCenter-PicRegDwn.width*scaling/2),...
    round(PicRegDwn.height*scaling)+round(options.screen.yCenter-PicRegDwn.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]

PicRest.Pic = imread('Rest.jpg');
PicRest.Texture = Screen('MakeTexture', window, PicRest.Pic);
[PicRest.height, PicRest.width, ~] = size(PicRest.Pic);
PicRest.Position = [round(options.screen.xCenter-PicRest.width*scaling/2),...
    round(options.screen.yCenter-PicRest.height*scaling/2),...
    round(PicRest.width*scaling)+round(options.screen.xCenter-PicRest.width*scaling/2),...
    round(PicRest.height*scaling)+round(options.screen.yCenter-PicRest.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]



%%%                                    %%%
%%% RECEIVE THE FEEDBACK SIGNAL ONLINE %%%
%%%                                    %%%
disp('Loading the library...');
lib = lsl_loadlib();
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});
disp('Now receiving chunked data...');

%%%           %%%
%%% MAIN LOOP %%%
%%%           %%%

current_timepoint = 1; % current timepoint of the experiment
previous_timepoint = 1;
chunkstart_timepoint = 1; % previous timepoint of the experiment
trial_counter_up = 0;
trial_counter_dwn = 0;
FinishRecording = 0;

while true
%     pause(0.1);
    % get chunk from the inlet
    [chunk,~] = inlet.pull_chunk();
   
    % Remove ECG and CWL (delete later)
        
    if ~isempty(chunk)
        chunk = chunk([1:31 33:64], :);
        chunkout = [];
        while isempty(chunkout)
            chunkout=egb_fftfilter_Igor(chunk, Srate, 2,20,'bandp');
            [chunk1,~] = inlet.pull_chunk();
            chunk1 = chunk1([1:31 33:64], :);
            chunk = [chunk chunk1];
        end
        chunk = chunkout;
        % averagereference
        chunk = AvgRef ( chunk );
        % count at which timepoint of the experiment we are and save the data
         current_timepoint = chunkstart_timepoint + size(chunk,2) - 1;
            if current_timepoint > length(TimePointsTL)
                current_timepoint = length(TimePointsTL);
                chunk = chunk(:,1:current_timepoint - chunkstart_timepoint+1);
                FinishRecording = 1;
            end
        current_flag = TimePointsTL{current_timepoint};
        previous_flag = TimePointsTL{previous_timepoint};
        DATA(:,chunkstart_timepoint:current_timepoint) = chunk;
        
        % Now we decide what to do, according to timepoint flag
        if isequal(current_flag(1:2),'FB') % it is time to process feedback
            if isequal(previous_flag(1:2),'FB')
                fb_current_timepoint_local = fb_previous_timepoint_local + size(chunk,2) - 1;
                feedbackstart_chunk_idx = 1:size(chunk,2);
            else
                tic
                % find part of chunk, which contains timepoints of Feedback Epoch and timepoint of feedback start
                flags_in_chunk = TimePointsTL(chunkstart_timepoint:current_timepoint);
                flags_in_chunk = cellfun(@(x) x(1:2),flags_in_chunk,'UniformOutput',false);
                feedbackstart_chunk_idx = find(arrayfun(@(x) isequal(x,{'FB'}),flags_in_chunk));
                feedbackstart_timepoint = feedbackstart_chunk_idx(1) + chunkstart_timepoint - 1; % the experiment timepoint at which feedback started
                fb_previous_timepoint_local = 1; % we set our local feedback time
                fb_current_timepoint_local = length(feedbackstart_chunk_idx);
            end
            if isequal(current_flag,'FBU') && ~isequal(previous_flag,'FBU')
                trial_counter_up = trial_counter_up + 1;
            end
            if isequal(current_flag,'FBD') && ~isequal(previous_flag,'FBD')
                trial_counter_dwn = trial_counter_dwn + 1;
            end
            chunk = chunk(:,feedbackstart_chunk_idx);
            

            
            % save the incoming data into variable
            FB_DATA(:,fb_previous_timepoint_local:fb_current_timepoint_local) = chunk;
            % calculate GFP
            GFP_DATA(:,fb_previous_timepoint_local:fb_current_timepoint_local) = std(chunk,1,1);
            fb_previous_timepoint_local = fb_current_timepoint_local + 1;
            
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
                MicrostateTime(:,current_timepoint) = MSinSeconds;
                clc;
                disp(['A: ' num2str(SecondsInMS1)]);
                disp(['B: ' num2str(SecondsInMS2)]);
                disp(['C: ' num2str(SecondsInMS3)]);
                disp(['D: ' num2str(SecondsInMS4)]);
                disp(['Totl: ' num2str(Total)]);
                if isequal(current_flag,'FBZ')
                    CurrentFB = 1; PreviousFB = 1; MaximalFB = 1;
                    DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Rest');
                elseif isequal(current_flag,'FBU')
                    Feedback_Value(1,trial_counter_up) = MSinSeconds(MSofInterest);
                    CurrentFB = Feedback_Value(1,trial_counter_up);
                    if trial_counter_up ~= 1
                        MaximalFB = max(Feedback_Value(1,1:trial_counter_up-1),[],'omitnan');
                        PreviousFB = Feedback_Value(1,trial_counter_up-1);
                    else
                        MaximalFB = max(Feedback_Value(1,1:trial_counter_up),[],'omitnan');
                        PreviousFB = Feedback_Value(1,trial_counter_up);
                    end
                    DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, 'Upreg');
                elseif isequal(current_flag,'FBD')
                    Feedback_Value(2,trial_counter_dwn) = MSinSeconds(MSofInterest);
                    CurrentFB = Feedback_Value(2,trial_counter_dwn);
                    if trial_counter_dwn ~= 1
                        MinimalFB = min(Feedback_Value(2,1:trial_counter_dwn-1),[],'omitnan');
                        PreviousFB = Feedback_Value(2,trial_counter_dwn-1);
                    else
                        MinimalFB = min(Feedback_Value(2,1:trial_counter_dwn),[],'omitnan');
                        PreviousFB = Feedback_Value(2,trial_counter_dwn);
                    end
                    DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MinimalFB, 'Downreg');
                end
            end

            
        elseif isequal(current_flag(1:2),'CS') % check if we want to show any of the Condition Stimuli (CS)
            if isequal(current_flag,'CSZ') && ~isequal(previous_flag,'CSZ') || previous_timepoint == 1
                FB_DATA = nan(Qchan,RegTimepoints);
                GFP_DATA = nan(1,RegTimepoints);
                sendEvent(markers.CSR);
                %%% SHOW REST STIMULI %%%
                Screen('DrawTexture', window, PicRest.Texture, [], PicRest.Position);
                Screen('Flip', window);
            elseif isequal(current_flag,'CSU') && ~isequal(previous_flag,'CSU') || previous_timepoint == 1
                FB_DATA = nan(Qchan,RegTimepoints);
                GFP_DATA = nan(1,RegTimepoints);
                sendEvent(markers.CSU);
                %%% SHOW REGULATION STIMULI %%%
                Screen('DrawTexture', window, PicRegUp.Texture, [], PicRegUp.Position);
                Screen('Flip', window);
            elseif isequal(current_flag,'CSD') && ~isequal(previous_flag,'CSD') || previous_timepoint == 1
                FB_DATA = nan(Qchan,RegTimepoints);
                GFP_DATA = nan(1,RegTimepoints);
                sendEvent(markers.CSD);
                %%% SHOW REGULATION STIMULI %%%
                Screen('DrawTexture', window, PicRegDwn.Texture, [], PicRegDwn.Position);
                Screen('Flip', window);
            end
        elseif isequal(current_flag,'PAU')  % Pause code
            if ~isequal(previous_flag,'PAU')
                tic
                sendEvent(markers.PAU);
                %%% SHOW EMPTY SCREEN %%%
                PauseEpochScreen(options);
            end
        end
        if FinishRecording == 1
            break
        end
        chunkstart_timepoint = current_timepoint + 1;
        previous_timepoint = current_timepoint;
    else
        % we do not want to deal with empty data
        continue
    end 
end
Output.DATA = DATA;
Output.options = options;
Output.TimePointsTL = TimePointsTL;
Output.Feedback = Feedback_Value;
Output.MSparams = MSparams;
Output.MSofInterest = MSofInterest;
Output.MicrostateTime = MicrostateTime;

save([savePath 'OutputFB_' Output.ID '_Session_' num2str(Output.Day) '_Run_' num2str(Run) '.mat'], 'Output');