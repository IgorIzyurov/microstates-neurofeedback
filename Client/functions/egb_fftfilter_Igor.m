function yy=egb_fftfilter_Igor(EEG, Srate, lower,upper,type)


Fs = Srate;
N = size(EEG,2);
dF = Fs/N;
f = (-Fs/2:dF:Fs/2-dF)';      
if strcmp(type,'bandp')
    Filt = ((lower <= abs(f)) & (abs(f) < upper))';
elseif strcmp(type,'notch')
    Filt = ((abs(f) < lower) | (upper <= abs(f)))';
else
    error('bandp or notch?');
end
if ~any(Filt)
    yy=[];
    return;
end
for t=1:size(EEG,3)
    x=EEG(:,:,t);
    x=bsxfun(@minus,x,mean(x,2));
    spec = fftshift(fft(x,[],2),2);
    spec = bsxfun(@times,spec,Filt);     
    EEG(:,:,t)=ifft(ifftshift(spec,2),[],2, 'symmetric');
end
yy = EEG;
end
