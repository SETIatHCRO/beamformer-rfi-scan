#!/usr/bin/env python
import os
import subprocess
from optparse import OptionParser
import sys
import antennapols
import signal
import numpy
import time

global antennasInUse

def signal_handler(sig,frame):
  print("Exiting on SIGINT")
  p = callProg(['fxconf.rb sagive bfa none ' + antennasInUse])
  sys.exit(1)

def callProg(mystring,readall=0,ignoreerrors=0):
  print mystring
  p = subprocess.Popen(mystring, stdout=subprocess.PIPE, shell=True)
  p.wait()
  if not ignoreerrors:
    if(p.returncode):
      print "program " + mystring[0] + " returned error"
      print p.stdout.read()
      os.kill(os.getpid(),signal.SIGINT)
      time.sleep(1)
      sys.exit(1)
  if(readall):
    print p.stdout.read()
  return p

def scanRFI(options,antennas):
  freqShift = 94.3718 #90% of 104.8576 MHz
  azVec = numpy.arange(0,360,options.azstep)
  elVec = numpy.arange(18,90,options.elstep)
  freqVec = numpy.arange(options.startf,options.stopf,freqShift)
  antennastr = antennas.split(",")

  logFile = open(options.folder + "/logfile_rfiScan_" + time.strftime("%Y%m%d_%H%M%S") + ".log","w")

  for ant in antennastr:
    pols = ant + "x1," + ant + "y1"
    p = callProg(['atasetfocus ' + ant + ' ' + str(options.stopf)],options.verbose) 
    p = callProg(['atasetpams ' + ant],options.verbose) 
    p = callProg(['atalnaon ' + ant],options.verbose) 

    if(options.bank == 1):
      mixer = 'c'
    elif(options.bank == 2 or options.bank == 3):
      mixer = 'd'
    else:
      print("bad bank number")
      os.kill(os.getpid(),signal.SIGINT)
      time.sleep(1)

    p = callProg(['atasetskyfreq ' + mixer + ' ' +str(options.startf)])
    p = callProg(['bfibob ' + str(options.bank) + ' sky'],options.verbose)
    p = callProg(['bfibob ' + str(options.bank) + ' walsh'],options.verbose)
    p = callProg(['bfibob ' + str(options.bank) + ' autoatten'],options.verbose)
    p = callProg(['~/bbarott/bfu/bfinit.rb -b ' + str(options.bank) + ' -a ' + pols],options.verbose)
    p = callProg(['~/bbarott/bfu/bftrackephem.rb -b ' + str(options.bank) + ' -f ' + str(options.startf)  + ' -i 10 --caldelay -n 3 -e 0:18 --calbw 0.6'],options.verbose)
    for curraz in azVec:
      for currel in elVec:
        p = callProg(['atasetazel -w -q ' + ant + ' ' + str(curraz) + ' ' + str(currel) ])
        for currF in freqVec:
          p = callProg(['~/bbarott/bfu/bftrackephem.rb -b ' + str(options.bank) + ' -f ' +str(currF) + ' -i ' + str(options.tint) + ' --write out -n 3 -d 30 -e ' + str(curraz) + ":" + str(currel)],0,1)
          line = p.stdout.readline()
          while line.find("Changing Snapshot Directory to ") == -1:
            if (options.verbose):
              print(line)
            line = p.stdout.readline()
          names = line.split("Changing Snapshot Directory to ")
          logFile.write(ant + " : " + str(curraz) + " : " + str(currel) + " : " + str(currF) + " : " + names[1] )
          logFile.flush()
          workName = " ".join(names[1].split())
          print workName
          p = callProg(['rsync -a obs@boot2:/opt/bfu/data/' + workName + ' ' + options.folder])
  
  logFile.close()

if __name__ == "__main__":
  usage = "Usage %prog [options] antennas"
  parser = OptionParser(usage=usage)
  parser.add_option("-d", "--dir`", action="store", type="str", dest="folder", default=".",
    help="the output files directory '.'", metavar="DIRECTORY")
  parser.add_option("-t", "--tint`", action="store", type="int", dest="tint", default=10,
    help="beamformer integration time", metavar="TINT")
  parser.add_option("-b", "--bank`", action="store", type="int", dest="bank", default=1,
    help="set beamformer bank [1|2|3]", metavar="BF_NO")
  parser.add_option("-f", "--freqstart`", action="store", type="float", dest="startf", default=1000.0,
    help="set the start scan frequency [MHz]", metavar="SKYFREQ")
  parser.add_option("-s", "--freqstop`", action="store", type="float", dest="stopf", default=9000.0,
    help="set the start scan frequency [MHz]", metavar="SKYFREQ")
  parser.add_option("-a", "--azimuthstep`", action="store", type="float", dest="azstep", default=10.0,
    help="step in azimuth", metavar="ANGLE")
  parser.add_option("-e", "--elevationstep`", action="store", type="float", dest="elstep", default=50.0,
    help="step in elevation", metavar="ANGLE")
  parser.add_option("-v", "--verbose",
    action="store_true", dest="verbose", default=False,
    help="print status messages to stdout")

  (options, args) = parser.parse_args()
  if options.bank < 1 or options.bank > 3:
    print "bank " + str(options.bank) + ", should be [1|2|3]"
    sys.exit(1)

  if len(args) < 1:
    print "Not enough arguments!"
    parser.print_help()
    sys.exit(1)

  if(options.startf > options.stopf):
    print("start frequency should be lower than stop frequency!")
    sys.exit(1)

  antennas,antpols = antennapols.makeAntPolsStr(args[0])

  if len(antennas) < 1:
    print "no antennas found"
    sys.exit(1)

  antennasInUse = antennas
  signal.signal(signal.SIGINT,signal_handler)
  p = callProg(['fxconf.rb sagive none bfa ' + antennas])
  scanRFI(options,antennas)
  p = callProg(['fxconf.rb sagive bfa none ' + antennas])
