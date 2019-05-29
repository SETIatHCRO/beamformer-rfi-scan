clearvars
close all

%%

dataDir='/home/jkulpa/Current/ATA_meas/RFImeas/rfiScan/';
dataFile = 'logfile_rfiScan_20190517_180019.log';
imagedir = '/home/jkulpa/Current/RadAstron/imgs/rfi';


[retStruct] = ATATools.IO.readRFILogFile([dataDir filesep dataFile]);

[uniqueAntennas,bIdx,cIdx] = unique(retStruct.antenna);
NFiles =  length(retStruct.antenna);

NCells = length(uniqueAntennas);

%%

antennaCells = cell(NCells,1);

for iK = 1:NCells
    antennaCells{iK}.antenna = retStruct.antenna(cIdx == iK);
    antennaCells{iK}.az = retStruct.az(cIdx == iK);
    antennaCells{iK}.el = retStruct.el(cIdx == iK);
    antennaCells{iK}.freq = retStruct.freq(cIdx == iK);
    antennaCells{iK}.datadir = retStruct.datadir(cIdx == iK);
end

%%

for iK = 1:NCells
    currCell =  antennaCells{iK};
    [uniqueAz,~,idAz] = unique(antennaCells{iK}.az);
    for iL = 1:length(uniqueAz)
        cellPart.antenna = currCell.antenna(idAz == iL);
        cellPart.az = currCell.az(idAz == iL);
        cellPart.el = currCell.el(idAz == iL);
        cellPart.freq = currCell.freq(idAz == iL);
        cellPart.datadir = currCell.datadir(idAz == iL);
        
        [uniqueEl,~,idEl] = unique(cellPart.el);
        for iM = 1:length(uniqueEl)
            cellPart2.antenna = cellPart.antenna(idEl == iM);
            cellPart2.az = cellPart.az(idEl == iM);
            cellPart2.el = cellPart.el(idEl == iM);
            cellPart2.freq = cellPart.freq(idEl == iM);
            cellPart2.datadir = cellPart.datadir(idEl == iM);
            
            nfreq = length(cellPart2.freq);
            
            freqData = cell(nfreq,1);
            for iN = 1:nfreq
                nsplit = split(cellPart2.datadir{iN},'/');
                freqData{iN} = ATATools.IO.atabfsread([dataDir filesep nsplit{end} filesep 'atabf.bfs']);         
            end
            
            [dataX,dataY] = ATATools.Calc.joinBFSSpectra(freqData);
            
            clear freqData
            
            save(sprintf('%s%crfiScan_ant_%s_az_%f_el_%f.mat',imagedir,filesep,cellPart2.antenna{1},cellPart2.az(1),cellPart2.el(1)),'dataX','dataY');
            h1 = figure(1);
            plot(dataX.freq,10*log10(dataX.data));
            xlabel('frequency [MHz]')
            ylabel('power [dB]')
            title(sprintf('%sx1 %f %f',cellPart2.antenna{1},cellPart2.az(1),cellPart2.el(1)))
            print(h1,sprintf('%s%crfiScan_ant_%sx1_az_%f_el_%f.png',imagedir,filesep,cellPart2.antenna{1},cellPart2.az(1),cellPart2.el(1)), '-dpng', '-r300')
            h2 = figure(2);
            plot(dataY.freq,10*log10(dataY.data));
            xlabel('frequency [MHz]')
            ylabel('power [dB]')
            title(sprintf('%sy1 %f %f',cellPart2.antenna{1},cellPart2.az(1),cellPart2.el(1)))
            print(h2,sprintf('%s%crfiScan_ant_%sy1_az_%f_el_%f.png',imagedir,filesep,cellPart2.antenna{1},cellPart2.az(1),cellPart2.el(1)), '-dpng', '-r300')
        end
    end
end
