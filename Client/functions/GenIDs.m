ID_pool = cell(1,100);
for i = 1:100
    ID_pool{i} = genSubjID(5);
end
save('NF_SubjID.mat','ID_pool')


function [ID] = genSubjID(IDLength)
% Generate Subject ID
symbols = ['a':'z' 'A':'Z' '0':'9'];
%find number of random characters to choose from
numRands = length(symbols); 
%generate random string
ID = symbols(ceil(rand(1,IDLength)*numRands));
end