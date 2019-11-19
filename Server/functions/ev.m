function out = ev(bitList,val,prac)
    if(~exist('prac','var'))
        prac = false;
    end
    out = 0;
    if(prac)
        out = bitset(out,8);
    end
    for i=bitList
        out = bitset(out,i);
    end
    %disp(['EV DEBUG: out=' num2str(out) '  val=' num2str(val)]);
    out = bitor(out,val);