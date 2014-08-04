
t = linspace(0, 4*pi, 1000);
windowSize = 50;
overlap = 49;

wave1 = sin(t);
wave2 = wave1;

DimTime = length(wave1);

corrmap = [];
nmaps = 1;

for i = 1:(windowSize-overlap):(DimTime-windowSize-1)
    if ((i+windowSize)<=DimTime)
        reftc=wave1(1,i:i+windowSize-1);
        imgtc=wave2(1,i:i+windowSize-1);
        temp=corrcoef(reftc,imgtc);
        corrmap(1,nmaps)=temp(2,1);
        nmaps=nmaps+1;
    else
        reftc=wave1(1,i:(DimTime-endlength));
        imgtc=wave2(1,i:(DimTime-endlength));
        temp=corrcoef(reftc,imgtc);
        corrmap(1,nmaps)=temp(2,1);
        nmaps=nmaps+1;
    end
end


figure;
plot(corrmap);
