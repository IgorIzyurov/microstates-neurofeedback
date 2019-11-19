
function [tmpdata] = Interpolation(bad_channel, EEG, EEG_sw)

EEG_sw.badchans = bad_channel;
EEG.badchans = bad_channel;

EEG_sw.goodchans = setdiff(1:EEG_sw.nbchan, EEG.badchans);
EEG_sw.oldelocs = EEG_sw.chanlocs;

EEG_sw.chanlist = { EEG.chanlocs.labels };

EEG_sw.noChannelAsCell = {};
for nochanId = 1:length(EEG_sw.badchans)
    EEG_sw.noChannelAsCell{nochanId} = EEG_sw.chanlocs(EEG_sw.badchans(nochanId)).labels;
end

EEG_sw.badchans = EEG_sw.noChannelAsCell;
EEG_sw.channel = EEG_sw.chanlist;
EEG_sw.channel = sort(setdiff(lower(EEG_sw.channel), lower(EEG_sw.badchans) ));

% Decoding channels
EEG_sw.chaninds = [];
EEG_sw.alllabs = lower({ EEG_sw.chanlocs.labels });
EEG_sw.channel = lower(EEG_sw.channel);
for ind = 1:length(EEG_sw.channel)
    EEG_sw.indmatch = find(strcmp(EEG_sw.alllabs,EEG_sw.channel{ind}));
    if ~isempty(EEG_sw.indmatch)
        for tmpi = 1:length(EEG_sw.indmatch)
            EEG_sw.chaninds(end+1) = EEG_sw.indmatch(tmpi);
        end
    else
    end
end

EEG_sw.chaninds = sort(EEG_sw.chaninds);
EEG_sw.channel = EEG_sw.chaninds;

% Performing removal
EEG_sw.diff1 = setdiff(1:size(EEG_sw.data,1), EEG_sw.channel);
EEG_sw.data(EEG_sw.diff1, :) = [];

EEG_sw.pnts = size(EEG_sw.data,2);
EEG_sw.nbchan = length(EEG_sw.channel);
EEG_sw.chanlocs = EEG_sw.chanlocs(EEG_sw.channel);
EEG_sw.chanlocs = EEG_sw.oldelocs ; % re-save chanlocs

disp(['Interpolating' ' channel(s): ' num2str((EEG.badchans')) ' ' strjoin(strcat(EEG_sw.noChannelAsCell),' ') ' ...']);

% Find non-empty good channels and update some variables
EEG_sw.origoodchans = EEG_sw.goodchans;
EEG_sw.chanlocs = EEG.chanlocs;
EEG_sw.nonemptychans = find(~cellfun('isempty', {EEG_sw.chanlocs.theta}));

[EEG_sw.tmp, EEG_sw.indgood] = intersect(EEG_sw.goodchans, EEG_sw.nonemptychans);
EEG_sw.indgood = EEG_sw.indgood';
EEG_sw.goodchans = EEG_sw.goodchans(sort(EEG_sw.indgood));

% Getting data channel
EEG_sw.datachans = EEG_sw.goodchans;
EEG.badchans = sort(EEG.badchans);

for index_interp = length(EEG.badchans):-1:1
    EEG_sw.datachans(EEG_sw.datachans > EEG.badchans(index_interp)) = EEG_sw.datachans(EEG_sw.datachans > EEG.badchans(index_interp))-1;
end
EEG.badchans = intersect(EEG.badchans, EEG_sw.nonemptychans);

% Scan data points: get theta, rad of electrodes
EEG_sw.tmpgoodlocs     = EEG_sw.chanlocs(EEG_sw.goodchans);
EEG_sw.xelec           = [ EEG_sw.tmpgoodlocs.X ];
EEG_sw.yelec           = [ EEG_sw.tmpgoodlocs.Y ];
EEG_sw.zelec           = [ EEG_sw.tmpgoodlocs.Z ];
EEG_sw.rad             = sqrt(EEG_sw.xelec.^2+EEG_sw.yelec.^2+EEG_sw.zelec.^2);
EEG_sw.xelec           = EEG_sw.xelec./EEG_sw.rad;
EEG_sw.yelec           = EEG_sw.yelec./EEG_sw.rad;
EEG_sw.zelec           = EEG_sw.zelec./EEG_sw.rad;
EEG_sw.tmpbadlocs      = EEG_sw.chanlocs(EEG.badchans);
EEG_sw.xbad            = [ EEG_sw.tmpbadlocs.X ];
EEG_sw.ybad            = [ EEG_sw.tmpbadlocs.Y ];
EEG_sw.zbad            = [ EEG_sw.tmpbadlocs.Z ];
EEG_sw.rad             = sqrt(EEG_sw.xbad.^2+EEG_sw.ybad.^2+EEG_sw.zbad .^2);
EEG_sw.xbad            = EEG_sw.xbad./EEG_sw.rad;
EEG_sw.ybad            = EEG_sw.ybad./EEG_sw.rad;
EEG_sw.zbad            = EEG_sw.zbad ./EEG_sw.rad;

% Spherical spline interpolation
EEG_sw.values = EEG_sw.data(EEG_sw.datachans,:);
EEG_sw.newchans = length(EEG_sw.xbad);
EEG_sw.numpoints = size(EEG_sw.values,2);

% Compute g function
% Gelec
EEG_sw.unitmat = ones(length(EEG_sw.xelec(:)),length(EEG_sw.xelec));
EEG_sw.EI = EEG_sw.unitmat - sqrt((repmat(EEG_sw.xelec(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.xelec,length(EEG_sw.xelec(:)),1)).^2 +...
    (repmat(EEG_sw.yelec(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.yelec,length(EEG_sw.xelec(:)),1)).^2 +...
    (repmat(EEG_sw.zelec(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.zelec,length(EEG_sw.xelec(:)),1)).^2);

EEG_sw.g = zeros(length(EEG_sw.xelec(:)),length(EEG_sw.xelec));
EEG_sw.m = 4; % 3 is linear, 4 is best according to Perrin's curve

for n = 1:7
    EEG_sw.L = legendre(n,EEG_sw.EI);
    EEG_sw.g = EEG_sw.g + ((2*n+1)/(n^EEG_sw.m*(n+1)^EEG_sw.m))*squeeze(EEG_sw.L(1,:,:));
end
EEG_sw.Gelec = EEG_sw.g/(4*pi);

% G-function of spherical splines
EEG_sw.unitmat = ones(length(EEG_sw.xbad(:)),length(EEG_sw.xelec));
EEG_sw.EI = EEG_sw.unitmat - sqrt((repmat(EEG_sw.xbad(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.xelec,length(EEG_sw.xbad(:)),1)).^2 +...
    (repmat(EEG_sw.ybad(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.yelec,length(EEG_sw.xbad(:)),1)).^2 +...
    (repmat(EEG_sw.zbad(:),1,length(EEG_sw.xelec)) - repmat(EEG_sw.zelec,length(EEG_sw.xbad(:)),1)).^2);

EEG_sw.g = zeros(length(EEG_sw.xbad(:)),length(EEG_sw.xelec));

for n = 1:7
    EEG_sw.L = legendre(n,EEG_sw.EI);
    EEG_sw.g = EEG_sw.g + ((2*n+1)/(n^EEG_sw.m*(n+1)^EEG_sw.m))*squeeze(EEG_sw.L(1,:,:));
end
EEG_sw.Gsph = EEG_sw.g/(4*pi);

% Compute solution for parameter C
EEG_sw.meanvalues = mean(EEG_sw.values);
EEG_sw.values = EEG_sw.values - repmat(EEG_sw.meanvalues, [size(EEG_sw.values,1) 1]); % make mean zero
EEG_sw.values = [EEG_sw.values; zeros(1,EEG_sw.numpoints )];
EEG_sw.C = pinv([EEG_sw.Gelec; ones(1,length(EEG_sw.Gelec))]) * EEG_sw.values;
clear EEG_sw.values;
EEG_sw.allres = zeros(EEG_sw.newchans, EEG_sw.numpoints );

% Apply results
for j = 1:size(EEG_sw.Gsph,1)
    EEG_sw.allres(j,:) = sum(EEG_sw.C.*repmat(EEG_sw.Gsph(j,:)',[1 size(EEG_sw.C,2)]));
end

EEG_sw.allres = EEG_sw.allres + repmat(EEG_sw.meanvalues, [size(EEG_sw.allres,1) 1]);
EEG_sw.badchansdata = EEG_sw.allres;
EEG_sw.tmpdata = zeros(length(EEG.badchans), EEG_sw.pnts);
EEG_sw.tmpdata (EEG_sw.origoodchans, :) = EEG_sw.data;
EEG_sw.tmpdata (EEG.badchans,:) = EEG_sw.badchansdata;
tmpdata = EEG_sw.tmpdata;
end