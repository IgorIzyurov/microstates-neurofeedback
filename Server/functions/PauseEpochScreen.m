function [] = PauseEpochScreen(options)
xCenter = options.screen.xCenter;
yCenter = options.screen.yCenter;
windowPtr = options.screen.windowPtr;
fixationFig = options.fixationFig;
wantBackgroundGrid = options.wantBackgroundGrid;

if wantBackgroundGrid
    % Draw the background grid
    GridCoords = options.screen.GridCoords;
    Screen('DrawLines', windowPtr, GridCoords, [1 1 1], [1 1 1], [xCenter, yCenter], 0, 1);
end

switch fixationFig
    case 'dot'
        % Draw the fixation dot to the screen.
        FixSizePix = 20;
        FixdotColor = [0 0 0];
        Screen('DrawDots', windowPtr, [xCenter yCenter], FixSizePix, FixdotColor, [0 0], 2);
    case 'cross'
        % Draw the fixation cross to the screen.
        % Here we set the size of the arms of our fixation cross
        fixCrossDimPix = 20;
        % Now we set the coordinates (these are all relative to zero we will let
        % the drawing routine center the cross in the center of our monitor for us)
        xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
        yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
        allCoords = [xCoords; yCoords];
        % Set the line width for our fixation cross
        lineWidthPix = 10;
        % Draw the fixation cross in white, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawLines', windowPtr, allCoords, lineWidthPix, [1 1 1], [xCenter yCenter], 2);
end

% Flip to the screen. This command basically draws all of our previous
% commands onto the screen. See later demos in the animation section on more
% timing details. And how to demos in this section on how to draw multiple
% rects at once. For help see: Screen Flip?
Screen('Flip', windowPtr);
end