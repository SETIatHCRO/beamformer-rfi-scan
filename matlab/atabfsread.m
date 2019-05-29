%========================================================================
% ataimport2(fn...)
%
% Written for beamformer metadata July 21, 2008
% Reads the entire beamformer data file and returns structured data
%========================================================================

function dataholder = atabfsread(fn)


%function [x,tai,datestring,memcounts] = ataimport2(fn, subdir,nodat)

%====================================
% Each line in the file is its own entry
% The meta data format for the file:
%====================================
% [0]	Beamformer:	Indicates the beamfromer ID (1 or 2 currently)
% [1]	Data Type:	Category of write.  See above.
% [2]	Time (String):	String of current date/time
% [3]	Time (Numeric):	Numeric (seconds since 1970), NOT TAI!
% [4]	Sky Frequency:	Floating point MHz
% [5]	User Pointing:	The user's commanded ephem file, if present
% [6]	User Offset Az:	The user's offset azimuth command
% [7]	User Offset El:	The user's offset elevation command
% [8]	Current Az:	The current azimith (read from child ant?)
% [9]	Current El:	The current elevation (read from child ant?)
%			Note az/el only work if pointing has been loaded
%			in this mode, and not as raw geopoint!
% [10]	Hookup Type:	Category of hookup. (1) Antenna, (2) FPGA
% [11]	Hookup Name:	String name of the hookup
% [12]	CalDelay:	The bulk delay from the hookup cal
% [13]	CalPhasorReal:	The phasor from the hookup cal, real part
% [14]  CalPhasorImag:	The phasor from the hookup cal, imag part
% [15]	CalDpDf:	The dp/df from the hookup cal	
% [16]	Obs time:	The observation time, in seconds
% [17]	Data Length:	Reserved currently, but might be length of following data
% [18]	idx:		The index number of the snap (optional)
% [19]	pol:		The polarziation of the snap (optional)
% [20]  bandwidth:  The bandwidth of the spectra (optional, 0 = 104 MHz)
% [21]..[24]		Reserved meta data
% --> The data codes <ririririri...> follow meta data


% c:\cygwin\home\barottw\bfu

    %fn = sprintf('c:\\cygwin\\home\\billy\\ruby\\snap\\%s%s', subdir, fn);
    %fn = sprintf('c:\\cygwin\\home\\billy\\bfu\\%s%s', subdir, fn);
    %fn = sprintf('c:\\cygwin\\home\\barottw\\bfu\\%s%s', subdir, fn);
    %fn = sprintf('c:\\cygwin\\home\\billy\\snaps\\%s%s', fn);
   % fn = sprintf('d:\\ATA Data\\%s%s', fn);
    %fn = sprintf('p:\\caltest\\%s',fn);
 
disp('ATABFSREAD: Opening the following data file:')
disp(fn)
xf = fopen(fn,'r');
dd =  textscan(xf,'%d %d %s %f %f %s %f %f %f %f %d %s %f %f %f %f %f %d %d %c %f %d %s %d %d %100000000[^\n]    ','delimiter','\t','emptyValue',0); %,'bufsize',2000000);

% dd now contains a 1x26 cell array.  The first 25 entries are meta data,
% and the last entry contains the snapshot data that was written here.
% All snapshot data is complex pairs, so we'll interpret:

xdata = dd{26};
nrows = length(xdata);
for inc = 1:nrows
    %Interpret data:
    xcd = xdata{inc};
    xvpair = sscanf(xcd,'%f');
    xvreal = xvpair(1:2:(length(xvpair)));
    xvimag = xvpair(2:2:(length(xvpair)));
    if length(xvreal) ~= length(xvimag)
        disp('Lengths not equal for real/imag, exiting');
        fclose(xf);
        return;
    end
    xval = xvreal + i*xvimag;
    
    %Now read meta data:
    meta_bf = dd{1}(inc);
    meta_scantype = dd{2}(inc);
    meta_times = dd{3}(inc);
    meta_timen = dd{4}(inc);
    meta_freq = dd{5}(inc);
    meta_ephem = dd{6}(inc);
    meta_offsetaz = dd{7}(inc);
    meta_offsetel = dd{8}(inc);
    meta_pointaz = dd{9}(inc);
    meta_pointel = dd{10}(inc);
    meta_hookup = dd{11}(inc);
    meta_hookupname = dd{12}(inc);
    meta_caldelay = dd{13}(inc);
    meta_calphasorreal = dd{14}(inc);
    meta_calphasorimag = dd{15}(inc);
    meta_caldpdf = dd{16}(inc);
    meta_obstime = dd{17}(inc);
    meta_dlen = dd{18}(inc);
    meta_idx = dd{19}(inc);
    meta_pol = dd{20}(inc);
    meta_bw = dd{21}(inc);
    meta_huref = dd{23}(inc);
    
    % Need double assignemnt to strip the cell
    dh.bf = meta_bf;
    dh.scantype = meta_scantype;
    if meta_bw == 0
        atafrange = 838.8608 / 16;
    else
        atafrange = meta_bw / 2;
    end
    switch dh.scantype
        case 1
            dh.scanlabel = 'Cross Correlation';
            meta_freqlist = linspace(meta_freq+atafrange, meta_freq-atafrange, length(xval));
            xval = fftshift(xval);
        case 2
            dh.scanlabel = 'Auto Correlation';
            meta_freqlist = linspace(meta_freq+atafrange, meta_freq-atafrange, length(xval));
            xval = fftshift(xval);
        case 3
            dh.scanlabel = 'Link Diagnostics';
            meta_freqlist = [];
        case 4
            dh.scanlabel = 'Beam Output';
            % For yvette, remove the first data from the autocorrelation
            % (DC channel).... This may be removed later...
            xval = xval(2:length(xval));
            meta_freqlist = linspace(meta_freq+atafrange, meta_freq-atafrange, length(xval));
            xval = fftshift(xval);
    end
    dh.times = meta_times{1};
    dh.timen = meta_timen;
    dh.freq = meta_freq;
    dh.ephem = meta_ephem{1};
    dh.pointoffset = [meta_offsetaz, meta_offsetel];
    dh.point = [meta_pointaz, meta_pointel];
    dh.hutype = meta_hookup;
    switch dh.hutype
        case 1
            dh.hutypelabel = 'Antenna';
        case 2
            dh.hutypelabel = 'FPGA';
    end
    
    dh.huname = meta_hookupname{1};
    dh.huref = meta_huref{1};
    dh.caldelay = meta_caldelay;
    dh.calphasor = meta_calphasorreal + i*meta_calphasorimag;
    dh.caldpdf = meta_caldpdf;
    dh.obstime = meta_obstime;
    dh.index = meta_idx;
    dh.pol = meta_pol;
    dh.data = xval;
    dh.flist = meta_freqlist;
    
    dataholder(inc) = dh;
end

fclose(xf);


