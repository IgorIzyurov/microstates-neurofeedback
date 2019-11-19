function [] = DrawAccumulativeFeedback(options, CurrentFB, PreviousFB, MaximalFB, Condition)
xCenter = options.screen.xCenter;
yCenter = options.screen.yCenter;
windowPtr = options.screen.windowPtr;
fixationFig = options.fixationFig;
wantBackgroundGrid = options.wantBackgroundGrid;


CurrentColor = options.CurrentColor;


if wantBackgroundGrid
    % Draw the background grid
    GridCoords = options.screen.GridCoords;
    Screen('DrawLines', windowPtr, GridCoords, [1 1 1], [1 1 1], [xCenter, yCenter], 0, 1);
end

if isequal(Condition,'Upreg') || isequal(Condition,'Downreg')
    
    switch Condition
        case 'Upreg'
            MaxColor = round(255*[0.4844 0.9875 0]);
        case 'Downreg'
            MaxColor = round(255*[0.8594 0.0781 0.2344]);
    end
    
    PreviousColor = options.PreviousColor;
    PreviousColor = round(255*[0.5 0.5 0.5]);
    CurrentFB_pix = (options.MaxFBScreen * CurrentFB)/(options.TrialLengthSeconds*(2));
    PreviousFB_pix = (options.MaxFBScreen * PreviousFB)/(options.TrialLengthSeconds*(2));
    MaximalFB_pix = (options.MaxFBScreen * MaximalFB)/(options.TrialLengthSeconds*(2));

    
    % Draw the Current circle to the screen.
    % Make a base Rect of x00 by x00 pixels
    baseRect = [0 0 CurrentFB_pix CurrentFB_pix];
    % Center the rectangle on the centre of the screen
    centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    % Draw the background circle to the screen
    Screen('FillOval', windowPtr, CurrentColor, centeredRect);
    
    % Draw the Previous feedback circle to the screen.
    % Make a base Rect of x00 by x00 pixels
    baseRect = [0 0 PreviousFB_pix PreviousFB_pix];
    % Center the rectangle on the centre of the screen
    centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    % Draw the background circle to the screen
    Screen('FrameOval', windowPtr, PreviousColor, centeredRect,3);
    
    % Draw the Max circle to the screen.
    % Make a base Rect of x00 by x00 pixels
    baseRect = [0 0 MaximalFB_pix MaximalFB_pix];
    % Center the rectangle on the centre of the screen
    centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    % Draw the background circle to the screen
    % Screen('FillOval', windowPtr, MaxColor, centeredRect);
    Screen('FrameOval', windowPtr, MaxColor, centeredRect, 3);
else
    % Draw the Background circle to the screen.
    % Make a base Rect of x00 by x00 pixels
    baseRect = [0 0 300 300];
    % Center the rectangle on the centre of the screen
    centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    % Draw the background circle to the screen
    Screen('FillOval', windowPtr, CurrentColor, centeredRect);
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
        lineWidthPix = 7;
        % Draw the fixation cross in white, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawLines', windowPtr, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
end



% Flip to the screen. This command basically draws all of our previous
% commands onto the screen. See later demos in the animation section on more
% timing details. And how to demos in this section on how to draw multiple
% rects at once. For help see: Screen Flip?
Screen('Flip', windowPtr);
end