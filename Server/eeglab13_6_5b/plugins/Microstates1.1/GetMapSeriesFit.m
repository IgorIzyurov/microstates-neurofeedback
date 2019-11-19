function [TheFit,FitSign] = GetMapSeriesFit(IndMaps,Template,RespectPolarity)
    nCases = size(IndMaps,1);
    TheFit = mean(IndMaps.*repmat(Template,[nCases,1,1]),3);
    if ~RespectPolarity
        FitSign = sign(TheFit);
        TheFit = abs(TheFit);    
    else
        FitSign = ones(size(TheFit));
    end
end