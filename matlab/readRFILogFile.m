function dataStr =  readRFILogFile(filename)


[fd,msg] = fopen(filename);
assert(fd ~= -1,'ATATools:IO:readRFILogFile',msg)

antName = cell(0,1);
az = zeros(0,1);
el = zeros(0,1);
freq = zeros(0,1);
datadir = cell(0,1);

iK = 1;
while 1
    tline = fgetl(fd);
    if ~ischar(tline), break, end

    [a] = textscan(tline,'%s : %f : %f : %f : %s');
    antName{iK} = a{1}{1};
    az(iK) = a{2};
    el(iK) = a{3};
    freq(iK) = a{4};
    datadir{iK} = a{5}{1};
    %1a : 0.0 : 66.5 : 5880.0 : 2019/05/17/2019-5-17-20-48-32-BF1
    
    iK = iK + 1;
end
fclose(fd);

    antName{iK} = '1b';
    az(iK) = 0;
    el(iK) = 0;
    freq(iK) = 0;
    datadir{iK} = 'null';

dataStr.antenna = antName;
dataStr.az = az;
dataStr.el = el;
dataStr.freq = freq;
dataStr.datadir = datadir;

end