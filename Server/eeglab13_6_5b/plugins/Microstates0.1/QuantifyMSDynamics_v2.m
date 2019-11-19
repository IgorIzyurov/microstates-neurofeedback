%QuantifyMSDynamics() Quantify microstate parameters
%
% Usage:
%   >> res = QuantifyMSDynamics(MSClass,info, SamplingRate, DataInfo, TemplateName)
%
% Where: - MSClass is a N timepoints x N Segments matrix of momentary labels
%        - info is the structure with the microstate information
%        - Samplingrate is the sampling rate
%        - DataInfo contains info about the dataset analyzed
%        - TemplateName is the name of the microstate map template used
%        - ExpVar is the explained variance
%          The last three parameters are only for the documentation of the
%          results.
%
% Output:
%         - res: A Matlab table with the results, including the observed
%           transition matrix, the transition matrix expected if
%           transitions were only determined by the occurrence, and the
%           difference between the two.
%
% Author: Thomas Koenig, University of Bern, Switzerland, 2016
%
% Copyright (C) 2016 Thomas Koenig, University of Bern, Switzerland, 2016
% thomas.koenig@puk.unibe.ch
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
function [res, ExtraOutput, MSDynamicBinary, MSDynamicDuration] = QuantifyMSDynamics_v2(MSClass,info, SamplingRate, DataInfo, TemplateName, ExpVar)

%    res = table();

nEpochs = size(MSClass,2);

% WE HAVE CHANGED IT
% to get info about duration and occurance in ms
%     TimeAxis = (0:(numel(MSClass)-1)) / SamplingRate;
TimeAxis = (0:(numel(MSClass)-1))*1000 / SamplingRate;


res.DataSet      = DataInfo.setname;
res.Subject      = DataInfo.subject;
res.Day        = DataInfo.day;
res.Session        = DataInfo.session;
res.Intake        = DataInfo.intake;
res.Template     = TemplateName;
res.ExpVar       = ExpVar;

%   res.SortInfo     = info.MSMaps(info.FitPar.nClasses).SortedBy; % do
%   not understand modification
res.SortInfo     = info.MSMaps.SortedBy;

eDuration        = nan(1,info.FitPar.nClasses,nEpochs);
eOccurrence      = zeros(1,info.FitPar.nClasses,nEpochs);
eContribution    = zeros(1,info.FitPar.nClasses,nEpochs);

eTotalTime       = zeros(1,nEpochs);
eMeanDuration    = nan(1,nEpochs);
eMeanOccurrence  = nan(1,nEpochs);

eOrgTM        = zeros(info.FitPar.nClasses,info.FitPar.nClasses,nEpochs);
eExpTM        = zeros(info.FitPar.nClasses,info.FitPar.nClasses,nEpochs);

MSDynamicBinary = zeros(info.FitPar.nClasses,length(TimeAxis));
MSDynamicDuration = zeros(info.FitPar.nClasses,1);

counter2 = 0;

for e = 1: size(MSClass,2)
    % Find the transitions
    ChangeIndex = find([0 diff(MSClass(:,e)')]);
    StartTimes   = TimeAxis(ChangeIndex(1:(end-1)    ));
    % WE HAVE CHANGED IT
    % to get end time of prevoius microstate same as start time of next one
    % EndTimes     = TimeAxis((ChangeIndex(2:end    )-1));
    EndTimes     = TimeAxis((ChangeIndex(2:end)));
    
    Duration = EndTimes - StartTimes + TimeAxis(1);
    Class    = MSClass(ChangeIndex,e);
    Class(end) = nan;
    
    TotalTime = sum(Duration(Class > 0));
    eTotalTime(e)    = TotalTime;
    
    eMeanDuration(e) = mean(Duration(Class > 0));
    MeanOcc = sum(Class > 0) / (TotalTime/1000); % we get occurance is Hz (numb of MS per second)
    eMeanOccurrence(e) = MeanOcc;
    
    for c1 = 1: info.FitPar.nClasses
        counter1 = 0;
        Hits = find(Class == c1);
        for k = 1:length(Hits)
            
            MSDynamicDuration(c1,(length(nonzeros(MSDynamicDuration(c1,:)))+k-counter1)) = Duration(Hits(k));
            counter1 = counter1+1;
            
            for timepoint = (ChangeIndex(Hits(k))):((ChangeIndex(Hits(k))+Duration(Hits(k))/(1000/SamplingRate)-1))
                MSDynamicBinary(c1,timepoint + counter2) = 1;
            end
        end
    end
    
    counter2 = counter2 + (size(MSClass(:,e),1));
    clear c1
    clear Hits
    
    for c1 = 1: info.FitPar.nClasses
        Hits = find(Class == c1);
        eDuration(1,c1,e)     = mean(Duration(Hits));
        eOccurrence(1,c1,e)   = numel(Hits) / (TotalTime/1000); % we get occurance is Hz (numb of MS per second)
        eContribution(1,c1,e) = sum(Duration(Hits)) / TotalTime;
        for c2 = 1: info.FitPar.nClasses
            eOrgTM(c1,c2,e) = sum(Class(Hits+1) == c2) / sum(~isnan(Class));
        end
    end
    
    for c1 = 1: info.FitPar.nClasses
        for c2 = 1: info.FitPar.nClasses
            eExpTM(c1,c2,e) = eOccurrence(1,c1,e) / MeanOcc * eOccurrence(1,c2,e) / MeanOcc / (1 - eOccurrence(1,c1,e) / MeanOcc);
        end
        eExpTM(c1,c1,e) = 0;
    end
end

res.TotalTime = sum(eTotalTime);

res.Duration     = mynanmean(eDuration,3);
res.MeanDuration = mean(eMeanDuration);

res.Occurrence   = mean(eOccurrence,3);
res.MeanOccurrence = mean(eMeanOccurrence);

res.Contribution = mean(eContribution,3);

res.OrgTM = mean(eOrgTM,3);
res.ExpTM = mean(eExpTM,3);
res.DeltaTM = res.OrgTM - res.ExpTM;

ExtraOutput.eDuration = eDuration;
ExtraOutput.eOccurrence = eOccurrence;
ExtraOutput.eContribution = eContribution;
ExtraOutput.eOrgTM = eOrgTM;
ExtraOutput.eExpTM = eExpTM;

%     for c1 = 1: info.FitPar.nClasses
%         for c2 = 1: info.FitPar.nClasses
%             tmptbl = table(OrgTM(c1,c2),'VariableNames',{sprintf('Obs_TM_%i_%i',c1,c2)});
%             res = [res tmptbl];
%         end
%     end
%
%     for c1 = 1: info.FitPar.nClasses
%         for c2 = 1: info.FitPar.nClasses
%             tmptbl = table(ExpTM(c1,c2),'VariableNames',{sprintf('Exp_TM_%i_%i',c1,c2)});
%             res = [res tmptbl];
%         end
%     end
%
%     for c1 = 1: info.FitPar.nClasses
%         for c2 = 1: info.FitPar.nClasses
%             tmptbl = table(DeltaTM(c1,c2),'VariableNames',{sprintf('ObsvsExp_TM_%i_%i',c1,c2)});
%             res = [res tmptbl];
%         end
%     end
end

function res = mynanmean(in,dim)
isout = isnan(in);
in(isout) = 0;
res = sum(in,dim) ./ sum(~isout,dim);
end
