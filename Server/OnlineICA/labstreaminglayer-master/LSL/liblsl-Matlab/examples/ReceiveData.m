clear
%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-MRcorr'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving data...');
c = 0;
DATA = [];
while true
    c = c+1;
    % get data from the inlet
    [vec,ts] = inlet.pull_sample();
    A = vec;
    DATA = [DATA vec'];
    % and display it
%     fprintf('%.2f\t',vec);
%     fprintf('%.5f\n',ts);
    if c == 10000
        break
    end
end