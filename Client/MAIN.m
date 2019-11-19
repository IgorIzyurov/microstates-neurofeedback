%%% MAIN EEG FEEDBACK SCRIPT %%%

close all
clear            
clc        
sca

% add path with nessesary functions and images  sca
doRuns = {'0','1', '2', 'Tr1', '3', '4','Tr2'};


folder = fileparts(which('MAIN.m')); sca

% addpath(genpath(folder));
addpath([fileparts(which('MAIN.m')) '\functions']);
addpath([fileparts(which('MAIN.m')) '\images']);
                
PsychDefaultSetup(2);

% [options] = OpenTheScreen(0); % Makes the nessesary inputs and runs PTB. Input: 1 - skips sync tests
SkipSync=1;
if SkipSync
    Screen('Preference', 'SkipSyncTests', 1);
end
options.fixationFig = 'cross'; % 'cross' || 'dot'
options.wantBackgroundGrid = 0; % 1 if want grid of lines at the background

options.BGColorRight = 'ForestGreen'; % Set the color of background circle for upregulation
options.BGColorRight = rgb(options.BGColorRight); % code it to RGB triplet
options.BGColorLeft = 'BlueViolet'; % Set the color of background circle for upregulation
options.BGColorLeft = rgb(options.BGColorLeft); % code it to RGB triplet
options.textparam.font = 'Helvetica'; % set the text parameters
options.textparam.fontsize = 56; %44

% If Microstates Feedback
options.CurrentColor = 'Gainsboro';
options.CurrentColor = round(255*rgb(options.CurrentColor)); 
options.PreviousColor = 'Moccasin';
options.PreviousColor = round(255*rgb(options.PreviousColor)); 
options.MaxColor = 'Crimson';
options.MaxColor = round(255*rgb(options.MaxColor)); 
% Setup PTB with some default values
PsychDefaultSetup(2);
% Lets make a screen
windowOpts.windowed = 0; % If true, will run experiment in a window
if windowOpts.windowed == 1
   
    windowOpts.screen_num = max(Screen('Screens'));
    screen_rect = Screen('Rect',0);
    [mx,my] = RectCenter(screen_rect);
    windowOpts.window_width = 600;
    windowOpts.window_height = 500;
    windowOpts.window_size = [mx-windowOpts.window_width/2,my-windowOpts.window_height/2, mx+windowOpts.window_width/2,my+windowOpts.window_height/2];
elseif windowOpts.windowed == 0
    if SkipSync

        windowOpts.screen_num = max(Screen('Screens'));
%         windowOpts.screen_num = 2; % On Igor's computer
    else
        windowOpts.screen_num = max(Screen('Screens')); % On Igor's computer
    end
    windowOpts.window_size = []; % Full screen
end

screen.Color = BlackIndex(windowOpts.screen_num); % Define black and white        
scr.white = WhiteIndex(windowOpts.screen_num);
% [window, rect] = PsychImaging('OpenWindow', windowOpts.screen_num, screen.Color);
[window, rect] = Screen('OpenWindow', windowOpts.screen_num, screen.Color,windowOpts.window_size,32,2);
% Flip to clear
Screen('Flip', window);
        
% Query the frame duration
options.ifi = Screen('GetFlipInterval', window);
% [S.window, S.windowRect] = PsychImaging('OpenWindow', windowOpts.screen_num, screen.Color, [], 32, 2);
% [window, rect] = Screen('OpenWindow', windowOpts.screen_num, screen.Color); % Open an on screen window
[scrWidth, scrHeight] = Screen('WindowSize',window); % Get the size of the on screen window
Screen('TextSize',window,options.textparam.fontsize);
Screen('TextFont',window,options.textparam.font);
% Set blend function for alpha blending
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(rect);

% Make coords for line grid
if options.wantBackgroundGrid
    [GridCoords] = MakeCoordsGrid (10, scrHeight);
    screen.GridCoords = GridCoords;
end
if scrWidth > scrHeight
    options.MaxFBScreen = scrHeight - 100;
else
    options.MaxFBScreen = scrWidth - 100;
end

screen.windowOpts = windowOpts;
screen.xCenter = xCenter;
screen.yCenter = yCenter;
screen.windowPtr = window;
screen.rect = rect;
screen.scrWidth = scrWidth;
screen.scrHeight = scrHeight;
options.screen = screen;


% Some parameters
Qchan = 63; % quantity of channels
ch = [1:Qchan]; % number of the channel, in which we are interested
Srate = 500; % Hz, Sampling rate of the incoming data
RegSeconds = 36; % Seconds, time of each feedback regulation period
PauseSeconds = 2; ClueSeconds = 2;
Ntrials = 4; % quantity of trials of each type of regulation (Ntrials - up, Ntrials - down, 2*Ntrials - rest)
options.Srate = Srate;
options.TrialLengthSeconds = RegSeconds;
RegTimepoints = Srate*RegSeconds;
MSofInterest = 3;
ExperimentDuration = 4*Ntrials*(RegSeconds + PauseSeconds + ClueSeconds); % Seconds
options.ExperimentDuration = ExperimentDuration;
% Define the keyboard keys that are listened for.
KbName('UnifyKeyNames');
options.keys.space = KbName('SPACE');
options.keys.one = KbName('3#');
options.keys.two = KbName('4$');
options.keys.three = KbName('1!');
options.keys.scannertrigger = KbName('5%');
% DisableKeysForKbCheck([allkeys(~isnan(allkeys))]);
allkeys = zeros(1,256);
keysofinterest = [options.keys.space,options.keys.one,options.keys.two,options.keys.three];
allkeys(keysofinterest) = 1;
options.keys.allkeys = allkeys;

% Load condition stimuli pictures
scaling = 1.0;
PicRegUp.Pic = imread('RegUp.jpg');
PicRegUp.Texture = Screen('MakeTexture', options.screen.windowPtr, PicRegUp.Pic);
[PicRegUp.height, PicRegUp.width, ~] = size(PicRegUp.Pic);
PicRegUp.Position = [round(options.screen.xCenter-PicRegUp.width*scaling/2),...
    round(options.screen.yCenter-PicRegUp.height*scaling/2),...
    round(PicRegUp.width*scaling)+round(options.screen.xCenter-PicRegUp.width*scaling/2),...
    round(PicRegUp.height*scaling)+round(options.screen.yCenter-PicRegUp.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]

PicRegDwn.Pic = imread('RegDwn.jpg');
PicRegDwn.Texture = Screen('MakeTexture', options.screen.windowPtr, PicRegDwn.Pic);
[PicRegDwn.height, PicRegDwn.width, ~] = size(PicRegDwn.Pic);
PicRegDwn.Position = [round(options.screen.xCenter-PicRegDwn.width*scaling/2),...
    round(options.screen.yCenter-PicRegDwn.height*scaling/2),...
    round(PicRegDwn.width*scaling)+round(options.screen.xCenter-PicRegDwn.width*scaling/2),...
    round(PicRegDwn.height*scaling)+round(options.screen.yCenter-PicRegDwn.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]

PicRest.Pic = imread('Rest.jpg');
PicRest.Texture = Screen('MakeTexture', options.screen.windowPtr, PicRest.Pic);
[PicRest.height, PicRest.width, ~] = size(PicRest.Pic);
PicRest.Position = [round(options.screen.xCenter-PicRest.width*scaling/2),...
    round(options.screen.yCenter-PicRest.height*scaling/2),...
    round(PicRest.width*scaling)+round(options.screen.xCenter-PicRest.width*scaling/2),...
    round(PicRest.height*scaling)+round(options.screen.yCenter-PicRest.height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]


%%%                %%%
%%% Welcome window %%%
%%%       and      %%%
%%%  Instructions  %%%
%%%                %%%
% Set blend function for alpha blending
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

DrawFormattedText(window,'Welcome to our experiment! \n\n Press any key to continue.', 'center','center',255 , [], [], [], 1);
Screen('Flip',options.screen.windowPtr);
AnyKeyWait(allkeys);
  
ShowInstruction = 1;
RenderInstruction (options,1,ShowInstruction);
RenderInstruction (options,2,ShowInstruction);
RenderInstruction (options,3,ShowInstruction);
RenderInstruction (options,4,ShowInstruction);
RenderInstruction (options,5,ShowInstruction);
RenderInstruction (options,6,ShowInstruction);


%%%                %%%
%%% TRANSFER RUN 0 %%%
%%%                %%%
if strcmp(doRuns(1),'Tr0')
Run = 'Transfer0';

% DrawFormattedText(window,'Transfer0.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%       %%%
%%% RUN 1 %%%
%%%       %%%
if strcmp(doRuns(2),'1')
Run = 1;
% DrawFormattedText(window,'Upregulations.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%       %%%
%%% RUN 2 %%%
%%%       %%%
if strcmp(doRuns(3),'2')
Run = 2;
% DrawFormattedText(window,'Downregulations.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%                %%%
%%% TRANSFER RUN 1 %%%
%%%                %%%
if strcmp(doRuns(4),'Tr1')
Run = 'Transfer1';

% DrawFormattedText(window,'Transfer1.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%       %%%
%%% RUN 3 %%%
%%%       %%%
if strcmp(doRuns(5),'3')
Run = 3;
% DrawFormattedText(window,'Upregulations.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%       %%%
%%% RUN 4 %%%
%%%       %%%
if strcmp(doRuns(6),'4')
Run = 4;
% DrawFormattedText(window,'Downregulations.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
%%%                %%%
%%% TRANSFER RUN 2 %%%
%%%                %%%
if strcmp(doRuns(7),'Tr2')
Run = 'Transfer2';

% DrawFormattedText(window,'Transfer2.', 'center','center',255 , [], [], [], 1);
% Screen('Flip',options.screen.windowPtr);
% AnyKeyWait(allkeys);
ExperimentDuration=options.ExperimentDuration;
Client_HardTiming;

DrawFormattedText(options.screen.windowPtr,['Please have a rest'], 'center','center',[0 255 0]);
Screen('Flip',options.screen.windowPtr);
pause(60);
end
sca