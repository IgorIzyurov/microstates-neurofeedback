%%%                              %%%
%%% TEMPORARY: GENERATE SINUSOID %%%
%         TEST_DrawSinusoid
%%%                              %%%
%%%                              %%%

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

disp('Now receiving data...');
c = 0;
DATA = [];
FB = [];
% Main loop
while true
    c = c + 1;
    % get data from the inlet
    [vec,ts] = inlet.pull_sample();
    DATA = [DATA vec'];
    [FeedbackValue] = RelativeAmplitudeCalculation(ForPSD, NFBfreqRange, ch, Srate, HamWin);
    FB = [FB FeedbackValue];
%     DrawFeedback(screen, FeedbackValue, THRESHOLD, options.fixationFig, options.BGColor, options.wantBackgroundGrid);
    if c == 10000
        break;
    end
end














