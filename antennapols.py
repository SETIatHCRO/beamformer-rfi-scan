#python antenna pol translation module

import sys
import subprocess

def callProg(mystring):
  #print mystring
  p = subprocess.Popen(mystring, stdout=subprocess.PIPE, shell=True)
  p.wait()
  if(p.returncode):
    print "program " + mystring + " returned error"
    print p.stdout.read()
    sys.exit(1)

  return p


def getValidAntennaList():
  p = callProg(['fxconf.rb sals'])
  line = p.stdout.readline()
  while not line.startswith("none"):
    line = p.stdout.readline()
  validAntennas = line.split()
  validAntennas = validAntennas[1:] #first is none, skipping
  return validAntennas

def getAntName(apl):
  strname=''
  if len(apl) > 2:
    strname=apl[0:2]
  return strname

def isvalidname(antennalist, apl):
  if len(apl) < 4:
    print("antennapol: " + apl + " -- too short")
    return False
  pol = apl[2:]
  anum = apl[0:2]
  if not pol in ['x1','y1']:
    print("antennapol: " + apl + " -- bad polarization")
    return False
  if not anum in antennalist:
    print("antennapol: " + apl + " -- bad antenna name")
    return False
  return True

def getAllAntennas():
  validAntennas = getValidAntennaList()
  antpols = [];
  for ant in validAntennas:
    antpols.append(ant + "x1")
    antpols.append(ant + "y1")
  return validAntennas,antpols

def getAllAntennasStr():
  antennasList,antpolList = getAllAntennas()
  antstr = ",".join(antennasList);
  antpolstr = ",".join(antpolList);
  return antstr,antpolstr


def generateAntennasfromAntpolStr(antpolstr):
  antennasList,antpolList = generateAntennasfromAntpol(antpolstr)
  antstr = ",".join(antennasList);
  antpolstr = ",".join(antpolList);
  return antstr,antpolstr
  
def makeAntPolsStr(antennastr):
  antennasList,antpolList = makeAntPols(antennastr)
  antstr = ",".join(antennasList);
  antpolstr = ",".join(antpolList);
  return antstr,antpolstr


def makeAntPols(antennastr):
  validAntennas = getValidAntennaList()
  antennas = set()
  antpolsvalid = set()
  antennasL = antennastr.split(",")
  for ant in antennasL:
    apl1 = ant + "x1"
    apl2 = ant + "y1"
    if(isvalidname(validAntennas,apl1)):
      antennas.add(getAntName(apl1))
      antpolsvalid.add(apl1)
      antpolsvalid.add(apl2)
  return antennas,antpolsvalid


def generateAntennasfromAntpol(antpolstr):
  validAntennas = getValidAntennaList()
  antennas = set()
  antpolsvalid = set()
  antpols = antpolstr.split(",")
  for apl in antpols:
    if(isvalidname(validAntennas,apl)):
      antennas.add(getAntName(apl))
      antpolsvalid.add(apl)

  return antennas,antpolsvalid
