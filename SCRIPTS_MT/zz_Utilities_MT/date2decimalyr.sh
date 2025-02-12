#!/bin/bash
# Transform first column of  YYYYMMDD into decimal year
#
# V1.0: Aug 16, 2018
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

FILE=$1

#PATHGNU1=/usr/local/bin
#PATHGNU2=/opt/local/bin

rm -f ${FILE}_decimaldate.txt

# read number of columns (separated by spaces)
#NCOL=`awk '{print NF}' ${FILE} | sort -nu | tail -n 1`
#echo " NCOL = $NCOL"

# while read yyyymmdd a b c d 
# do 
# 	echo ${yyyymmdd} 
# 	yyyy=`echo ${yyyymmdd} | cut -c  1-4`
# 	echo $yyyy
# 	mm=`echo ${yyyymmdd} | cut -c  5-6`
# 	echo $mm
# 	DD=`echo ${yyyymmdd} | cut -c  7-8`
# 	echo $DD
# 	leapm=`${PATHGNU1}/gdate --date="${yyyy}1231" +%j`
# 	datetemp=`${PATHGNU1}/gdate --date="${yyyy}${mm}${DD}" +%j`
# 	datedecimal=`echo ${datetemp} ${leapm} ${yyyy} | ${PATHGNU2}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
# 
# 	echo $datedecimal a b c d  >> ${FILE}_date.txt
# done < ${FILE}

# Change , with " " if needed

#${PATHGNU2}/gsed -i "s/ /,/g" ${FILE}
${PATHGNU}/gsed -i "s/ /,/g" ${FILE}


for LINES in `cat ${FILE}`
do 
	yyyymmdd=`echo ${LINES} | cut -c 1-8`
	yyyy=`echo ${yyyymmdd} | cut -c 1-4`
	mm=`echo ${yyyymmdd} | cut -c 5-6`
	DD=`echo ${yyyymmdd} | cut -c 7-8`
	#leapm=`${PATHGNU1}/gdate --date="${yyyy}1231" +%j`
	#datetemp=`${PATHGNU1}/gdate --date="${yyyy}${mm}${DD}" +%j`
	#datedecimal=`echo ${datetemp} ${leapm} ${yyyy} | ${PATHGNU2}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
	leapm=`${PATHGNU}/gdate --date="${yyyy}1231" +%j`
	datetemp=`${PATHGNU}/gdate --date="${yyyy}${mm}${DD}" +%j`
	datedecimal=`echo ${datetemp} ${leapm} ${yyyy} | ${PATHGNU}/gawk '{printf("%f",(($1-0.5)/$2) + $3);}'` 
	echo "$datedecimal ${LINES}" >> ${FILE}_decimaldate.txt

#${PATHGNU2}/gsed -i "s/,/ /g" ${FILE}_decimaldate.txt
${PATHGNU}/gsed -i "s/,/ /g" ${FILE}_decimaldate.txt

done 

