 order = 12;
 nfft = 512;
 Fs = 8000;
 beastmode = audiorecorder;   
 for i=1:3
    yn = input('\nReady to record? Y/N ','s');
    if yn == 'Y' 
        hold off;
        disp('Recording...')
        recordblocking(beastmode,2);
        speech = getaudiodata(beastmode);
        disp('End recording. Plotting...');
        pydata = pyulear(speech,order,nfft,Fs);
        plot(1:numel(pydata),pydata);
        hold on;
        input('Paused...');
        coeff = polyfit((1:numel(pydata))',pydata,4);
        x = 1:300;
        y = polyval(coeff,x);
        for i=250:300
            if y(i) < 0
                y(i) = [];
                x(i) = [];
            end
        end
        hold on;
        plot(x,y);
        hold on;
    end
 end