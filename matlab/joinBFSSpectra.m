function [xpol,ypol] = joinBFSSpectra(bfsStruct)

nSpec = length(bfsStruct);
ephemStr = bfsStruct{1}(1).ephem;

polyOrd = 15;
polyxErr = Inf;
polyyErr = Inf;
bestXPoly = [];
bestYPoly = [];

nSigmaStd = 4;

xPolData = cell(nSpec,1);
xPolFreq = cell(nSpec,1);

yPolData = cell(nSpec,1);
yPolFreq = cell(nSpec,1);

for iK = 1:nSpec
    nX = 1;
    nY = 1;
    for iL = 1:length(bfsStruct{iK})
        if(bfsStruct{iK}(iL).pol == 'x')
            if (nX == 1)
                xPolData{iK} = bfsStruct{iK}(iL).data;
                xPolFreq{iK} = bfsStruct{iK}(iL).flist;
                nX = nX + 1;
            else
                assert(all(bfsStruct{iK}(iL).flist == xPolFreq{iK}),'ATATools:Calc:joinBFSSpectra','freq data mistmatch')
                xPolData{iK} = xPolData{iK} + bfsStruct{iK}(iL).data;
                nX = nX + 1;
            end
        elseif(bfsStruct{iK}(iL).pol == 'y')
            if (nY == 1)
                yPolData{iK} = bfsStruct{iK}(iL).data;
                yPolFreq{iK} = bfsStruct{iK}(iL).flist;
                nY = nY + 1;
            else
                assert(all(bfsStruct{iK}(iL).flist == yPolFreq{iK}),'ATATools:Calc:joinBFSSpectra','freq data mistmatch')
                yPolData{iK} = yPolData{iK} + bfsStruct{iK}(iL).data;
                nY = nY + 1;
            end
        else
            error('ATATools:Calc:joinBFSSpectra','unknown polarization %s',bfsStruct{iK}(iL).pol)
        end
    end
    
    xxx = linspace(-1,1,length(xPolFreq{iK})).';
    xxy = linspace(-1,1,length(yPolFreq{iK})).';
    
    mvalx = median(xPolData{iK});
    mvaly = median(yPolData{iK});
    svalx = min([std(xPolData{iK}(1:end/3)),std(xPolData{iK}(end/3:2*end/3)),std(xPolData{iK}(2*end/3:end))]);
    svaly = min([std(yPolData{iK}(1:end/3)),std(yPolData{iK}(end/3:2*end/3)),std(yPolData{iK}(2*end/3:end))]);
    
    yyx = (xPolData{iK}-mvalx)/svalx;
    yyy = (yPolData{iK}-mvaly)/svaly;
    
    yyxSat = yyx;
    yyySat = yyy;
    yyxSat(yyxSat>nSigmaStd) = nSigmaStd;
    yyxSat(yyxSat<-nSigmaStd) = -nSigmaStd;
    yyySat(yyySat>nSigmaStd) = nSigmaStd;
    yyySat(yyySat<-nSigmaStd) = -nSigmaStd;
    
    
    PX = polyfit(xxx,yyxSat,polyOrd);
    PY = polyfit(xxy,yyySat,polyOrd);
    
    xPolData{iK} = (yyx - polyval(PX,xxx))*svalx + mvalx;
    yPolData{iK} = (yyy - polyval(PY,xxy))*svaly + mvaly;
    
    %     ErrX = sum((yyx - polyval(PX,xxx)).^2);
    %     ErrY = sum((yyy - polyval(PY,xxy)).^2);
    %
    %     if (ErrX < polyxErr)
    %         bestXPoly = PX;
    %         polyxErr = ErrX;
    %     end
    %     if (ErrY < polyyErr)
    %         bestYPoly = PY;
    %         polyyErr = ErrY;
    %     end
end

% for iK = 1:nSpec
%     mvalx = median(xPolData{iK});
%     mvaly = median(yPolData{iK});
%     %svalx = std(xPolData{iK});
%     %svaly = std(yPolData{iK});
%
%     svalx = min([std(xPolData{iK}(1:end/3)),std(xPolData{iK}(end/3:2*end/3)),std(xPolData{iK}(2*end/3:end))]);
%     svaly = min([std(yPolData{iK}(1:end/3)),std(yPolData{iK}(end/3:2*end/3)),std(yPolData{iK}(2*end/3:end))]);
%
%     xxx = linspace(-1,1,length(xPolFreq{iK})).';
%     xxy = linspace(-1,1,length(yPolFreq{iK})).';
%
%     xPolData{iK} = (xPolData{iK}-mvalx)/svalx - polyval(bestXPoly,xxx);
%     yPolData{iK} = (yPolData{iK}-mvaly)/svaly - polyval(bestYPoly,xxy);
% end

if 1
    figure(1)
    plot(xPolFreq{1},xPolData{1});
    hold on
    for iK = 2:nSpec
        plot(xPolFreq{iK},xPolData{iK});
    end
    hold off
end
if 0
    figure(2)
    plot(yPolFreq{1},yPolData{1});
    hold on
    for iK = 2:nSpec
        plot(yPolFreq{iK},yPolData{iK});
    end
    hold off
end

xpol = mergeChannel(xPolFreq,xPolData);
ypol = mergeChannel(yPolFreq,yPolData);

if(0)
    figure(1)
    hold on
    plot(xpol.freq,xpol.data);
    hold off;
end
if(0)
    figure(2)
    hold on
    plot(ypol.freq,ypol.data);
    hold off;
end

end

function data = mergeChannel(polFreq,polData)

%now, 2 cases are possible: 1st: end part of yPolFreq{iN} and begining of
%yPolFreq{iN+1} share the same points. In such case, we average them with
%overlaping parts.
%in second scenario, data does not overlap. Preserving both data points but
%adding a constant to "even" the transition.
%in both cases a median level of "noise floor" is calculated for the
%overlaping regions and each data point is scaled with respect to that.

yFreqList = [];
yDataList = [];

nSpec = length(polFreq);

if(diff(polFreq{1}(1:2)) < 0)
    %frequency list is inverted
    lastIdx = length(polFreq{1});
    for iK = 1:nSpec-1
        id1 = find(polFreq{iK+1} < polFreq{iK}(1),1);
        id2 = find(polFreq{iK} < polFreq{iK+1}(end),1);
        
        mValueCurr = median(polData{iK}(1:id2));
        mValueNext = median(polData{iK+1}(id1:end));
        
        freqInters = intersect(polFreq{iK}(1:id2-1),polFreq{iK+1}(id1:end));
        freqCurrAdj = setdiff(polFreq{iK}(1:id2-1),polFreq{iK+1}(id1:end));
        freqNextAdj = setdiff(polFreq{iK+1}(id1:end),polFreq{iK}(1:id2-1));
        
        freqLow = min(polFreq{iK+1}(end),polFreq{iK}(id2));
        freqHigh = max(polFreq{iK+1}(id1),polFreq{iK}(1));
        
        freqDiff = freqHigh - freqLow;
        
        freqVectNonOverlap = polFreq{iK}(lastIdx:-1:id2);
        dataVectNonOverlap = polData{iK}(lastIdx:-1:id2);
        

        
        dataInters= zeros(size(freqInters));
        dataCurrAdj = zeros(size(freqCurrAdj));
        dataNextAdj = zeros(size(freqNextAdj));
        
        for iZ = 1:length(dataInters)
            idd1 = find(polFreq{iK}(1:id2) == freqInters(iZ));
            idd2 = find(polFreq{iK+1}(id1:end) == freqInters(iZ)) - 1;
            dd1 = polData{iK}(idd1);
            dd2 = polData{iK+1}(id1 + idd2);
            scaleInterpFactor = (freqLow- freqInters(iZ))/freqDiff;
            offsetCurr = (mValueNext-mValueCurr)*scaleInterpFactor;
            offsetNew = (mValueNext-mValueCurr) + (mValueNext-mValueCurr)*(scaleInterpFactor);
            dataInters(iZ) = (dd1 - offsetCurr + dd2 - offsetNew)/2;
        end
        
        for iZ = 1:length(dataCurrAdj)
            idd1 = find(polFreq{iK}(1:id2) == freqCurrAdj(iZ));
            dd1 = polData{iK}(idd1);
            scaleInterpFactor = (freqLow- freqCurrAdj(iZ))/freqDiff;
            %offsetCurr = mValueCurr*(1-scaleInterpFactor) + mValueNext*scaleInterpFactor;
            offsetCurr = (mValueNext-mValueCurr)*scaleInterpFactor;
            dataCurrAdj(iZ) = dd1 - offsetCurr;
        end
        
        for iZ = 1:length(dataNextAdj)
            idd2 = find(polFreq{iK+1}(id1:end) == freqNextAdj(iZ)) - 1;
            dd2 = polData{iK+1}(id1 + idd2);
            scaleInterpFactor = (freqLow- freqNextAdj(iZ))/freqDiff;
            %offsetNew = mValueCurr*(1-scaleInterpFactor) + mValueNext*(scaleInterpFactor);
            offsetNew = (mValueNext-mValueCurr) + (mValueNext-mValueCurr)*(scaleInterpFactor);
            dataNextAdj(iZ) = dd2  - offsetNew;
        end
        
        concatFreqVec = [freqInters,freqCurrAdj,freqNextAdj];
        concatDataVec = [dataInters,dataCurrAdj,dataNextAdj];
        [sortFreq,idxFreq] = sort(concatFreqVec);
        sortData = concatDataVec(idxFreq);
        
        yFreqList = [yFreqList,freqVectNonOverlap,sortFreq];
        yDataList = [yDataList,dataVectNonOverlap.',sortData];
        
        lastIdx = id1+1;
    end
    freqVectNonOverlap = polFreq{iK+1}(lastIdx:-1:1);
    dataVectNonOverlap = polData{iK+1}(lastIdx:-1:1);
    yFreqList = [yFreqList,freqVectNonOverlap];
    yDataList = [yDataList,dataVectNonOverlap.'];
    data.freq = yFreqList;
    data.data = yDataList;
else
    error('needs testing!')
end

end
