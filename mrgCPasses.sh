#!/bin/bash

#===============================================
function checkDir() 
{
    #create directory if needed
    if [ ! -d $1 ]; then
	echo Creating directory $1
	mkdir $1
    fi
}
#===============================================
#===============================================
function Usage() 
{
    #print usage
    echo Usage: "mrgCPasses.sh -p <period> -l <logbook_extract> [-r runMin] [-R runMax] [-f fillMin] [-F fillMax]"
    exit 1                                            
}

#===============================================
# main body
#
while [ $# -gt 0 ] ; do
    case $1 in
	-p) period=$2;  shift 2 ;;
	-l) logbook=$2; shift 2 ;;
	-r) runMin=$2;  shift 2 ;;
	-R) runMax=$2;  shift 2 ;;
	-f) fillMin=$2; shift 2 ;;
	-F) fillMax=$2; shift 2 ;;
    esac
done
#
if [ ! -n "$period" ] || [ ! -n "$logbook" ] ; then Usage; fi
#
sumFile="reportMergeNew${period}"
#
if [ -n "$runMin"  ] ;  then  sumFile="${sumFile}_rmn${runMin}"   ; else runMin=0;        fi
if [ -n "$runMax"  ] ;  then  sumFile="${sumFile}_rmx${runMax}"   ; else runMax=9999999;  fi
if [ -n "$fillMin" ] ;  then  sumFile="${sumFile}_fmn${fillMin}"  ; else fillMin=0;       fi
if [ -n "$fillMax" ] ;  then  sumFile="${sumFile}_fmnx${fillMax}" ; else fillMax=9999999; fi
#
sumFile="${sumFile}.txt"
if [ -e ${sumFile} ] ; then rm ${sumFile} ; fi
#
cvmfsPath="/cvmfs/alice-ocdb.cern.ch/calibration/data"
year="2016"

export CVMFS="$cvmfsPath"/"$year"/"OCDB"

# 
# output will go here
outDir0=qaCPass0${period}
outDir1=qaCPass1${period}
#
# create out.dirs if needed
checkDir $outDir0
checkDir $outDir1
#
# get run and fills list
gstr=`grep "$period" "$logbook" | cut -d';' -f1`
runs=(${gstr// / })
gstr=`grep "$period" "$logbook" | cut -d';' -f2`
fills=(${gstr// / })
nruns=${#runs[*]}
#
fillPrev=0
newFill=0
#
for (( i=0; i<${nruns}; i++ )); do
    run="${runs[$i]}"
    fill="${fills[$i]}"
#
    echo Doung "$fill" "(" "$fillMin" "$fillMax" ")" "$run" "(" "$runMin" "$runMax" ")"
#
    if [ "$fill" -lt "$fillMin" ] || [ "$fill" -gt "$fillMax" ] || [ "$run" -lt "$runMin" ] || [ "$run" -gt "$runMax" ] ; then  continue; fi
#
# do we start new fill?
    if [ "$fill" -ne "$fillPrev" ] ; then
	newFill=1
	fillPrev=$fill
    fi
#
# copy cpass0
  #  aliroot -b -q -l mergeSDD.C\($run,\"$outDir0\",\"/alice/data/${year}/${period}/%09d/cpass0_pass2/OCDB\",\"CalibObjects.root\"\)
  #  mfl0="${outDir0}/_alice_data_${year}_${period}_000${run}_cpass0_pass2_OCDB_CalibObjects.root"
    mfl0txt="${outDir0}/_alice_data_${year}_${period}_000${run}_cpass0_pass2_OCDB_CalibObjects.txt"
    mfl0st="-1;-1;-1;"
    if [ ! -e "$mfl0txt" ] ; then 
	mfl0=""
    else
	mfl0st=`cat ${mfl0txt}`
    fi
# copy cpass1
    aliroot -b -q -l mergeSDD.C\($run,\"$outDir1\",\"/alice/data/${year}/${period}/%09d/cpass1_pass2_sdd/OCDB\",\"CalibObjects.root\"\)
    mfl1="${outDir1}/_alice_data_${year}_${period}_000${run}_cpass1_pass2_sdd_OCDB_CalibObjects.root"
    mfl1txt="${outDir1}/_alice_data_${year}_${period}_000${run}_cpass1_pass2_sdd_OCDB_CalibObjects.txt"
    mfl1st="-1;-1;-1;"
    if [ ! -e "$mfl1" ] ; then
	mfl1=""
    else
	mfl1st=`cat ${mfl1txt}`
    fi
#
# check if there are data at least in one of passes
    if [ ! -n "$mfl0" ] && [ ! -n "$mfl1" ]; then continue; fi
#
# determine detectors status
    aliroot -b -q -l FetchDetStatus.C\(${run}\)
    detst=`cat _detStatus_${run}`
    if [ ! -n "$detst" ]; then 
	detst=";;;;"; 
    else
	rm _detStatus_${run}
    fi
# 
# write status string
    if [ "$newFill" -gt 0 ] ; then 
	echo "#" >> ${sumFile}
    fi
#
    echo "${run};${fill};${detst} ${mfl0st} ${mfl1st} ${mfl0}; ${mfl1};"  >> ${sumFile}
#
#    
#    if [ "$newFill" -gt 0 ] ; then 
#	aliroot -b -q -l GetCalib.C\(${run}\)
#    fi
#
#   reset newFill only after successful fetch of the file
    newFill=0
#
done
