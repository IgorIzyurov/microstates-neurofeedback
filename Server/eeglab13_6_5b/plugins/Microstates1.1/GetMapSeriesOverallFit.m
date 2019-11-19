function [MeanFit,FitSign] = GetMapSeriesOverallFit(IndMaps,Template,RespectPolarity)
    [TheFit,FitSign] = GetMapSeriesFit(IndMaps,Template,RespectPolarity);
    MeanFit = mean(TheFit,2);
end