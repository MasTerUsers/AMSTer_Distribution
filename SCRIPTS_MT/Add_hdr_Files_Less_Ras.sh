#!/bin/bash
######################################################################################
# This script copy hdr files corresponding to u.bin, e.bin and linear rates files 
#      from msbas processing in the current directory. Unlike Add_hdr_Files.sh, it only 
#      computes here the rasters of the LINEAR RATE and its ERROR. It prepares a scripts 
#      to compute if needed the other rasters that it does not creates (for the sake of processing time)
#
# Parameters : - String PARAMNAME used to add to dir names where results will be strore. 
#                  This can help to remember eg some processing configs.
#
# Dependencies:	- A HDR.hdr file has to be present in the dir with the right parameters. 
#					This can be created by build_header_msbas_criterie.sh
#				- gsed and gawk
#
# New in Distro V 1.0:	- Based on developpement version 1.1 and Beta V1.3
#               V 1.1:  - bug fix in movin SBAS2 to LOS instead of EW
#                       - compliant for automatic time series
# New in Distro V 2.0:	- creater rasters when using (m)sbas V2 here instead of within MSBAS.sh script
# New in Distro V 2.1:	- remove former bin and hdr before copying the new ones because some may have been discarded if coh threshold was changed. 
#						- remove redirection toward file while moving MSBAS_ZSCORE_MASK.bin
# New in Distro V 2.2:	- take into account MSBAS results files name with word STD instead of ERROR i.e. for msbasv3 > Oct 2020
# New in Distro V 2.3:	- add path to cpxfiddle 
# New in Distro V 2.4:	- accounts for usage with msbasv4, i.e. that requires additional info in header files 
# New in Distro V 2.5:	- correct mv files from msbasv4, i.e. MSBAS_CON_NUM.bin and MSBAS_RANK.bin
# New in Distro V 2.6: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20240116:	- allows MSBAS 3D. Note that the inversion of the this third NS component only makes sense if/where the 
# 								displacement is expected to occur along the steepest slope of the topography (e.g. in 
# 								case of land slide). That is why it is sometimes referred as 3D SPF (Surface Parallel Flow)
#								- debug detection of MSBASV4 
# New in Distro V 3.2 20240129:	- move also some hdr file from newly created MSBAS bin files when compute NS comp. 
# New in Distro V 3.3 20240704:	- Stop if LOS and EW/UD .bin files are present in the main directory. 
#								  This is not supposed to happen, hence it must result from a crash. Manual sorting is advised. 
# New in Distro V 3.4 20240924:	- Debug creating pdf files for simple TS with error bar 
# New in Distro V 3.5 20240925:	- typo in line to mv MSBAS_*.txt to zz_${ALLCOMP}_TS${PARAMNAME}
#								- search for files in *_UD.bin instead of *UD.bin 
# New in Distro V 3.6 20241008:	- When processing 3D data, because it takes time to close listdir.tmp when performing  
#									ls *_EW.bin *_UD.bin > listdir.tmp and 
#								  do not ls *_NS.bin >> listdir.tmp just after or it will miss several files !!
#								  Instead, list the 3 comp in the listdir.tmp file at the same time 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.6 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 08, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

PARAMNAME=$1

# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : \n" > CommandLine_${PRG}.txt
index=1 
for arg in $*
do
  echo "$arg" >> CommandLine_${PRG}.txt
  let "index+=1"
done 

#countMSBASV3=`ls -1 MSBAS_ZSCORE_MASK.bin 2>/dev/null | wc -l`
countMSBASV2=`ls -1 *_EW.bin 2>/dev/null | wc -l` 			# v2 or above
countSBASV2=`ls -1 *_LOS.bin 2>/dev/null | wc -l`
countMSBASV1=`ls -1 *e.bin 2>/dev/null | wc -l`

if [ ${countMSBASV2} -gt 1 ] && [ ${countSBASV2} -gt 1 ]
	then 
		echo 
		echo 
		echo "WARNING: abnormal situation detected: "
		echo "  LOS and EW/UD .bin files are in pwd. This is not supposed to happen."
		echo "  Please check and sort these files manually (mv *LOS.bin in zz_LOS... and/or *EW.bin and *UD.bin in resp. zz_EW.. and zz_UD and/or clean the wrong files)"
		echo " => Stop here."
		echo 
		echo 
		exit
fi

if [ ${countMSBASV2} -gt 1 ]   	# v2 or above
	then 
		countMSBASV4=`ls -1 MSBAS_RANK.bin 2>/dev/null | wc -l` 	
		if [ ${countMSBASV4} -ge 1 ] 								# v4 or above
			then 
				lname="MSBASV4" 
				echo "You probably processed ${lname} or above"			
			else 
				lname="MSBASV2" 									# v2-3
				echo "You probably processed ${lname} or above"
		fi
fi
if [ ${countSBASV2} -gt 1 ] 		# v2 or above
	then 
		countSBASV4=`ls -1 MSBAS_RANK.bin 2>/dev/null | wc -l`
		if [ ${countSBASV4} -gt 1 ] 
			then 
				lname="SBASV4" 									 	# v4 or above
				echo "You probably processed ${lname} or above"			
			else 
				lname="SBASV2"  									# v2-3
				echo "You probably processed ${lname} or above"
		fi
fi 
if [ ${countMSBASV1} -gt 1 ] ; then lname="MSBASV1" ; echo "You probably processed ${lname}" ; fi


case ${lname} in 
 	MSBASV4)
		# Test if process 3D inversion 
		# do not add [] in line below 
		if ls MSBAS*_NS.bin 1> /dev/null 2>&1 
			then 
				ENU="YES" 
				ALLCOMP="UD_EW_NS"
			else 
				ENU="NO"
				ALLCOMP="UD_EW" 
		fi 

 		if [ "${ENU}" == "YES" ] 
 			then 
 				ls MSBAS*_EW.bin MSBAS*_UD.bin MSBAS*_NS.bin > listdir.tmp 
 			else
 				ls MSBAS*_EW.bin MSBAS*_UD.bin > listdir.tmp
 		fi
 		ls MSBAS_NORM_AXY.bin >> listdir.tmp
 		ls MSBAS_NORM_X.bin >> listdir.tmp	
 		ls MSBAS_COND_NUM.bin >> listdir.tmp
 		ls MSBAS_RANK.bin >> listdir.tmp
 		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then ls MSBAS_ZSCORE_MASK.bin >> listdir.tmp ; fi
 		mkdir -p zz_UD${PARAMNAME}
 		mkdir -p zz_EW${PARAMNAME} 
 		if [ "${ENU}" == "YES" ] ; then mkdir -p zz_NS${PARAMNAME} ; fi
		mkdir -p "zz_${ALLCOMP}_TS${PARAMNAME}" 
 		;;
	MSBASV2)
		ALLCOMP="UD_EW"
		ls MSBAS*_EW.bin MSBAS*_UD.bin > listdir.tmp
		ls MSBAS_NORM_AXY.bin >> listdir.tmp
		ls MSBAS_NORM_X.bin >> listdir.tmp	
		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then ls MSBAS_ZSCORE_MASK.bin >> listdir.tmp ; fi
		mkdir -p zz_UD${PARAMNAME}
		mkdir -p zz_EW${PARAMNAME} 
		mkdir -p "zz_${ALLCOMP}_TS${PARAMNAME}"
		;;
 	SBASV4)
 		ls MSBAS*_LOS.bin > listdir.tmp
 		ls MSBAS_NORM_AXY.bin >> listdir.tmp
 		ls MSBAS_NORM_X.bin >> listdir.tmp
 		ls MSBAS_COND_NUM.bin >> listdir.tmp
 		ls MSBAS_RANK.bin >> listdir.tmp
 		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then ls MSBAS_ZSCORE_MASK.bin >> listdir.tmp ; fi
 		mkdir -p zz_LOS${PARAMNAME} 
 		mkdir -p zz_LOS_TS${PARAMNAME} ;;
	SBASV2)
		ls *_LOS.bin > listdir.tmp
		ls MSBAS_NORM_AXY.bin >> listdir.tmp
		ls MSBAS_NORM_X.bin >> listdir.tmp
		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then ls MSBAS_ZSCORE_MASK.bin >> listdir.tmp ; fi
		mkdir -p zz_LOS${PARAMNAME} 
		mkdir -p zz_LOS_TS${PARAMNAME} ;;
	MSBASV1)
		ALLCOMP="e_u"
		ls *.bin > listdir.tmp
		mkdir -p zz_e${PARAMNAME}
		mkdir -p zz_u${PARAMNAME} 
		mkdir -p "zz_${ALLCOMP}_TS${PARAMNAME}"
		;;	
esac

for filename in `cat -s listdir.tmp`
   do
   # create hdr
   #cp HDR.hdr ${filename}.hdr
   
   # update description in hdr with file name 
   DESCRIPTION=`echo ${filename} | cut -d. -f1`
   # with awk, change everything between "{defo" and "pass}" with "{DESCRIPTION}" where DESCRIPTION is the basename of file
   ${PATHGNU}/gawk -v RS='{defo.*pass}' -v ORS= '1;NR==1{printf "{'${DESCRIPTION}'}"}' HDR.hdr > ${filename}.hdr 
done

case ${lname} in 
	MSBASV4|MSBASV2)
		# remove former bin and hdr. This is more secure if some dates must be discarded due to coh. threshold 
		rm -f zz_EW${PARAMNAME}/*_EW.bin*
		rm -f zz_UD${PARAMNAME}/*_UD.bin*
		# add new ones
		mv MSBAS*_EW.bin* zz_EW${PARAMNAME}/
		mv MSBAS*_UD.bin* zz_UD${PARAMNAME}/ 
		if [ "${ENU}" == "YES" ] ; then 
			rm -f zz_NS${PARAMNAME}/MSBAS*_NS.bin*
			mv MSBAS*_NS.bin* zz_NS${PARAMNAME}/
		fi

		echo "Move norms and log and dateTime file in EW${PARAMNAME}"	
		mv -f MSBAS_NORM_X.bin* zz_EW${PARAMNAME}/ 
		mv -f MSBAS_NORM_AXY.bin* zz_EW${PARAMNAME}/ 
		if [ -f MSBAS_COND_NUM.bin ] && [ -s MSBAS_COND_NUM.bin ] ; then mv -f MSBAS_COND_NUM.bin* zz_EW${PARAMNAME}/ ; fi
		if [ -f MSBAS_RANK.bin ] && [ -s MSBAS_RANK.bin ] ; then mv -f MSBAS_RANK.bin* zz_EW${PARAMNAME}/ ; fi
		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then mv MSBAS_ZSCORE_MASK.bin* zz_EW${PARAMNAME}/ ; fi
		mv -f MSBAS_TSOUT.txt zz_EW${PARAMNAME}/
		mv -f MSBAS_TIME_MATRIX.txt zz_EW${PARAMNAME}/

		cd zz_UD${PARAMNAME}
		ls *.hdr | ${PATHGNU}/grep -v "RATE" > ../datesTime.txt
		cd ..
		${PATHGNU}/gsed -i 's/UD.bin.hdr//g' datesTime.txt
		${PATHGNU}/gsed -i 's/MSBAS_//g' datesTime.txt
		mv datesTime.txt zz_UD${PARAMNAME}/
		cp header.txt zz_UD${PARAMNAME}/

		if [ `ls -1 MSBAS_*.txt 2>/dev/null | wc -l` -gt 1 ] ; then mv MSBAS_*.txt zz_${ALLCOMP}_TS${PARAMNAME}/ ; fi	
			
		# Create ratsers 
		if [ -d zz_EW${PARAMNAME} ] ; then 
			cp header.txt zz_EW${PARAMNAME}/
			cd zz_EW${PARAMNAME}
			WIDTH=`${PATHGNU}/grep Samples MSBAS_LINEAR_RATE_EW.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`

			# Make a script for creating rasters if needed.
			echo "ANYFILE=\$1" > _make_ras.sh
			echo "${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 \${ANYFILE} > \${ANYFILE}.ras" >> _make_ras.sh
 			# Make fig for linear velocity 
			${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_EW.bin > MSBAS_LINEAR_RATE_EW.bin.ras
			if [ -f MSBAS_LINEAR_RATE_ERROR_EW.bin ] && [ -s MSBAS_LINEAR_RATE_ERROR_EW.bin ] ; then 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_ERROR_EW.bin > MSBAS_LINEAR_RATE_ERROR_EW.bin.ras
				else 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_STD_EW.bin > MSBAS_LINEAR_RATE_STD_EW.bin.ras				
			fi
			# make kmz of linear rate
			Envi2ColorKmz.sh MSBAS_LINEAR_RATE_EW.bin
			cd ..
		fi

		# Create ratsers 
		if [ -d zz_NS${PARAMNAME} ] ; then 
			cp header.txt zz_NS${PARAMNAME}/
			cd zz_NS${PARAMNAME}
			WIDTH=`${PATHGNU}/grep Samples MSBAS_LINEAR_RATE_NS.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`

			# Make a script for creating rasters if needed.
			echo "ANYFILE=\$1" > _make_ras.sh
			echo "${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 \${ANYFILE} > \${ANYFILE}.ras" >> _make_ras.sh
 			# Make fig for linear velocity 
			${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_NS.bin > MSBAS_LINEAR_RATE_NS.bin.ras
			if [ -f MSBAS_LINEAR_RATE_ERROR_NS.bin ] && [ -s MSBAS_LINEAR_RATE_ERROR_NS.bin ] ; then 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_ERROR_NS.bin > MSBAS_LINEAR_RATE_ERROR_NS.bin.ras
				else 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_STD_NS.bin > MSBAS_LINEAR_RATE_STD_NS.bin.ras				
			fi
			# make kmz of linear rate
			Envi2ColorKmz.sh MSBAS_LINEAR_RATE_NS.bin
			cd ..
		fi

		if [ -d zz_UD${PARAMNAME} ] ; then 
			cd zz_UD${PARAMNAME}

			# Make a script for creating rasters if needed.
			echo "ANYFILE=\$1" > _make_ras.sh
			echo "${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 \${ANYFILE} > \${ANYFILE}.ras" >> _make_ras.sh
 			# Make fig for linear velocity 
			${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_UD.bin > MSBAS_LINEAR_RATE_UD.bin.ras
			if [ -f MSBAS_LINEAR_RATE_ERROR_UD.bin ] && [ -s MSBAS_LINEAR_RATE_ERROR_UD.bin ] ; then 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_ERROR_UD.bin > MSBAS_LINEAR_RATE_ERROR_UD.bin.ras
				else 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_STD_UD.bin > MSBAS_LINEAR_RATE_STD_UD.bin.ras				
			fi			
			# make kmz of linear rate
			Envi2ColorKmz.sh MSBAS_LINEAR_RATE_UD.bin
			cd ..
			#if [ `ls -1 zz_${ALLCOMP}_TS${PARAMNAME}/MSBAS_*.txt 2>/dev/null | wc -l` -gt 1 ] ; then 
			#	cd zz_${ALLCOMP}_TS${PARAMNAME} 
			if [ `ls -1 MSBAS_*.txt 2>/dev/null | wc -l` -gt 1 ] ; then 
				#cd zz_${ALLCOMP}_TS${PARAMNAME} 
				Plot_All_EW_UP_ts_inDir.sh
			fi
		fi	;;
	SBASV4|SBASV2)
		# remove former bin and hdr. This is more secure if some dates must be discarded due to coh. threshold 
		rm -f zz_LOS${PARAMNAME}/*_LOS.bin*
		# add new ones
		mv *_LOS.bin* zz_LOS${PARAMNAME}/ 
		mv MSBAS_NORM_X.bin* zz_LOS${PARAMNAME}/ 
		mv MSBAS_NORM_AXY.bin* zz_LOS${PARAMNAME}/ 
		#if [ -s MSBAS_ZSCORE_MASK.bin ] ; then mv MSBAS_ZSCORE_MASK.bin* zz_LOS${PARAMNAME}/  >> listdir.tmp ; fi
		if [ -f MSBAS_ZSCORE_MASK.bin ] && [ -s MSBAS_ZSCORE_MASK.bin ] ; then mv MSBAS_ZSCORE_MASK.bin* zz_LOS${PARAMNAME}/ ; fi
		mv -f MSBAS_TSOUT.txt zz_LOS${PARAMNAME}/
		mv -f MSBAS_TIME_MATRIX.txt zz_LOS${PARAMNAME}/
		#if [ ${lname} == "SBASV4" ] ; then  
		#	mv -f MSBAS_COND_NUM.bin zz_LOS${PARAMNAME}/ 
		#	mv -f MSBAS_RANK.bin zz_LOS${PARAMNAME}/ 
		#fi
		if [ -f MSBAS_COND_NUM.bin ] && [ -s MSBAS_COND_NUM.bin ] ; then mv -f MSBAS_COND_NUM.bin zz_LOS${PARAMNAME}/ ; fi
		if [ -f MSBAS_RANK.bin ] && [ -s MSBAS_RANK.bin ] ; then mv -f MSBAS_RANK.bin zz_LOS${PARAMNAME}/ ; fi
		
		#mv MSBAS_*.txt zz_EW${PARAMNAME}/
		cd zz_LOS${PARAMNAME}
		ls *.hdr | ${PATHGNU}/grep -v "RATE" > ../datesTime.txt
		cd ..
		${PATHGNU}/gsed -i 's/_LOS.bin.hdr//g' datesTime.txt
		${PATHGNU}/gsed -i 's/MSBAS_//g' datesTime.txt
		mv datesTime.txt zz_LOS${PARAMNAME}/
		cp header.txt zz_LOS${PARAMNAME}/
		#if [ `ls -1 *.ts 2>/dev/null | wc -l` -gt 1 ] ; then mv *.ts zz_LOS_TS${PARAMNAME}/ ; fi
		if [ `ls -1 MSBAS_*.txt 2>/dev/null | wc -l` -gt 1 ] ; then mv MSBAS_*.txt zz_LOS_TS${PARAMNAME}/ ; fi

		# Create rasters
		if [ -d zz_LOS${PARAMNAME} ] ; then 
			#cp header.txt zz_LOS${PARAMNAME}/
			cd zz_LOS${PARAMNAME}
			WIDTH=`${PATHGNU}/grep Samples MSBAS_LINEAR_RATE_LOS.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`

			# Make a script for creating rasters if needed.
			echo "ANYFILE=\$1" > _make_ras.sh
			echo "${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 \${ANYFILE} > \${ANYFILE}.ras" >> _make_ras.sh
 			# Make fig for linear velocity 
			${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_LOS.bin > MSBAS_LINEAR_RATE_LOS.bin.ras
			if [ -f MSBAS_LINEAR_RATE_ERROR_LOS.bin ] && [ -s MSBAS_LINEAR_RATE_ERROR_LOS.bin ] ; then 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_ERROR_LOS.bin > MSBAS_LINEAR_RATE_ERROR_LOS.bin.ras
				else 
					${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 MSBAS_LINEAR_RATE_STD_LOS.bin > MSBAS_LINEAR_RATE_STD_LOS.bin.ras				
			fi			
	
			# make kmz of linear rate
			Envi2ColorKmz.sh MSBAS_LINEAR_RATE_LOS.bin
			cd ..
			if [ `ls -1 zz_LOS_TS${PARAMNAME}/*.txt 2>/dev/null | wc -l` -gt 1 ] ; then 
				cd zz_LOS_TS${PARAMNAME} 
				Plot_All_LOS_ts_inDir.sh
			fi
		fi	;;
	MSBASV1)
		# remove former bin and hdr. This is more secure if some dates must be discarded due to coh. threshold 
		rm -f zz_e${PARAMNAME}/*e.bin*
		rm -f zz_u${PARAMNAME}//*u.bin*
		# add new ones
		mv *e.bin* zz_e${PARAMNAME}/
		mv linear_rate_east.bin* zz_e${PARAMNAME}/
		mv *u.bin* zz_u${PARAMNAME}/ 
		mv linear_rate_up.bin* zz_u${PARAMNAME}/
		echo "Move norms and log and dateTime file in zz_e${PARAMNAME}"	
		mv lambda_norms.txt zz_e${PARAMNAME}/
		mv *_norm.bin* zz_e${PARAMNAME}/
		cd zz_u${PARAMNAME}
		ls *.hdr > ../dates.txt
		cd ..
		${PATHGNU}/gsed -i 's/u.bin.hdr//g' dates.txt
		mv dates.txt zz_e${PARAMNAME}/
		cp header.txt zz_e${PARAMNAME}/
		if [ `ls -1 *.ts 2>/dev/null | wc -l` -gt 1 ] ; then mv *.ts zz_e_u_TS${PARAMNAME}/ ; fi
		;;
esac

rm listdir.tmp
#RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm%Ss" | ${PATHGNU}/gsed "s/ //g"`
#mv listdir.tmp listdir.tmp.${RUNDATE}.txt

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL HDR ADDED AND FILES MOVED- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


