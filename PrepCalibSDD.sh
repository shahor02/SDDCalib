#!/bin/bash
set +o posix
# number of records per line in the report file
nRec=14
#declare -a runs
declare -a rec	
recSize=0
#
fill=0
nRunsFill=0
lastRunUsed=0
#
kRun=1
kFill=2
kTPC=3
kSPD=4
kSDD=5
kSSD=6
kNEv0=7
kNTr0=8
kNDet0=9
kNEv1=10
kNTr1=11
kNDet1=12
kNFl0=13
kNFl1=14

#-------------------------------------------------------------------
function Usage() {
#
    echo "Usage: PrepCalibSDD.sh -p <period>  -y <year> [-i inputFile] [-b runToBridge]"
    echo "period      : LHC12f ... etc"
    echo "inputFile   : output report of mrgCPasses.sh script, if not specified"
    echo "              then reportMerge<period>.txt will be used"
    echo "runToBridge : if needed, first object created will cover the range"
    echo "              starting from <runToBridge>+1"
    echo "year        : production year"
    exit
}

#-------------------------------------------------------------------
function GetRecInfo() {
#
  if [ $# -lt 1 ] ; then echo "GetRecInfo <record>" exit ; fi
#
  OLD_IFS=$IFS
  IFS=";"
  recSize=0
  if [[ $1 == "#"* ]] ; then return; fi  # this was a comment
  for word in $1; do rec[$((++recSize))]=$word ; done
  IFS=$OLD_IFS
}

#-------------------------------------------------------------------
function ProcessOldFill() {
#
  if [ $# -lt 1 ] ; then echo "ProcessOldFill <lines ...>" ; exit ; fi
#
  if [ ${nRunsFill} -lt 1 ] ; then return; fi
#  echo "First run of fill ${fill} is ${lRuns[1]} N= $# "
  ir=0
  nTrP0=0
  nTrP1=0  
  runMin=9999999
  runMax=0
  nTPCok0=0
  nITSok0=0
  nTPCok1=0
  nITSok1=0
  currFill=0
#
  nflmrg0=0
  nflmrg1=0
  mrgStr0=""
  mrgStr1=""
  runCmb0=""
  runCmb1=""
#
  for (( ir=1; ir<=${nRunsFill} ; ir++ )) ; do
      liner=${!ir}
#      echo "Run #${ir} : $liner"
      GetRecInfo "$liner"
      useCP0[$ir]=0
      useCP1[$ir]=0
      if [ ${runMin} -gt ${rec[$kRun]} ] ; then runMin=${rec[$kRun]} ; fi
      if [ ${runMax} -lt ${rec[$kRun]} ] ; then runMax=${rec[$kRun]} ; fi
      if [ $currFill -eq 0 ] && [ ${rec[$kFill]} -gt 0 ] ; then currFill=${rec[$kFill]} ; fi
#
      if [ "${rec[$kSDD]}" != "SDD1" ] ; then 
#	  echo "Discard run ${rec[$kRun]} w/o SDD" ; 
	  continue ; 
      fi
#
      if [ "${rec[$kNDet0]}" -gt 0  ] ; then 
	  ((nflmrg0=$nflmrg0+1))
	  ((nTrP0=$nTrP0+${rec[$kNTr0]}))
	  useCP0[$ir]=1
	  if [ "${rec[$kTPC]}" == "TPC1" ] ; then ((nTPCok0=$nTPCok0+1)) ; fi
	  if [ "${rec[$kSPD]}" == "SPD1" ] &&  [ "${rec[$kSSD]}" == "SSD1" ] ; then ((nITSok0=$nITSok0+1)) ; fi
	  mrgStr0="${mrgStr0}${rec[$kNFl0]} \\\\"\\n
	  echo "# r${rec[$kRun]}/f${rec[$kFill]} :  ${rec[$kTPC]}:${rec[$kSPD]}:${rec[$kSSD]} Ntr: ${rec[$kNTr0]}" >>  ${scrMrgFill0}
      fi	  
#
      if [ "${rec[$kNDet1]}" -gt 0  ] ; then 
	  ((nflmrg1=$nflmrg1+1))
	  ((nTrP1=$nTrP1+${rec[$kNTr1]}))
	  useCP1[$ir]=1
	  if [ "${rec[$kTPC]}" == "TPC1" ] ; then ((nTPCok1=$nTPCok1+1)) ; fi
	  if [ "${rec[$kSPD]}" == "SPD1" ] &&  [ "${rec[$kSSD]}" == "SSD1" ] ; then ((nITSok1=$nITSok1+1)) ; fi
	  mrgStr1="${mrgStr1}${rec[$kNFl1]} \\\\"\\n
	  echo "# r${rec[$kRun]}/f${rec[$kFill]} :  ${rec[$kTPC]}:${rec[$kSPD]}:${rec[$kSSD]} Ntr: ${rec[$kNTr1]}" >>  ${scrMrgFill1}
      fi	  
#
  done
#
#  echo "TPCOK: ${nTPC1} ITSOK: ${nITS1} out of ${nRunsFill} runs, Stat: ${nTrP0} ${nTrP1}"
#
  echo "rmin: $runMin rmax: $runMax $lastRunUsed"
  if [ $nflmrg0 -eq 0 ] && [ $nflmrg1 -eq 0 ] ; then return ; fi
  if [ $lastRunUsed -gt 0 ] && [ $lastRunUsed -lt $runMin ] ; then ((runMin=$lastRunUsed+1)) ; fi
  lastRunUsed=$runMax
#

  echo "# fill ${currFill}: total ${nTrP0} tracks in ${nflmrg0} runs, tpcOK in ${nTPCok0} itsOK in ${nITSok0}" >> ${scrMrgFill0}
  echo "# fill ${currFill}: total ${nTrP1} tracks in ${nflmrg1} runs, tpcOK in ${nTPCok1} itsOK in ${nITSok1}" >> ${scrMrgFill1}

# create merging, calib scripts lines
  if [ $nflmrg0 -gt 0 ] ; then
      echo "hadd -f qaCPass0mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root \\" >> ${scrMrgFill0}
      echo -e $mrgStr0 >> ${scrMrgFill0}
      echo -e "${runMin} ${runMax} ${runMax} \"qaCPass0mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root\" \"\" \\" >> ${scrCalFill0}
  fi
#
  if [ $nflmrg1 -gt 0 ] ; then
      echo "hadd -f qaCPass1mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root \\" >> ${scrMrgFill1}
      echo -e $mrgStr1 >> ${scrMrgFill1}
      echo -e "${runMin} ${runMax} ${runMax} \"qaCPass1mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root\" \"\" \\" >> ${scrCalFill1}
  fi
#
  echo -e "#\n" >> ${scrMrgFill0}
  if [ $nflmrg0 -gt 0 ] ; then
      echo "aliroot -b -q RemoveSlope.C\\(\\\"qaCPass0mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root\\\"\\)" >> ${scrMrgFill0}
      echo -e "#---------------\n\n\n" >> ${scrMrgFill0}
  fi
#
  echo -e "#\n" >> ${scrMrgFill1}
  if [ $nflmrg1 -gt 0 ] ; then
      echo "aliroot -b -q RemoveSlope.C\\(\\\"qaCPass1mrgFill_${period}/qa_fill${currFill}_${runMin}_${runMax}.root\\\"\\)" >> ${scrMrgFill1}
      echo -e "#---------------\n\n\n" >> ${scrMrgFill1}
  fi
#

#
}
#-------------------------------------------------------------------
#-------------------------------------------------------------------
#-------------------------------------------------------------------
#
while [ $# -gt 0 ] ; do
    case $1 in
        -p) period=$2;  shift 2 ;;
        -i) inpFile=$2; shift 2 ;;
        -b) lastRunUsed=$2;  shift 2 ;;
        -y) year=$2; shift 2 ;;
    esac
done

if [ -z "$period"  ] ; then Usage ; fi
if [ -z "$inpFile" ] ; then
    if [ -e "reportMerge${period}.txt" ] ; then inpFile=reportMerge${period}.txt ; fi
fi
#
if [ -z "$inpFile" ] ; then Usage ; fi
if [ -n "$lastRunUsed" ] ; then echo "Will bridge period $period to run $lastRunUsed" ; fi
#
if [ -z "$year"  ] ; then Usage ; fi

cvmfsPath="/cvmfs/alice-ocdb.cern.ch/calibration/data"
export year
export CVMFS="$cvmfsPath"/"$year"/"OCDB"



scrMrgFill0="mrgFillCP0_${period}.sh"
scrMrgFill1="mrgFillCP1_${period}.sh"
scrCalFill0="CalibFillCP0_${period}.sh"
scrCalFill1="CalibFillCP1_${period}.sh"

if [ -e ${scrMrgFill0} ] ; then rm ${scrMrgFill0} ; fi
if [ -e ${scrMrgFill1} ] ; then rm ${scrMrgFill1} ; fi
if [ -e ${scrCalFill0} ] ; then rm ${scrCalFill0} ; fi
if [ -e ${scrCalFill1} ] ; then rm ${scrCalFill1} ; fi
echo -e "#!/bin/bash\n" > ${scrMrgFill0}
echo -e "#!/bin/bash\n" > ${scrMrgFill1}
echo -e "#!/bin/bash\n#\nrangeArr=(\\" > ${scrCalFill0}
echo -e "#!/bin/bash\n#\nrangeArr=(\\" > ${scrCalFill1}

echo -e "mkdir qaCPass0mrgFill_${period}" > ${scrMrgFill0}
echo -e "mkdir qaCPass1mrgFill_${period}" > ${scrMrgFill1}

chmod +x ${scrMrgFill0} ${scrMrgFill1} ${scrCalFill0} ${scrCalFill1}

while read  line
do
#
    GetRecInfo "$line"
    if [ $recSize -lt $nRec ] ; then continue; fi
#    echo Line is: ${recSize} "|"$line"|"
    #
    if [ "${fill}" -ne "${rec[$kFill]}" ] ; then 
	fill=${rec[$kFill]}
	echo "Starting new fill ${fill}"
	if [ "$nRunsFill" -gt 0 ] ; then ProcessOldFill "${runs[@]}" ; fi
	nRunsFill=0
	unset runs
    fi
#
    runs[((++nRunsFill))]="$line"

#    echo "Size: $sz Run: ${rec[1]} Rec: ${rec[*]}"
done < <( cat "$inpFile" )
 
#echo "end $nRunsFill size: ${#runs[@]}"
#echo "${runs[@]}"
# if needed process lasst fill
if [ "$nRunsFill" -gt 0 ] ; then ProcessOldFill "${runs[@]}" ; fi

echo -e ")" >> ${scrCalFill0}
echo -e ")" >> ${scrCalFill1}

echo -e "#\n" >> ${scrMrgFill0}
echo -e "#\n" >> ${scrMrgFill1}

echo -e "hadd -f qaCPass0mrgFill_${period}/qa_${period}_NoSlp.root qaCPass0mrgFill_${period}/qa_fill*NoSlp.root" >> ${scrMrgFill0}
echo -e "hadd -f qaCPass1mrgFill_${period}/qa_${period}_NoSlp.root qaCPass1mrgFill_${period}/qa_fill*NoSlp.root" >> ${scrMrgFill1}

#--------------------------------------------------------
echo -e "export CVMFS=${CVMFS}" >> ${scrCalFill0}
echo -e "period=${period}" >> ${scrCalFill0}
echo \
'((nobj=${#rangeArr[@]}/5))
#
# edit these initial and imposed objects
respIni="auto"
mapIni="auto"
vdIni="auto"
dedx="CorrectiondEdxSDD_244917.245068_OCDB.root"
respForce="auto"
rgloMn=${rangeArr[((0*5+0))]}
rgloMx=${rangeArr[((${nobj}*5+1-5))]}
mapForce="ITS_map${period}/Calib/MapsTimeSDD/Run${rgloMn}_${rgloMx}_v0_s0.root"

#prepare map for the period
if [ -d "ITS_map${period}" ]; then rm -r "ITS_map${period}" ; fi
if [ -d "ITS_${period}" ]; then rm -r "ITS_${period}" ; fi
if [ -d ITS ]; then rm -r ITS ; fi

inp="qaCPass0mrgFill_${period}/qa_${period}_NoSlp.root"
rauto=${rangeArr[2]}
aliroot -b -q CalibrateSDD.C+\(\"${inp}\",${rgloMn},${rgloMx},${rauto},\"${respIni}\",\"${vdIni}\",\"${mapIni}\",\"${dedx}\",\"${respForce}\",\"\"\)
mv ITS "ITS_map${period}"

for (( i=0; i<${nobj} ; i++ )) ; do
    rmin=${rangeArr[(($i*5+0))]}
    rmax=${rangeArr[(($i*5+1))]}
    rauto=${rangeArr[(($i*5+2))]}
    inp=${rangeArr[(($i*5+3))]}
    dedxuse=${rangeArr[(($i*5+4))]}
    [[ -z ${dedxuse} ]] && dedxuse=${dedx}
    aliroot -b -q CalibrateSDD.C+\(\"${inp}\",${rmin},${rmax},${rauto},\"${respIni}\",\"${vdIni}\",\"${mapIni}\",\"${dedxuse}\",\"${respForce}\",\"${mapForce}\"\)

done
mv ITS "ITS_${period}"
' >> ${scrCalFill0}


#--------------------------------------------------------
echo -e "export CVMFS=${CVMFS}" >> ${scrCalFill1}
echo -e "period=${period}" >> ${scrCalFill1}

echo \
'((nobj=${#rangeArr[@]}/5))
#
# edit these initial and imposed objects
respIni="auto"
mapIni="auto"
vdIni="auto"
dedx="CorrectiondEdxSDD_244917.245068_OCDB.root"
respForce="auto"
rgloMn=${rangeArr[((0*5+0))]}
rgloMx=${rangeArr[((${nobj}*5+1-5))]}
mapForce="ITS_map${period}/Calib/MapsTimeSDD/Run${rgloMn}_${rgloMx}_v0_s0.root"

#prepare map for the period
if [ -d "ITS_map${period}" ]; then rm -r "ITS_map${period}" ; fi
if [ -d ITS ]; then rm -r ITS ; fi

inp="qaCPass1mrgFill_${period}/qa_${period}_NoSlp.root"
rauto=${rangeArr[2]}
aliroot -b -q CalibrateSDD.C+\(\"${inp}\",${rgloMn},${rgloMx},${rauto},\"${respIni}\",\"${vdIni}\",\"${mapIni}\",\"${dedx}\",\"${respForce}\",\"\"\)
mv ITS "ITS_map${period}"

for (( i=0; i<${nobj} ; i++ )) ; do
    rmin=${rangeArr[(($i*5+0))]}
    rmax=${rangeArr[(($i*5+1))]}
    rauto=${rangeArr[(($i*5+2))]}
    inp=${rangeArr[(($i*5+3))]}
    dedxuse=${rangeArr[(($i*5+4))]}
    [[ -z ${dedxuse} ]] && dedxuse=${dedx}
    aliroot -b -q CalibrateSDD.C+\(\"${inp}\",${rmin},${rmax},${rauto},\"${respIni}\",\"${vdIni}\",\"${mapIni}\",\"${dedxuse}\",\"${respForce}\",\"${mapForce}\"\)

done
' >> ${scrCalFill1}

echo "Please check/edit the following generated scripts:"
echo "1) ${scrMrgFill1} : script to merge per fill runs of $period"
echo "created per-fill files with slopes removed and to merge them"
echo ""
echo "2) ${scrCalFill1} : script to run calibration macro over slope-removed"
echo "data for the whole period, to create the non-uniformity map"
echo "and then to run per-fill calibration"
echo "Note: if some fill have no data in CPass1, check if CPass0 scrits "
echo "${scrMrgFill0} and ${scrCalFill0} have needed data"
