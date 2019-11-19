

function sendEvent(code)

config_io;
% Start menu -> msconfig -> Tools -> System Information -> Launch ->
% Hardware Resources -> IO -> 0x0000037F -> '037F'
addr = hex2dec('A030');


outp(addr,0);

outp(addr,code);
pause(0.010);
outp(addr,0);

end


    