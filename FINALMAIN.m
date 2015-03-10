%INITIALIZE VARIABLES
clc;clearvars;
db = [];
lbls = [];
allowed = 'allowed';
vulgar = 'vulgar ';
order = 12;
nfft = 512;
locs = [];
pks = [];
warning('off')

%TAKE USER INPUT
multiplyer = 5*str2double(input('Enter toxicity of speech from 6(Obama Speech) to 1(You will be scarred): ','s'));

%LOAD VULGAR WORDS
disp('Loading vulgar database...')
tstart = tic;
cd('wavfiles');
cd('BADWORDS');
wavfilesbad = dir('*.aiff');
for f = 1:2
    for i = 2:(numel(wavfilesbad))
        [speech, fs] = audioread(wavfilesbad(i).name);
        num = pyulear(mean(speech,2),order,nfft,fs)';
        num2 = pburg(mean(speech,2),order,nfft,fs)';
        num3 = pcov(mean(speech,2),order,nfft,fs)'/2;
        num4 = max(mean(speech,2));
        db = [db;num num2 num3];
        lbls = [lbls;vulgar];
    end
end
telapsed = toc(tstart);
disp('Time to load vulgar database:');
disp(telapsed);
disp('Number of Samples: ');
disp((i-1)*f);
disp(' ');

%LOAD ALLOWED WORDS
disp('Loading allowed database...')
tstart = tic;
cd('..');
cd('WORDS');
wavfilesgood = dir('*.aiff');
    for i = 2:(numel(wavfilesgood)-704)
        [speech, fs] = audioread(wavfilesgood(i).name);
        num = pyulear(mean(speech,2),order,nfft,fs)';
        num2 = pburg(mean(speech,2),order,nfft,fs)';
        num3 = pcov(mean(speech,2),order,nfft,fs)'/2;
        num4 = max(mean(speech,2));
        db = [db;num num2 num3];
        lbls = [lbls;allowed];
    end
telapsed = toc(tstart);
disp('Time to load allowed database:');
disp(telapsed);
disp('Number of Samples: ');
disp(i-1)
disp(' ');
cd('..');

%INITIALIZE SUPPORT VECTOR MACHINE
SVMmodel = fitcsvm(db,lbls);

%START CENSORING TEST
input('Press enter to start the censoring part...','s')
[audiofiletest,FS] = audioread('obama.mp3');
[bleep,~] = audioread('bleep.wav');
bleep = bleep/5;
audiofiletest = audiofiletest*(multiplyer*2);
n=1;
count = 0;
numwords = 0;
vulgarwords = 0;
timemeanvar = 0;
for i=1:20000:size(audiofiletest,1)
    tmeasure = tic;
    hold off;
    if size(audiofiletest(i:i+20000),2) > size(audiofiletest(i:i+20000),1)
        snippet = audiofiletest(i:i+20000)';
    end
    [pks,locs] = findpeaks(snippet,'MinPeakHeight',max(snippet)/5);
    plot(snippet,'Color','blue'); 
    hold on;
    plot(locs,snippet(locs),'k^','markerfacecolor',[1 0 0]);
    disp('Words in this snippet...');
    dp1 = pyulear(mean(snippet,2),order,nfft,fs)';
    dp2 = pburg(mean(snippet,2),order,nfft,fs)';
    dp3 = pcov(mean(speech,2),order,nfft,fs)'/2;
    classification = predict(SVMmodel,[dp1 dp2 dp3]);
    if numel(locs) <= 780 && numel(locs) >= 70
        if strcmp(classification,vulgar)
            sound(snippet,FS);
            vulgarwords = vulgarwords+1;
            y_n = input('Is this snippet vulgar? Y/N ','s');
            if strcmpi(y_n,'y')
                vulgarwords=vulgarwords-1;
                snippet = bleep;
            end
        else
            classification = allowed;
            numwords = numwords+1;
        end
        try 
            sound(snippet(locs(1)-300:locs(numel(locs))+300),FS);
        catch
            sound(snippet(locs(1):locs(numel(locs))),FS);
        end
    else
        numwords = numwords + 1;
        continue
    end
    disp(classification);
    disp(' ');
    timemeanvar = (timemeanvar + toc(tmeasure))/(count+1);
    numwords = numwords + 1;
    pause(0.4);
end
disp(strcat(num2str((1-(vulgarwords/numwords))*100),'% are classified correctly.'));
disp(strcat('Number of words: ',num2str(numwords)));
disp(strcat('Number classified incorrectly: ',num2str(vulgarwords)));
disp(strcat('Number classified correctly: ',num2str(numwords-vulgarwords)));
    