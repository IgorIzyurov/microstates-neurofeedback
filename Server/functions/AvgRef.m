function [DataOut] = AvgRef ( DataIn )
    Qch = size(DataIn,1);
    refmatrix = eye(Qch)-ones(Qch)*1/Qch;
    DataOut(1:Qch,:) = refmatrix*DataIn(1:Qch,:);
end