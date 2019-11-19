function [Result,Assignment, Polarity] = SwapMaps(MapsToSwap,MeanMap,RespectPolarity)
    [~,nMaps,nChannels] = size(MeanMap);
    permutations = fliplr(perms(1:nMaps));
    nPerms = size(permutations,1);
    
    PermutedMaps = zeros(nPerms,nMaps,nChannels);
 
    for p = 1:nPerms
        PermutedMaps(p,:,:) = MapsToSwap(1,permutations(p,:),:);
    end
    [PermFit,sgn] = GetMapSeriesOverallFit(PermutedMaps,MeanMap,RespectPolarity);
    [~,idx] = max(PermFit);
    if idx == 1
        Result = [];
    else
        Result = squeeze(PermutedMaps(idx,:,:)) .* repmat(sgn(idx,:)',1,nChannels);
    end
    Assignment = permutations(idx,:);
    Polarity = sgn(idx,:);
 end
