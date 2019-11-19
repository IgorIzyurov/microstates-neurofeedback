function [] = RenderInstruction (options,N, ShowInstrustion)
if ShowInstrustion
screen = options.screen;
allkeys = options.keys.allkeys;
vbl = Screen('Flip', screen.windowPtr);
ifi = Screen('GetFlipInterval', screen.windowPtr);
waitframes = 1; % Numer of frames to wait before re-drawing
Pic = imread(['Instruction_' num2str(N) '.jpg']);
[height, width, ~] = size(Pic);
scaling = 1.0;
Position = [round(screen.xCenter-width*scaling/2),round(screen.yCenter-height*scaling/2),round(width*scaling)+round(screen.xCenter-width*scaling/2),round(height*scaling)+round(screen.yCenter-height*scaling/2)]; %[left_uppper_corner_x,  left_upper_corner_y, right_down_corner_x, right_down_corner_y]
instruction = Screen('MakeTexture', screen.windowPtr, Pic);
Screen('DrawTexture', screen.windowPtr, instruction, [], Position);
Screen('Flip', screen.windowPtr, vbl + (waitframes - 0.5) * ifi);
AnyKeyWait(allkeys);
Screen('Close', instruction);
end
end