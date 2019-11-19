clear;
disp('RUNNING ONLINE ICA');
addpath([fileparts(which('step_03_OnlineICA.m')) '\functions\']);
[par] = WriteICAParameters();
Qchan = 63;
Srate = 500;
SBWlength = 8; % seconds
SBW = nan(Qchan,SBWlength*Srate);
current_timepoint = 1;
chunkstart_timepoint = 1;
doSBWacquisition = true;
OutStreamName = 'EEG-ICA';
% Variance
Threshold_Var = 1*10^6;
Threshold_Std = 3;
EEG_struct = load('chanlocs_from_Analyzer2_128Ch.mat');
EEG_struct.chanlocs = EEG_struct.chanlocs(1:Qchan);
EEG_struct.nbchan = Qchan;
Var_SW_ALL = [];

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG-MR-CWL'); end
% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

% make a new stream outlet
disp('Creating a new streaminfo...');
info_ICA = lsl_streaminfo(lib,OutStreamName,OutStreamName,Qchan,Srate,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet_ICA = lsl_outlet(info_ICA);

disp('Now receiving chunked data...');

tic
while true
    
    [chunk,stamps] = inlet.pull_chunk();
    if ~isempty(chunk)
        chunk = chunk([1:31 33:64], :); % exclude ECG and CWLs
        if doSBWacquisition
            current_timepoint = chunkstart_timepoint + size(chunk,2) - 1;
            if current_timepoint < SBWlength*Srate
                SBW(:,chunkstart_timepoint:current_timepoint) = chunk;
                chunkstart_timepoint = current_timepoint + 1;
                continue;
            else
                chunk1 = chunk(:,1:sum(isnan(SBW(1,:))));
                chunk2 = chunk(:,size(chunk1,2)+1:end);
                SBW(:,end-sum(isnan(SBW(1,:)))+1:end) = chunk1;
                SBW = [SBW(:,(size(chunk2,2)+1):end) chunk2];
                
                % Varience check for SBW
                Var_SBW = mean(var(SBW));
                if Var_SBW > Threshold_Var
                    disp('Noisy data! SBW not acqured! Retrying...');
                    SBW = nan(Qchan,SBWlength*Srate);
                    current_timepoint = 1;
                    chunkstart_timepoint = 1;
                    continue
                else
                    Var_chan = var(SBW,[],2);
                    Threshold_Channel = mean(Var_chan) + Threshold_Std*std(Var_chan);
                    NoiseChan = union(find(Var_chan > Threshold_Channel), find(Var_chan == 0));
                    EEG_struct.data = SBW;
                    if ~isempty(NoiseChan)
                        [SBW_interp] = Interpolation(NoiseChan, EEG_struct, EEG_struct);
                        SBW = SBW_interp;
                    end
                end
                
                SW = SBW(:,end-(par.sw-1):end);
                doSBWacquisition = false;
                doSWacquisition = false;
                disp('SBW acqired');
            end
        end
        if doSWacquisition
            SW = [SW chunk];
            if size(SW,2) < par.sw
                continue;
            else
                % Varience check for SW
                Var_SW = mean(var(SW));
                Threshold_Var_Upd = mean(Var_SW_ALL) + Threshold_Std*std(Var_SW_ALL);
                if Var_SW > Threshold_Var || (length(Var_SW_ALL) > 40 && Var_SW > Threshold_Var_Upd)
                    disp('High varience! SW not acquired');
                    SW = [];
                    continue
                else
                    Var_SW_ALL = [Var_SW_ALL Var_SW];
                    Var_chan = var(SW,[],2);
                    Threshold_Channel = mean(Var_chan) + Threshold_Std*std(Var_chan);
                    NoiseChan = find(Var_chan > Threshold_Channel);
                    FlatChan = find(Var_chan == 0);
                    ToInterpolate = union(NoiseChan, FlatChan);
                    EEG_struct.data = SW;
                    if ~isempty(ToInterpolate) && length(ToInterpolate) <= 4
                        [SW_interp] = Interpolation(NoiseChan, EEG_struct, EEG_struct);
                        SW = SW_interp;
                    elseif ~isempty(ToInterpolate) && length(ToInterpolate) > 4
                        [~,idx] = sort(Var_chan(ToInterpolate),'descend');
                        ToInterpolate = ToInterpolate(idx(1:4));
                        [SW_interp] = Interpolation(NoiseChan, EEG_struct, EEG_struct);
                        SW = SW_interp;
                    end
                    
                end
                SBW = [SBW(:,(size(SW,2)+1):end) SW];
            end
        end
        doSWacquisition = true;
        % ICA
        ICA_tic = tic;
        [SBW_noeyes] = ICA_calc(Qchan, par, SBW);
        ica_toc = toc(ICA_tic);
        % Output eye-artefact-corrected smallWindow
        SW_noeyes = SBW_noeyes(:,end-size(SW,2)+1:end);
        chunkOut = SW_noeyes;
        outlet_ICA.push_chunk(chunkOut);
        SW = [];
        tic
    else
%         if round(toc) > 10
%             disp('Connection lost after 10 seconds of silence');
%             disp('Aquisition ended');
%             break
%         end
        continue;
    end
end


function [par] = WriteICAParameters()
par.desired_ch = transpose(1:63); % number of channels
par.sw = 100;
par.numOfIC = 8; % number of independent components (IC); should range between 5-10, but not below 5

% Variables for controlling 'whitening'
% firstEig and lastEig specify the range for eigenvalues that are retained
par.firstEig          = 1; % index of largest eigenvalues to keep
par.lastEig           = par.numOfIC; % index of the last (smallest) eigenvalue to keep

% Default values for fixed point ICA parameters
par.epsilon           = 0.001; % stopping criterion
par.maxNumIterations  = 30; % default = 1000 (maximum number of iterations)

% Loading ICA template (template of ideal eye artifact (ICA_EyeHor = horizontal eye
% artifact; ICA_EyeVert = vertical eye artifact))

% for 63 channels

par.ICA_EyeHor = [0.549930755575988;-1.23201812304577;0.715267969445481;-0.808599885425582;0.628412186036173;-0.385705350733647;0.459300740834362;-0.0718191156452517;0.317085800153237;0.0315854123363991;2.46435540980346;-2.40413535849089;1.45113423439688;-1.01875224696384;0.564093672615190;-0.153263122777944;-0.0554122939106310;0.101664275357278;0.162749083456124;0.188716541531526;0.316672742973114;-0.259734247713312;0.270753605169826;-0.0544533571202849;1.36672480378071;-1.20820766319548;0.792314082880604;-0.308702767157315;0.894218999098727;-0.454368800081265;0.187306088777470;0.266121002165053;-0.379889562546222;0.301341768122391;-0.136278609219451;0.323017662652316;0.0679053165073431;0.534624639707329;-0.848034738222811;0.726696410458979;-0.612499282035063;0.524562063085504;-0.172004019145040;0.351354923870577;0.0524142736685281;1.36647663893710;-1.57082177469961;1.07051334425020;-0.734917403010183;0.551953766252701;-0.0888565277669833;1.82732373964643;-2.31506135244093;1.97068497757544;-1.63472057804342;1.01646132252746;-0.456691942286595;0.439186404443516;-0.00695794209293895;2.79239010732697;-2.16770135622766;-0.301003900681065;0.144925456188972];
par.ICA_EyeVert = [2.98725807590548;2.88837029746993;0.718652016977733;0.463101724250311;-0.0835314234275092;-0.384049424604029;-0.347061447984219;-0.714090744221027;-0.545860211915621;-0.846330229170974;1.12446421349439;0.146956814728358;-0.149826428978673;-0.903255957704736;-0.408331883731307;-1.02486218294318;0.623559360071658;-0.201121586333930;-0.507256963911764;-0.758337213031535;0.0274498698937332;-0.116526369557765;-0.275087705880795;-0.436263660831126;0.249058418745284;-0.254399515765336;-0.242770981862192;-0.752796067459360;-0.203870745552025;-1.88015453949280;-0.771789199802491;0.547520433761270;0.457296771293735;-0.194923175031498;-0.354861591035607;-0.377414696386545;-0.567121509127773;1.66938155792299;1.65560446645658;0.0885887561108664;-0.146655410701016;-0.235018897309136;-0.557726104888613;-0.534554756325647;-0.800449934751895;1.09091113932930;0.513527187056816;-0.0790027105412391;-0.564579573366736;-0.338582057848763;-0.699141399437207;2.50925208851822;1.78708357914369;0.240111690868962;-0.589995971894522;-0.320201628989981;-1.13781520326495;-0.456041947037395;-0.985493406122689;-0.255142494301014;-1.17144979944261;2.97218803246976;-0.532095112959968];
% par.ICA_EyeHor(32,:) = [];
% par.ICA_EyeVert(32,:) = [];

% for 21 channels
% par.ICA_EyeHor = [0.549930755575988;-1.23201812304577;0.715267969445481;-0.808599885425582;0.628412186036173;-0.385705350733647;0.459300740834362;-0.0718191156452517;0.317085800153237;0.0315854123363991;2.46435540980346;-2.40413535849089;1.45113423439688;-1.01875224696384;0.564093672615190;-0.153263122777944;-0.0554122939106310;0.101664275357278;0.162749083456124;0.188716541531526;0.144925456188972];
% par.ICA_EyeVert = [2.98725807590548;2.88837029746993;0.718652016977733;0.463101724250311;-0.0835314234275092;-0.384049424604029;-0.347061447984219;-0.714090744221027;-0.545860211915621;-0.846330229170974;1.12446421349439;0.146956814728358;-0.149826428978673;-0.903255957704736;-0.408331883731307;-1.02486218294318;0.623559360071658;-0.201121586333930;-0.507256963911764;-0.758337213031535;-0.532095112959968];

%--------------------------------------------------------------------------
% Threshold for calculation of spatial correlation
%--------------------------------------------------------------------------
par.th_hor = 0.7; % threshold for c-value of horizontal eye movement
par.th_ver = 0.7; % threshold for c-value of vertical eye movement
end
function [superbigwindow] = ICA_calc(nbchan, par, superbigwindow)

% In this section ICA decomposition is performed by using fastICA
% (Hyparinen, A.; 1999). fastICA seeks an orthogonal rotation of prewhitened
% data, through a fixed-point iteration scheme, that maximizes a measure
% of non-Gaussianity of the rotated components.
% fastICA ouputs the estimated separating matrix W and the corresponding
% mixing matrix A.

% Remove current EEG ICA weights and spheres
EEG_sbw.icaweights = [];
EEG_sbw.icasphere  = [];
EEG_sbw.icawinv    = [];
EEG_sbw.icaact     = [];

% Data must be in double precision
EEG_sbw.tmpdata     = superbigwindow;
EEG_sbw.tmpdata     = EEG_sbw.tmpdata  - repmat(mean(EEG_sbw.tmpdata,2), [1 size(EEG_sbw.tmpdata,2)]); % zero mean

% Begin fastICA by removing the

[EEG_sbw.tmpdata, EEG_sbw.mixedmean] = remmean(EEG_sbw.tmpdata);

%------------------------------
% Calculate PCA
%------------------------------

% Calculates the PCA matrices for given data (row) vectors. Returns
% the eigenvector (E) and diagonal eigenvalue (D) matrices containing the
% selected subspaces. Dimensionality reduction is controlled with
% the parameters 'firstEig' and 'lastEig'.

% Calculate the eigenvalues and eigenvectors of covariance
% matrix.
% if fprintf ('Calculating covariance...\n'); end

[EEG_sbw.E, EEG_sbw.D] = eig(cov(EEG_sbw.tmpdata', 1));

% Sort the eigenvalues - decending.
% eigenvalues = flipud(sort(diag(EEG_sbw.D)));
eigenvalues = sort(diag(EEG_sbw.D), 'descend');


% Drop the smaller eigenvalues
if par.lastEig < nbchan
    lowerLimitValue = (eigenvalues(par.lastEig) + eigenvalues(par.lastEig + 1)) / 2;
else
    lowerLimitValue = eigenvalues(nbchan) - 1;
end

lowerColumns = diag(EEG_sbw.D) > lowerLimitValue;

% Drop the larger eigenvalues
if par.firstEig > 1
    higherLimitValue = (eigenvalues(par.firstEig - 1) + eigenvalues(par.firstEig)) / 2;
else
    higherLimitValue = eigenvalues(1) + 1;
end
higherColumns = diag(EEG_sbw.D) < higherLimitValue;

% Combine the results from above
selectedColumns = lowerColumns & higherColumns;

% Select the colums which correspond to the desired range
% of eigenvalues (eigenvalues and eigenvectors are not sorted).

% for eigenvector E:
numTaken = 0;
for i = 1 : size (selectedColumns, 1)
    if selectedColumns(i, 1) == 1
        takingMask(1, numTaken + 1) = i; %#ok<AGROW>
        numTaken = numTaken + 1;
    end
end
EEG_sbw.E = EEG_sbw.E(:, takingMask); % --> E: Eigenvector matrix

% for diagonal eigenvalue D:
clear numTaken takingMask
numTaken = 0;
selectedColumns = selectedColumns';
EEG_sbw.D = EEG_sbw.D';
for i = 1 : size (selectedColumns, 2)
    if selectedColumns(1, i) == 1
        takingMask(1, numTaken + 1) = i;
        numTaken = numTaken + 1;
    end
end
EEG_sbw.D = EEG_sbw.D(:, takingMask)';

clear takingMask numTaken
numTaken = 0;
selectedColumns = selectedColumns';
for i = 1 : size (selectedColumns, 1)
    if selectedColumns(i, 1) == 1
        takingMask(1, numTaken + 1) = i;
        numTaken = numTaken + 1;
    end
end
EEG_sbw.D = EEG_sbw.D(:, takingMask); % --> D: Diagonal eigenvalue matrix

%-------------------
% Whitening the data
%-------------------
% The following section whitens the data (row vectors) and reduces dimension.
% Returns the whitened vectors (row vectors), whitening and dewhitening matrices.

% Calculate the whitening and dewhitening matrices (these handle
% dimensionality simultaneously).
EEG_sbw.whiteningMatrix = inv(sqrt (EEG_sbw.D)) * EEG_sbw.E';
% EEG_sbw.whiteningMatrix = (sqrt (EEG_sbw.D)) / EEG_sbw.E';
EEG_sbw.dewhiteningMatrix = EEG_sbw.E * sqrt (EEG_sbw.D);

% Project to the eigenvectors of the copariance matrix.
% Whiten the samples and reduce dimension simultaneously.
% --> whitening
EEG_sbw.whitesig =  EEG_sbw.whiteningMatrix * EEG_sbw.tmpdata;

%----------------
% Calculate  ICA
%----------------

% Calculate the ICA with fixed-point algorithm
[EEG_sbw.vectorSize, EEG_sbw.numSamples]    = size(EEG_sbw.whitesig);
% if fprintf('Starting ICA calculation...\n'); end

% Estimate all the independent components in parallel
EEG_sbw.A = zeros(EEG_sbw.vectorSize, par.numOfIC);  % Dewhitened basis vectors

% Take random orthonormal initial vectors
EEG_sbw.B = orth (randn (EEG_sbw.vectorSize, par.numOfIC));

EEG_sbw.BOld = zeros(size(EEG_sbw.B));
EEG_sbw.BOld2 = zeros(size(EEG_sbw.B));

% This is the actual fixed-point iteration loop

for round = 1:par.maxNumIterations + 1
    
    if round == par.maxNumIterations + 1
        fprintf('No convergence after %d steps\n', par.maxNumIterations);
        if ~isempty(EEG_sbw.B)
            % Symmetric orthogonalization
            EEG_sbw.B = EEG_sbw.B * real(inv(EEG_sbw.B' * EEG_sbw.B)^(1/2));
            
            EEG_sbw.W = EEG_sbw.B' * EEG_sbw.whiteningMatrix;
            EEG_sbw.A = EEG_sbw.dewhiteningMatrix * EEG_sbw.B;
        else
            EEG_sbw.W = [];
            EEG_sbw.A = [];
        end
        continue;
    end
    
    % Symmetric orthogonalization
    EEG_sbw.B = EEG_sbw.B * real(inv(EEG_sbw.B' * EEG_sbw.B)^(1/2));
    
    % Test for termination condition. Note that we consider opposite
    % directions here as well.
    minAbsCos = min(abs(diag(EEG_sbw.B' * EEG_sbw.BOld)));
    
    if (1 - minAbsCos < par.epsilon)
        if fprintf('Convergence after %d steps\n', round); end
        
        % Calculate the de-whitened vectors
        EEG_sbw.A = EEG_sbw.dewhiteningMatrix * EEG_sbw.B;
        break;
    end
    
    EEG_sbw.BOld2 = EEG_sbw.BOld;
    EEG_sbw.BOld = EEG_sbw.B;
    
    % Show the progress...
    %     if round == 1
    %         fprintf('Step no. %d\n', round);
    %     else
    %         fprintf('Step no. %d, change in value of estimate: %.3g \n', round, 1 - minAbsCos);
    %     end
    
    EEG_sbw.B = (EEG_sbw.whitesig * (( EEG_sbw.whitesig' * EEG_sbw.B) .^ 3)) / EEG_sbw.numSamples - 3 * EEG_sbw.B;
    
end

% Calculate ICA filters

EEG_sbw.W = EEG_sbw.B' * EEG_sbw.whiteningMatrix;

% ICA Output
EEG_sbw.icawinv    = EEG_sbw.A; % mixing matrix A
EEG_sbw.icaweights = EEG_sbw.W; % inverse matrix of A

% Update weight and inverse matrices etc...
if isempty(EEG_sbw.icaweights)
    EEG_sbw.icaweights = pinv(EEG_sbw.icawinv);
end
if isempty(EEG_sbw.icasphere)
    EEG_sbw.icasphere  = eye(size(EEG_sbw.icaweights,2));
end
if isempty(EEG_sbw.icawinv)
    EEG_sbw.icawinv    = pinv(EEG_sbw.icaweights*EEG_sbw.icasphere); % a priori same result as inv
end

% Correlation of independent components

% In this section each of the calculated component (EEG_sbw.icawinv) is correlated with
% each template (template for horizontal eye movement 'EyeHor' AND template
% for vertical eye movement 'EyeVert'). If the c (correlation coefficient)
% or p (matrix of p-values for testing the hypothesis of no correlation
% against the alternative hypothesis of a nonzero correlation) value
% exceeds the threshold (predetermined c-value) of 0.7, then reject the
% component and reconstruct the

EEG_sbw.components = []; % initialising components

for q = 1:size(EEG_sbw.icawinv,2)
    
    % Calculate c and p-value of horizontal and vertical eye movement
    
    [par.c_hor, par.p_hor] = corr(EEG_sbw.icawinv(:,q)/std(EEG_sbw.icawinv(:,q)), par.ICA_EyeHor/std(par.ICA_EyeHor));
    [par.c_vert, par.p_vert] = corr(EEG_sbw.icawinv(:,q)/std(EEG_sbw.icawinv(:,q)), par.ICA_EyeVert/std(par.ICA_EyeVert));
    
    if (abs(par.c_hor) > par.th_hor) || (abs(par.c_vert) > par.th_ver)
        EEG_sbw.components = cat(2, EEG_sbw.components, q);
    end
end

if ~isempty(EEG_sbw.components) % if there are components, reconstruct data
    
    %-----------------------
    % Reconstruction of data
    %-----------------------
    
    % Rejecting bad component
    EEG_sbw.component_keep  = setdiff_bc(1:size(EEG_sbw.icaweights,1), EEG_sbw.components);
    EEG_sbw.compproj        = EEG_sbw.icawinv(:, EEG_sbw.component_keep) * ((EEG_sbw.icaweights(EEG_sbw.component_keep,:)*EEG_sbw.icasphere)*superbigwindow);
    
    % Data reconstruction (back-projection: forward mixing
    % process from IC's to sclap channels)
    superbigwindow(par.desired_ch',:) = EEG_sbw.compproj;
    EEG_sbw.goodinds    = setdiff_bc(1:size(EEG_sbw.icaweights,1), EEG_sbw.components);
    EEG_sbw.icawinv     = EEG_sbw.icawinv(:,EEG_sbw.goodinds);
    EEG_sbw.icaweights  = EEG_sbw.icaweights(EEG_sbw.goodinds,:);
end
end
function [newVectors, meanValue] = remmean(vectors)
%REMMEAN - remove the mean from vectors
%
% [newVectors, meanValue] = remmean(vectors);
%
% Removes the mean of row vectors.
% Returns the new vectors and the mean.
%
% This function is needed by FASTICA and FASTICAG

% @(#)$Id: remmean.m,v 1.2 2003/04/05 14:23:58 jarmo Exp $

newVectors = zeros (size (vectors));
meanValue = mean (vectors')';
newVectors = vectors - meanValue * ones (1,size (vectors, 2));
end