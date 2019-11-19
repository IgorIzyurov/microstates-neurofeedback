function [EpochsTL, TimePointsTL] = GenSeq_MS(NTrials, RegTime, Srate)
while true
% Generate the sequence of regulations
EpochsReg = ['U','D'];
numRands = length(EpochsReg);
% CSZ - Condition Stimuli Rest
% CSR - Condition Stimuli Regulate if MS Neurofeed
% PAU - Pause
% FBZ - Feedback Empty
% FBR - Feedback Regulate
% ITI - Interstimulus interval, 5+-1 seconds, not used
RestEpoch = [{'CSZ','CSZ','PAU','PAU'}, repmat({'FBZ'}, [1, RegTime])];
UpEpoch = [{'CSU','CSU','PAU','PAU'}, repmat({'FBU'}, [1, RegTime])];
DownEpoch = [{'CSD','CSD','PAU','PAU'},repmat({'FBD'}, [1, RegTime])];
EpochsTL = [];
SecondsTL = [];
AddOrDel_Array = [1 2 3];
NoChange = 0;
AddITI = 0;
ReduceITI = 0;
for t = 1:NTrials*2
    Reg = EpochsReg(ceil(rand(1,1)*numRands));
    EpochsTL = [EpochsTL {['z' Reg ]}];
    if t >= 3 && isequal(EpochsTL{t-1}, ['z' Reg ]) && isequal(EpochsTL{t-2}, ['z' Reg ])
        EpochsTL(end) = [];
        Reg = EpochsReg(EpochsReg ~= Reg);
        EpochsTL = [EpochsTL {['z' Reg ]}];
    end
    
    if Reg=='U'
        X = UpEpoch;
    else
        X = DownEpoch;
    end
    
    
    if NoChange >= floor(NTrials*4/3)
        AddOrDel_Array(AddOrDel_Array==1) = [];
    end
    if AddITI >= ceil(NTrials*4/3)
        AddOrDel_Array(AddOrDel_Array==2) = [];
    end
    if ReduceITI >= ceil(NTrials*4/3)
        AddOrDel_Array(AddOrDel_Array==3) = [];
    end
    
    ITI = {'ITI', 'ITI', 'ITI', 'ITI', 'ITI'};
    AddOrDel = AddOrDel_Array(ceil(rand(1,1)*length(AddOrDel_Array)));
    if AddOrDel == 1
        NoChange = NoChange + 1;
    elseif AddOrDel == 2
        ITI = [ITI 'ITI'];
        AddITI = AddITI + 1;
    elseif AddOrDel == 3
        ITI(end) = [];
        ReduceITI = ReduceITI + 1;
    end
%     SecondsTL = [SecondsTL RestEpoch ITI]; % uncomment if want to use ITI
     SecondsTL = [SecondsTL RestEpoch]; % comment if want to use ITI
    
    if NoChange >= 18
        AddOrDel_Array(AddOrDel_Array==1) = [];
    end
    if AddITI >= 19
        AddOrDel_Array(AddOrDel_Array==2) = [];
    end
    if ReduceITI >= 19
        AddOrDel_Array(AddOrDel_Array==3) = [];
    end
    
    ITI = {'ITI', 'ITI', 'ITI', 'ITI', 'ITI'};
    AddOrDel = AddOrDel_Array(ceil(rand(1,1)*length(AddOrDel_Array)));
    if AddOrDel == 1
        NoChange = NoChange + 1;
    elseif AddOrDel == 2
        ITI = [ITI 'ITI'];
        AddITI = AddITI + 1;
    elseif AddOrDel == 3
        ITI(end) = [];
        ReduceITI = ReduceITI + 1;
    end
    
%     SecondsTL = [SecondsTL X ITI]; % uncomment if want to use ITI
    SecondsTL = [SecondsTL X]; % comment if want to use ITI
    
      
end
EpochsTL = sprintf('%s', EpochsTL{:});
TimePointsTL = cell(1,length(SecondsTL)*Srate);
for t = 1:length(SecondsTL)
    c_start = t*Srate - Srate + 1;
    c_end = c_start + Srate-1;
    TimePointsTL(c_start:c_end) = repmat(SecondsTL(t), [1, Srate]);
end
TimePointsTL = ['RUN' TimePointsTL 'END'];
if sum(EpochsTL == 'U') == sum(EpochsTL == 'D')
    break
end
end
end