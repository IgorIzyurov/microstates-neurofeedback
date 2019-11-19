function [options] = OpenTheScreen(SkipSync)
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
options.CurrentColor = rgb(options.CurrentColor); 
options.PreviousColor = 'Moccasin';
options.PreviousColor = rgb(options.PreviousColor); 
options.MaxColor = 'Crimson';
options.MaxColor = rgb(options.MaxColor); 
% Setup PTB with some default values
PsychDefaultSetup(2);
% Lets make a screen
windowOpts.windowed = 1; % If true, will run experiment in a window
if windowOpts.windowed == 1
    windowOpts.screen_num = max(Screen('Screens'));
    screen_rect = Screen('Rect',0);
    [mx,my] = RectCenter(screen_rect);
    windowOpts.window_width = 100;
    windowOpts.window_height = 200;
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
screen.White = WhiteIndex(windowOpts.screen_num);
% [window, rect] = PsychImaging('OpenWindow', windowOpts.screen_num, screen.Color);
[window, rect] = Screen('OpenWindow', windowOpts.screen_num, screen.Color,[],32,2);
% Flip to clear
Screen('Flip', window);
% [S.window, S.windowRect] = PsychImaging('OpenWindow', windowOpts.screen_num, screen.Color, [], 32, 2);
% [window, rect] = Screen('OpenWindow', windowOpts.screen_num, screen.Color); % Open an on screen window
[scrWidth, scrHeight] = Screen('WindowSize',window); % Get the size of the on screen window
Screen('TextSize',window,options.textparam.fontsize);
Screen('TextFont',window,options.textparam.font);
% Set blend function for alpha blending
Screen('BlendFunction',window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
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
end



function [AllGridCoords] = MakeCoordsGrid (NumOfLines, scrHeight)

% Use the meshgrid command to create our base dot coordinates. This will
% simply be a grid of equally spaced coordinates in the X and Y dimensions,
% centered on 0,0
% For help see: help meshgrid
dim = NumOfLines;
[xGridCoords, yGridCoords] = meshgrid(-dim:1:dim, -dim:1:dim);
% Here we scale the grid so that it is in pixel coordinates. We just scale
% it by the screen size so that it will fit. This is simply a
% multiplication. Notive the "." before the multiplicaiton sign. This
% allows us to multiply each number in the matrix by the scaling value.
pixelScale = scrHeight / (dim * 2 + 2);
xGridCoords = xGridCoords .* pixelScale;
yGridCoords = yGridCoords .* pixelScale;
AllGridCoords = nan(2,length(xGridCoords)*4);

for c = 1:length(xGridCoords)
    idx = (1:4) + 4*(c-1);
    AllGridCoords(:,idx) = [xGridCoords(1,c) xGridCoords(end,c) ...
        xGridCoords(c,1) xGridCoords(c,end);yGridCoords(1,c)...
        yGridCoords(end,c) yGridCoords(c,1) yGridCoords(c,end)];
end
end