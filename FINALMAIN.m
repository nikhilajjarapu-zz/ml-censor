clc;clearvars;
db = [];
lbls = [];
allowed = 'allowed';
vulgar = 'vulgar ';
order = 12;
nfft = 512;
wordlocs = {};
locs = [];
pks = [];
warning('off')

multiplyer = 5*str2double(input('Enter toxicity of speech from 5(Obama Speech) to 1(You will be scarred): ','s'));
%LOAD VULGAR WORDS
disp('Loading vulgar database...')
tstart = tic;
cd('wavfiles');
cd('BADWORDS');
wavfilesbad = dir('*.aiff');
for f = 1:2
    for i = 2:(numel(wavfilesbad)-506)
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
%for f=1:2
    for i = 2:(numel(wavfilesgood)-2)
        [speech, fs] = audioread(wavfilesgood(i).name);
        num = pyulear(mean(speech,2),order,nfft,fs)';
        num2 = pburg(mean(speech,2),order,nfft,fs)';
        num3 = pcov(mean(speech,2),order,nfft,fs)'/2;
        num4 = max(mean(speech,2));
        db = [db;num num2 num3];
        lbls = [lbls;allowed];
    end
%end
telapsed = toc(tstart);
disp('Time to load allowed database:');
disp(telapsed);
disp('Number of Samples: ');
disp(i-1)

disp(' ');
cd('..');
SVMmodel = fitcsvm(db,lbls);
% numaifffiles = dir('*.wav');
% for i=1:numel(numaifffiles)
%     filename = numaifffiles(i).name;
%     [testaud,fs] = audioread(filename);
%     testaudio = pyulear(mean(testaud,2),order,nfft,fs)';
%     test2 = pburg(mean(testaud,2),order,nfft,fs)';
%     disp(filename);
%     disp(predict(SVMmodel,[testaudio test2]));
%     disp(' ');
% end
cd('..')
cd('wavfiles')
cd('BADWORDS')
bfiles = dir('*.aiff');
for i=4:round(numel(bfiles)/4):numel(bfiles)
    disp(bfiles(i).name)
    [speech,fs] = audioread(bfiles(i).name);
    test1 = pyulear(mean(speech,2),order,nfft,fs)';
    test2 = pburg(mean(speech,2),order,nfft,fs)';
    test3 = pcov(mean(speech,2),order,nfft,fs)'/2;
    test4 = max(mean(speech,2));
    disp(predict(SVMmodel, [test1 test2 test3]));
    disp(' ');
end
cd('..')
cd('WORDS')
gfiles = dir('*.aiff');
for i=4:round(numel(gfiles)/4):numel(gfiles)
    disp(gfiles(i).name)
    [speech,fs] = audioread(gfiles(i).name);
    test1 = pyulear(mean(speech,2),order,nfft,fs)';
    test2 = pburg(mean(speech,2),order, nfft, fs)';
    test3 = pcov(mean(speech,2),order,nfft,fs)'/2;
    test4 = max(mean(speech,2));
    disp(predict(SVMmodel, [test1 test2 test3]));
    disp(' ');
end
cd('..')
% for i = 1:10
%     word = input('Enter the word you want to test: ','s');
%     if i == 1 && strcmp(word,'skip')
%         break;
%     end
%     system(strcat('say -o  ',word,'.aiff "',word,'"'));
%     [speech,fs] = audioread(strcat(word,'.aiff'));
%     dat1 = pyulear(mean(speech,2),order,nfft,fs)';
%     dat2 = pburg(mean(speech,2),order,nfft,fs)';
%     disp(predict(SVMmodel,[dat1 dat2]))
% end
% for i=1:20
%     input('Press Enter to start the song...')
%     disp('Recording...')
%     recordblocking(testrec, 2);
%     disp('End Recording...')
%     disp(predict(SVMmodel, mean(pyulear(mean(getaudiodata(testrec),2),order,nfft,fs))))
% end
cd('..');
[rapgod,FS] = audioread('obama.mp3');
[bleep,~] = audioread('bleep.wav');
bleep = bleep/5;
rapgod = rapgod.*multiplyer;
n=1;
for i=45000:20000:size(rapgod,1)
    %if (rapgod(i)-rapgod(15000))/(i - (i - 15000)) < (-1*(10^-6))
    %    loggaps(i-15000:i) = 0;
    %end
    hold off;
    snippet = rapgod(i:i+20000)';
    [pks,locs] = findpeaks(snippet,'MinPeakHeight',max(snippet)/5);
%     for j = 2:numel(locs)
%         if locs(j) - locs(j-1) > 2000
%             wordlocs{n} = [pks(1:j)];
%             n = n + 1;
%             pks(1:j) = [];
%         end
%     end
    plot(snippet,'Color','blue'); 
    hold on;
    plot(locs,snippet(locs),'k^','markerfacecolor',[1 0 0]);
    disp('Words in this snippet...');
    dp1 = pyulear(mean(snippet,2),order,nfft,fs)';
    dp2 = pburg(mean(snippet,2),order,nfft,fs)';
    dp3 = pcov(mean(speech,2),order,nfft,fs)'/2;
    classification = predict(SVMmodel,[dp1 dp2 dp3]);
    if numel(locs) <= 750 && numel(locs) >= 50 && median(mean(snippet,2)) - locs(numel(locs)/2) >= 20
        if strcmp(classification,vulgar)
            snippet = bleep;
        end
        try 
            sound(snippet(locs(1)-300:locs(numel(locs))+300),FS);
        catch
            sound(snippet(locs(1):locs(numel(locs))),FS);
        end
    else
        continue
    end
    %input('Press enter to continue...','s');
%     disp('Plotting...')
%     disp('Playing sample...')
%     sound(snippet,fs);
    disp(classification);
    disp(' ');
    pause(0.3);
end
% WORD_FLAG = 0;
% for i = 1:numel(loggaps)
%     if loggaps(i) == 1
%         WORD_FLAG = WORD_FLAG + 1;
%     end
%     if mod(WORD_FLAG,2) == 0
        
    