clc;clearvars;
db = [];
lbls = [];
allowed = 'allowed';
vulgar = 'vulgar ';
order = 12;
nfft = 512;
Fs = 8000;

disp('Loading vulgar database...')
tstart = tic;
cd('wavfiles');
cd('BADWORDS');
wavfilesbad = dir('*.aiff');
%for f = 1:4
    for i = 2:(numel(wavfilesbad)-499)
        [speech, fs] = audioread(wavfilesbad(i).name);
        num = pyulear(mean(speech,2),order,nfft,fs)';
        num2 = pburg(speech,order,nfft,fs)';
        db = [db;num num2];
        lbls = [lbls;vulgar];
    end
%end
telapsed = toc(tstart);
disp('Time to load vulgar database:');
disp(telapsed);
disp('Number of Samples: ');
disp(i);
disp(' ');

disp('Loading allowed database...')
tstart = tic;
cd('..');
cd('WORDS');
wavfilesgood = dir('*.aiff');
%for f=1:3
    for i = 2:(numel(wavfilesgood)/2)
        [speech, fs] = audioread(wavfilesgood(i).name);
        num = pyulear(mean(speech,2),order,nfft,fs)';
        num2 = pburg(mean(speech,2),order,nfft,fs)';
        db = [db;num num2];
        lbls = [lbls;allowed];
    end
%end
telapsed = toc(tstart);
disp('Time to load allowed database:');
disp(telapsed);
disp('Number of Samples: ');
disp(i)
disp(' ');
cd('..');
SVMmodel = fitcsvm(db,lbls);
numaifffiles = dir('*.wav');
for i=1:numel(numaifffiles)
    filename = numaifffiles(i).name;
    [testaud,fs] = audioread(filename);
    testaudio = pyulear(mean(testaud,2),order,nfft,fs)';
    test2 = pburg(mean(testaud,2),order)';
    disp(filename);
    disp(predict(SVMmodel,[testaudio test2]));
    disp(' ');
end
cd('..')
[rapgod,fs]  = audioread('rapgodaudio.mp3');
loggaps = ones(size(rapgod));
testrec = audiorecorder;
cd('wavfiles')
cd('BADWORDS')
bfiles = dir('*.aiff');
for i=4:round(numel(bfiles)/20):numel(bfiles)
    disp(bfiles(i).name)
    [speech,fs] = audioread(bfiles(i).name);
    test1 = pyulear(mean(speech,2),order,nfft,fs)';
    test2 = pburg(mean(speech,2),order,nfft,fs)';
    disp(predict(SVMmodel, [test1 test2]));
    disp(' ');
end
cd('..')
cd('WORDS')
gfiles = dir('*.aiff');
for i=4:round(numel(gfiles)/20):numel(gfiles)
    disp(gfiles(i).name)
    [speech,fs] = audioread(gfiles(i).name);
    test1 = pyulear(mean(speech,2),order,nfft,fs)';
    test2 = pburg(mean(speech,2),order,nfft,fs)';
    disp(predict(SVMmodel, [test1 test2]));
    disp(' ');
end
cd('..')
for i = 1:10
    word = input('Enter the word you want to test: ','s');
    system(strcat('say -o ',word,'.aiff "',word,'"'));
    [speech,fs] = audioread(strcat(word,'.aiff'));
    dat1 = pyulear(mean(speech,2),order,nfft,fs)';
    dat2 = pburg(mean(speech,2),order,nfft,fs)';
    disp(predict(SVMmodel,[dat1 dat2]))
end
% for i=1:20
%     input('Press Enter to start the song...')
%     disp('Recording...')
%     recordblocking(testrec, 2);
%     disp('End Recording...')
%     disp(predict(SVMmodel, mean(pyulear(mean(getaudiodata(testrec),2),order,nfft,fs))))
% end
%for i=1:20000:size(rapgod,1)
%     if (rapgod(i)-rapgod(15000))/(i - (i - 15000)) < (-1*(10^-6))
%         loggaps(i-15000:i) = 0;
%     end
    %snippet = rapgod(i:i+20000);
    %disp('Playing sample...')
    %sound(snippet,fs);
    %disp(predict(SVMmodel,mean(snippet)));
    %input('Press enter to continue...','s');
%end
% WORD_FLAG = 0;
% for i = 1:numel(loggaps)
%     if loggaps(i) == 1
%         WORD_FLAG = WORD_FLAG + 1;
%     end
%     if mod(WORD_FLAG,2) == 0
        
    