#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at starting a new AMSTerEngine processing for every sat data
# It was fully refurbished to work with similar naming as what is present in the 
#     InSARParameters.txt files etc... and adapted to the new processing chain 
#     making use of data already read in csl format using script Read_All_Img.sh
#
# THIS PROCESSING DO NOT INCLUDE UNWRAPPING AND GEOCODING ON PURPOSE, AND ADD LABEL TO AMPL FIG
#
# Parameters : - PRM date
#              - SCD date
#              - PRAMETERS file, incl path (e.g. ___V20190710_LaunchMTparam.txt)
#              - COMMENT to be added at the end of dir name where the process is run. 
#                  Optional unless you want process the pair on a Global Primary (SuperMaster). 
#                  See next parameter. 
#              - SUPERMASTER date : if need coregistration on a Global Primary (SuperMaster), a 5th parameter 
#                  with its date is mandatory. A 4th paramerter is then aslo mandatory. 
#                  It is recommended to use a 4th parameter that includes the date of the 
#                  Global Primary (SuperMaster). Someting such as _SMyyyyMMdd would be intuitive. 
#
#                  If used for creating amplitude images (e.g for shadow monitoring)
#				   there is no need to use a Global Primary (SuperMaster). The 5th param can be set to NOSM 
#				   (actually it is forced to NOSM when use with 7 param).
#              - LABELX and LABELY: position of date label in amplitude jpg images.  
#
# Hard coded:	- MAXSIGMARGAZ = Maximum value of Sigma (in Range and Azimuth) admitted for successful Fine Coregistration. 
#                            If Sigma is larger, it attemps to restart a fine coreg with larger win size
#				- Crop function (cutAndZoom with option -e that is without considering latitude and hence poor accurate position. )
#
# Dependencies:
#	 - AMSTerEngine and AMSTerEngine Tools, at least V20190716
#	 - PRAMETERS file, at least V 20190710
#    - The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#    - gnu sed and awk for more compatibility. 
#    - cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#            http://doris.tudelft.nl/Doris_download.html. 
#    - Fiji (from ImageJ) is usefull as well though not mandatory
#    - Python 
#	 - scripts:	FLIPproducts.py.sh 
#				FLOPproducts.py.sh
#    - convert (to create jpg images from sun rasters)
#    - bc (for basic computations in scripts)
#    - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#	 - linux trap function
#	 - __HardCodedLines.sh for the definition of date cell 
#
# New in Distro V 1.0:	- Based on developpement version 14.11 and Beta V3.2.0
# New in Distro V 1.1:	- Offers possibility to calibrate amplitiude images
# New in Distro V 2.3:	- Update to cope with SinglPair.sh V_D2.3.0
# New in Distro V 2.4:	- allows mapping of zones unwrapped with snaphu
# New in Distro V 2.5:	- When using S1, creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
#							  that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms.
#							  Note that the script will remove that file at normal termination or CTRL-C, but not if script is terminated using kill. In such a case, you need to remove the file manaully 
# New in Distro V 2.5.1:	- check if images are already coregistered on SuperMaster based on NAME instead of date to be compliant with S1 Strip Map 
# New in Distro V 2.5.2:	- small stuffs about S1 sigma nought calib. 
# New in Distro V 2.6.0:	- If request coreg on super master to gain time, take the SM that is provided in LaunchParam.txt if it exists. If not, it ask among those existing ones. 
# New in Distro V 2.7.0:	- allows processing S1 WS data with zoom !=1. Must have param CROP set as CropYes and set the crop limits in pixels 
# New in Distro V 2.8.0:	- Do not consider squared zoom as it increases the size of the products unnecessarily 
# New in Distro V 2.9.0:	- Allows defining forced geocoded are with a kml using the GEOCKML parameter to be read from the LaunchParam.txt 
# New in Distro V 2.9.1:	- typo in defninition of CROPDIR in S1 WideSwath; shouldn't have been a problem though
# New in Distro V 3.0.0:	- update all points above from 2.5.1 till 3.0.0 as from SinglePair.sh
#							- correct bug that preventend zooming when data where already read with zoom=1 (was only zooming at geocoding)
#							- make ampli img S1 figures (ras and jpg) square
#							- stop processing if Zoom is requested for S1 Wide Swath without a crop or with a crop defined by kml. MUST be CROPyes and crop given in corners coordinates
#							- check coordinate system used to feed crop zone at S1 WideSwath Crop if Zoom is requested. 
# New in Distro V 3.0.1:	- evaluate MASPOL and SLVPOL after InSARprocessing whatever the type of processing in order to be sure of proper renaming of InSARProducts after completion
# New in Distro V 3.1.0:	- Keep track of MasTer Engine version in log by looking at MasTer Engine source dir 
# New in Distro V 3.1.1:	- Compute amplitude raster with ML 4/1 if S1 WideSwath, and 1/1 if S1 SM
# New in Distro V 3.2.0:	- Crop considering average altitude =0 to be consistent with old time series of ampli images
# New in Distro V 3.2.1:	- remind the hard coded lines 
# New in Distro V 4.0: 		- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 4.1: 		- read UTM zone for geocoding
# New in Distro V 5.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 6.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 6.1 20231123:	- Allows naming Radarsat2 as RS in workflow
# New in Distro V 6.2 20240228:	- Fix rounding pix size when smaller than one by allowing scale 2 before division. Now pix size in real insated of integer 
# New in Distro V 7.0 20241015:	- multi level mask 
# New in Distro V 7.1 20241202:	- debug PATHTOMASK
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V7.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Dec 02, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# source $HOME/.bashrc
 
MASINPUT=$1					# date or S1 name of Primary (for S1 : it could be either in the form of yyyymmdd or S1a/b_sat_trk_a/d)
SLVINPUT=$2					# date or S1 name of Secondary (for S1 : it could be either in the form of yyyymmdd or S1a/b_sat_trk_a/d)
PARAMFILE=$3				# File with the parameters needed for the run
COMMENT=$4					# Comment for naming dir where process is run
SUPMASINPUT=$5	
LABELX=$6					# position of the date label in jpg fig of mod
LABELY=$7					# position of the date label in jpg fig of mod

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# - SinglePairNoUnwrapDATECELL to define the type of Cell where the date is print on the plots

MAXSIGMARGAZ=5   # Maximum value of Sigma (in Range and Azimuth) admitted for successful Fine Coregistration. 

# Crop function for non S1 IW : CropAtZeroAlt or Crop (cfr FUNCTIONS_FOR_MT.sh)
# CropAtZeroAlt fct performd cutAndZoom with option -e that is without considering latitude and hence poor accurate position. 
#				This is however the default option before June 2022. Take this if you need to keep crop region consistency with former processing. 
# Crop fct can now adjust the crop based on the mean altitude and corners are more accurate. It requires however a DEM. 
CROPFCT=CropAtZeroAlt		 
#CROPFCT=Crop
# ^^^ ----- Hard coded lines to check --- ^^^ 

if [ $# -lt 3 ] ; then echo " Usage: $0 MAS SLV PARAMETER_FILE _COMMENT(optional) SUPERMASTER(optional) [position of the jpg date label in X and Y]"; exit; fi

if [ $# -eq 7 ] ; then echo " You wanted to change the position of the date label in jpg fig."; SUPERMASTER="NOSM"; fi  # force 5th param to be NOSM


# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the Global Primary (SuperMaster) as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/seti/setParametersFile.txt

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 
FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

DEMDIR=`GetParam DEMDIR`					# DEMDIR, path to dir where DEM is stored
RECOMPDEM=`GetParam "RECOMPDEM,"`			# RECOMPDEM, recompute DEM even if already there (FORCE), or trust the one that would exist (KEEP)
SIMAMP=`GetParam "SIMAMP,"`					# SIMAMP, (SIMAMPno or SIMAMPyes). Option to compute simulated amplitude during Extenral DEM generation - usually not needed.

POP=`GetParam "POP,"`						# POP, option to pop up figs or not (POPno or POPyes)
FIG=`GetParam "FIG,"`						# FIG, option to compute or not the quick look using cpxfiddle (FIGno or FIGyes)

SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)

CROP=`GetParam "CROP,"`						# CROP, CROPyes or CROPno 
FIRSTL=`GetParam "FIRSTL,"`					# Crop limits: first line to use
LASTL=`GetParam "LASTL,"`					# Crop limits: last line to use
FIRSTP=`GetParam "FIRSTP,"`					# Crop limits: first point (row) to use
LASTP=`GetParam "LASTP,"`					# Crop limits: last point (row) to use

MLAMPLI=`GetParam "MLAMPLI,"`				# MLAMPLI, Multilooking factor for amplitude images reduction (used for coregistration - 4-6 is appropriate). If rectangular pixel, it will be multiplied by corresponding ratio.
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
PIXSHAPE=`GetParam "PIXSHAPE,"`				# PIXSHAPE, pix shape for products : SQUARE or ORIGINALFORM   
CALIBSIGMA=`GetParam "CALIBSIGMA,"`			# CALIBSIGMA, if SIGMAYES it will output sigma nought calibrated amplitude file at the insar product generation step  

COH=`GetParam "COH,"`						# Coarse coregistration correlation threshold  
CCOHWIN=`GetParam "CCOHWIN,"`     			# CCOHWIN, Coarse coreg window size (64 by default but may want less for very small crop)
CCDISTANCHOR=`GetParam "CCDISTANCHOR,"`		# CCDISTANCHOR, Coarse registration range & az distance between anchor points [pix]

FCOH=`GetParam "FCOH,"`						# Fine coregistration correlation threshold 
FCOHWIN=`GetParam "FCOHWIN,"`				# FCOHWIN, Fine coregistration window size (size in az or rg is computed based on Az/Rg ratio) 
FCDISTANCHOR=`GetParam "FCDISTANCHOR,"`		# FCDISTANCHOR, Fine registration range & az distance between anchor points [pix]

PROCESSMODE=`GetParam "PROCESSMODE,"`		# PROCESSMODE, DEFO to produce DInSAR or TOPO to produce DEM
		
INITPOL=`GetParam "INITPOL,"`		        # INITPOL, force polarisation at initInSAR for InSAR processing. If it does not exists it will find the first compatible MAS-SLV pol. 
LLRGCO=`GetParam "LLRGCO,"`					# LLRGCO, Lower Left Range coord offset for final interferometric products generation. Used mainly for Shadow measurements
LLAZCO=`GetParam "LLAZCO,"`					# LLAZCO, Lower Left Azimuth coord offset for final interferometric products generation. Used mainly for Shadow measurements
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
COHESTIMFACT=`GetParam "COHESTIMFACT,"`		# COHESTIMFACT, Coherence estimator window size
FILTFACTOR=`GetParam "FILTFACTOR,"`			# Range and Az filtering factor for interfero
POWSPECSMOOTFACT=`GetParam "POWSPECSMOOTFACT,"`	# POWSPECSMOOTFACT, Power spectrum filtering factor (for adaptative filtering)

APPLYMASK=`GetParam "APPLYMASK,"`			# APPLYMASK, Apply mask before unwrapping (APPLYMASKyes or APPLYMASKno)
if [ ${APPLYMASK} == "APPLYMASKyes" ] 
 then 
	PATHTOMASK=`GetParam "PATHTOMASK,"`			# PATHTOMASK, geocoded mask file name and path
	if [ "${PATHTOMASK}" != "" ]
		then 
			# old Version of LaunchParamFiles.txt, i.e. =< 20231026
			MASKBASENAME=`basename ${PATHTOMASK##*/}`  
		else 
			# Version of LaunchParamFiles.txt, i.e. >= 202341015
			PATHTOMASKGEOC=`GetParam "PATHTOMASKGEOC,"`			# PATHTOMASKGEOC, geocoded "Geographical mask" file name and path (water body etc..)
			DATAMASKGEOC=`GetParam "DATAMASKGEOC,"`				# DATAMASKGEOC, value for masking in PATHTOMASKGEOC

			PATHTOMASKCOH=`GetParam "PATHTOMASKCOH,"`			# PATHTOMASKCOH, geocoded "Thresholded coherence mask" file name and path (mask at unwrapping below threshold)
			DATAMASKCOH=`GetParam "DATAMASKCOH,"`				# DATAMASKCOH, value for masking in PATHTOMASKCOH

			PATHTODIREVENTSMASKS=`GetParam "PATHTODIREVENTSMASKS,"` # PATHTODIREVENTSMASKS, path to dir that contains event mask(s) named eventMaskYYYYMMDDThhmmss_YYYYMMDDThhmmss(.hdr) for masking at Detrend with all masks having dates in Primary-Secondary range of dates
			DATAMASKEVENTS=`GetParam "DATAMASKEVENTS,"`			# DATAMASKEVENTS, value for masking in PATHTODIREVENTSMASKS 

			if [ "${PATHTOMASKGEOC}" != "" ] ; then MASKBASENAMEGEOC=`basename ${PATHTOMASKGEOC##*/}` ; else MASKBASENAMEGEOC=NoGeogMask  ; fi
			if [ "${PATHTOMASKCOH}" != "" ] ; then MASKBASENAMECOH=`basename ${PATHTOMASKCOH##*/}` ; else MASKBASENAMECOH=NoCohMask  ; fi
			if [ "${PATHTODIREVENTSMASKS}" != "" ] 
				then 
				    if [ "$(find "${PATHTODIREVENTSMASKS}" -type f | head -n 1)" ]
				    	then 
				    		MASKBASENAMEDETREND=`basename ${PATHTODIREVENTSMASKS}` 
				    		MASKBASENAMEDETREND=Detrend${MASKBASENAMEDETREND}
				    	else 
				    		echo "${PATHTODIREVENTSMASKS} exist though is empty, hence apply no Detrend mask " 
				    		MASKBASENAMEDETREND=NoAllDetrend
				    fi
				else 
					MASKBASENAMEDETREND=NoAllDetrend
			fi

			MASKBASENAME=${MASKBASENAMEGEOC}_${MASKBASENAMECOH}_${MASKBASENAMEDETREND}

	fi
 else 
  PATHTOMASK=`echo "NoMask"`
  MASKBASENAME=`echo "NoMask"` 
fi

SKIPUW=`GetParam "SKIPUW,"`					# SKIPUW, SKIPyes skips unwrapping and geocode all available products

CONNEXION_MODE=`GetParam "CONNEXION_MODE,"`	# CONNEXION_MODE, number of times that connexion search radius is augmented when stable connections are found ; 0 search along all coh zone  
BIASCOHESTIM=`GetParam "BIASCOHESTIM,"`		# BIASCOHESTIM, Biased coherence estimator range & Az window size (do not appli pix rratio) 
BIASCOHSPIR=`GetParam "BIASCOHSPIR,"`		# BIASCOHSPIR, Biased coherence square spiral size (if residual fringes are not unwrapped decrease it; must be odd)  
COHCLNTHRESH=`GetParam "COHCLNTHRESH,"`		# COHCLNTHRESH, Coherence cleaning threshold - used for mask
FALSERESCOHTHR=`GetParam "FALSERESCOHTHR,"`	# FALSERESCOHTHR, False Residue Coherence Threshold: higher is much slower. Use max 0.15 e.g. in crater 
UW_METHOD=`GetParam "UW_METHOD,"`			# UW_METHOD, Select phase unwrapping method (SNAPHU, CIS or DETPHUN)
DEFOTHRESHFACTOR=`GetParam "DEFOTHRESHFACTOR,"`	# DEFOTHRESHFACTOR, Snaphu : Factor applied to rho0 to get threshold for whether or not phase discontinuity is possible. rho0 is the expected, biased correlation measure if true correlation is 0. Increase if not good. 
DEFOCONST=`GetParam "DEFOCONST,"`				# DEFOCONST, Snaphu : Ratio of phase discontinuity probability density to peak probability density expected for discontinuity-possible pixel differences. Value of 1 means zero cost for discontinuity, 0 means infinite cost. Decrease if prblm. 
DEFOMAX_CYCLE=`GetParam "DEFOMAX_CYCLE,"`		# DEFOMAX_CYCLE, Snaphu : Max nr of expected phase cycle discontinuity. For topo where no phase jump is expected, it can be set to zero. 
SNAPHUMODE=`GetParam "SNAPHUMODE,"`				# SNAPHUMODE, Snaphu : TOPO, DEFO, SMOOTH, or NOSTATCOSTS. 
DETITERR=`GetParam "DETITERR,"`				# DETITERR, detPhUn : Number of iterration for detPhUn (Integer: 1, 2 or 3 is generaly OK)
DETCOHTHRESH=`GetParam "DETCOHTHRESH,"`		# DETCOHTHRESH, Coherence threshold
ZONEMAP=`GetParam "ZONEMAP"` 				# ZONEMAP, if ZoneMapYes, it will create a map with the unwrapped zones named snaphuZoneMap. Each continuously unwrapped zone is numbered (from 1 to...)
ZONEMAPSIZE=`GetParam "ZONEMAPSIZE"` 		# ZONEMAPSIZE, Minimum size of unwrapped zone to map (in frazction of total nr of pixels)
ZONEMAPCOST=`GetParam "ZONEMAPCOST"` 		# ZONEMAPCOST, Cost threshold for connected components (zones). Higher threshold will give smaller connected zones
ZONEMAPTOTAL=`GetParam "ZONEMAPTOTAL"` 		# ZONEMAPTOTAL, Maximum number of mapped zones	

INTERPOL=`GetParam "INTERPOL,"`				# INTERPOL, interpolate the unwrapped interfero BEFORE or AFTER geocoding or BOTH. 	
REMOVEPLANE=`GetParam "REMOVEPLANE,"`		# REMOVEPLANE, if DETREND it will remove a best plane after unwrapping. Anything else will ignore the detrending. 	

PROJ=`GetParam "PROJ,"`						# PROJ, Chosen projection (UTM or GEOC)
GEOCMETHD=`GetParam "GEOCMETHD,"`			# GEOCMETHD, Resampling Size of Geocoded product: Forced (at FORCEGEOPIXSIZE - convenient for further MSBAS), Auto (closest multiple of 10), Closest (closest to ML az sampling)
RADIUSMETHD=`GetParam "RADIUSMETHD,"`		# LetCIS (CIS will compute best radius) or forced to a given radius 
RESAMPMETHD=`GetParam "RESAMPMETHD,"`		# TRI = Triangulation; AV = weighted average; NN = nearest neighbour 
WEIGHTMETHD=`GetParam "WEIGHTMETHD,"`		# Weighting method : ID = inverse distance; LORENTZ = lorentzian 
IDSMOOTH=`GetParam "IDSMOOTH,"`				# ID smoothing factor  
IDWEIGHT=`GetParam "IDWEIGHT,"`				# ID weighting exponent 
FWHM=`GetParam "FWHM,"`						# Lorentzian Full Width at Half Maximum
ZONEINDEX=`GetParam "ZONEINDEX,"`			# Zone index  
FORCEGEOPIXSIZE=`GetParam "FORCEGEOPIXSIZE,"` # Pixel size (in m) wanted for your final products. Required for MSBAS

UTMZONE=`GetParam "UTMZONE,"`				# UTMZONE, letter of row and nr of col of the zone where coordinates below are computed (e.g. U32)

XMIN=`GetParam "XMIN,"`						# XMIN, minimum X UTM coord of final Forced geocoded product
XMAX=`GetParam "XMAX,"`						# XMAX, maximum X UTM coord of final Forced geocoded product
YMIN=`GetParam "YMIN,"`						# YMIN, minimum Y UTM coord of final Forced geocoded product
YMAX=`GetParam "YMAX,"`						# YMAX, maximum Y UTM coord of final Forced geocoded product
GEOCKML=`GetParam "GEOCKML,"`				# GEOCKML, a kml file to define final geocoded product. If not found, it will use the coordinates above


REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
DEMNAME=`GetParam "DEMNAME,"`				# DEMNAME, name of DEM inverted by lines and columns

RESAMPDATPATH=`GetParam RESAMPDATPATH`		# RESAMPDATPATH, path to dir where resampled data will be stored 

eval PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}

source ${FCTFILE}

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# Define Crop Dir
if [ ${CROP} == "CROPyes" ]
	then
		if [ ${ZOOM} -eq 1 ] 
			then 
				CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
			else
				CROPDIR=/Crop_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}_Zoom${ZOOM} #_ML${INTERFML}
		fi		
	else
		CROPDIR=/NoCrop
fi

# Define Dir where data are/will be cropped
INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
mkdir -p ${INPUTDATA}

if [ -z ${LLRGCO} ] 
	then 
		EchoTee "LLRGCO and LLAZCO seemed not set in Parameters File. Will use default vlaue 50 and 50."
		EchoTee "This is only used to ensure common crop for shadow measurements; shouldn't be a problem except if InSAR stops before 100%"
		EchoTee ""
		LLRGCO=50	
		LLAZCO=50
fi
EchoTee ""
EchoTee "Will run InSAR process with Lower Left Az and Range coord offset : ${LLRGCO} and ${LLAZCO}."
EchoTee ""

# Prepare image naming
MAS=`GetDateCSL ${MASINPUT}`    # i.e. if S1 is given in the form of name, MAS is now only the date anyway
SLV=`GetDateCSL ${SLVINPUT}`    # i.e. if S1 is given in the form of name, SLV is now only the date anyway

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
eval RNDM1=`echo $(( $RANDOM % 10000 ))`

case ${SATDIR} in 
	"S1") 
		MASNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${MAS} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
		SLVNAME=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SLV} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, SLVNAME is now the full name of the image anyway
		
		MASDIR=${MASNAME}.csl  # need this definition here for usage in GetParamFromFile
		SLVDIR=${SLVNAME}.csl

		S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
		S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
		if [ ${S1MODE} == "IW" ] || [ ${S1MODE} == "EW" ]
			then 
				S1MODE="WIDESWATH"
				CROPDIR=/NoCrop
			else 
				S1MODE="STRIPMAP"
		fi
		EchoTee "Processing S1 images in mode ${S1MODE}" 

		#stop processing if Zoom is requested for S1 Wide Swath without a crop or with a crop defined by kml. MUST be CROPyes and crop given in corners coordinates
		if [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1" ]
			then
				if [ "${CROP}" != "CROPyes" ] 
					then 
						echo "Zooming in S1 WideSwath requires a crop defined with coordinates (not a kml !); please correct the Parameters file and relaunch"
						exit
				fi	
		fi 

		# Creates an empty file .../SAR_CSL/S1/REGION/NoCrop/DoNotUpdateProducts_Date_RNDM.txt to let ReadAll_Img.sh to know
		# that it can't remove the processed products of S1 data of the same mode as the one under progress to avoid prblms
		eval FLAGUSAGE=${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop/DoNotUpdateProducts_${RUNDATE}_${RNDM1}_SPNU.txt
		function CleanExit()
			{
				# if ctrl-c is pressed, it removes ${FLAGUSAGE} before exiting
				# NOTE that it does not work if script is terminated using kill !
				rm -f ${FLAGUSAGE}
				exit
			}
			
		trap CleanExit SIGINT
		# also clean if exit
		trap "rm -f ${FLAGUSAGE}" EXIT
		touch ${FLAGUSAGE}
		
		;;
	"TDX")
		MASNAME=${MAS} 
		SLVNAME=${SLV} 
		SLVORIG=${SLV}

		# First ensure that MAS is in _TX	
		#MASTDXMODE=`echo -n ${TRKDIR} | tail -c 3`
		MASTDXMODE="_${TRKDIR##*_}"   # everything after last _, incl _
		BSORPM==`echo ${TRKDIR} | rev | cut -d_ -f 4 | rev` 	# i.e. from TRKDIR name: PM (pursuite) or BS (bistatic) 
		TDXMODE=`echo ${TRKDIR} | rev | cut -c4- | rev`   		# i.e. everything in TRKDIR name but the _TX or _RX

		# Master must always be TX. Slv is TX except when Topo with master date = slave date :
 		if [ ${MASTDXMODE} != "_TX" ] 
 			then 
 				EchoTee "Primary mode is ${MASTDXMODE}, not TX; please check" 
 				exit 0
 			else 
 				if [ ${MASNAME} == ${SLVNAME} ] 
 			 		then
 			 			SLVTDXMODE="_RX"
 						# sort out the dir issue when mas = slv	
 			 			EchoTee " MAS == SLV. However, both images must be stored in same dir TRKDIR for the integrity of the processing"
						EchoTee " Hence, the Secondary RX image will be linked in the TX dir with a dummy name, i.e. where millenia is replaced by 9000 (eg. 90190730 instead of 20190730)"
						EchoTee " Therefore let's change its date by year 9yyy "
						DUMMYSLVDATE=`echo ${SLV} | ${PATHGNU}/gsed "s/2/9/1"`
						if [ ! -d ${DATAPATH}/${SATDIR}/${TDXMODE}${MASTDXMODE}/${CROPDIR}/${DUMMYSLVDATE}.csl ] ; then ln -s ${DATAPATH}/${SATDIR}/${TDXMODE}${SLVTDXMODE}/${CROPDIR}/${SLV}.csl ${DATAPATH}/${SATDIR}/${TDXMODE}${MASTDXMODE}/${CROPDIR}/${DUMMYSLVDATE}.csl ; fi
						SLV=${DUMMYSLVDATE}
						SLVNAME=${DUMMYSLVDATE} 
 			 		else
 			 			 SLVTDXMODE="_TX"
 			 	fi 					
		fi
		MASDIR=${MASNAME}.csl
		SLVDIR=${SLVNAME}.csl		
		;;
	*)
		MASNAME=${MAS} 
		SLVNAME=${SLV} 
		
		MASDIR=${MASNAME}.csl
		SLVDIR=${SLVNAME}.csl
		;;
esac	

mkdir -p ${PROPATH}

RUNDIR=${PROPATH}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}${COMMENT}
if [ ! -d "${RUNDIR}" ]; then
		mkdir ${RUNDIR}
	else
		echo "  //  Sorry, ${RUNDIR} dir exists. Probable previous computation. Please check."
		exit 0
fi

cp ${PARAMFILE} ${RUNDIR}
cd ${RUNDIR}

# Log File
LOGFILE=${RUNDIR}/LogFile_${MAS}_${SLV}_${RUNDATE}.txt

# Get date of last AMSTer Engine source dir (require FCT file sourced above)
GetAMSTerEngineVersion
# Store date of last AMSTer Engine source dir
echo "Last created AMSTer Engine source dir suggest SinglePairNoUnwrap processing with ME version: ${LASTVERSIONMT}" > ${RUNDIR}/Processing_Pair_w_AMSTerEngine_V.txt

# Check required dir:
#####################
	# Where data will be processed
	if [ -d "${PROROOTPATH}/" ]
	then
 	  echo "  //  OK: a directory exist where I can create a processing dir." 
	else
		PROROOTPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$PROROOTPATH)"
	   if [ -d "${PROROOTPATH}/" ]
			then
  	 			echo "  // Double mount of hp-storeesay. Renamed dir with -1"
 	  		else 
  	 			echo " "
  	 			echo "  //  NO directory ${PROROOTPATH}/ where I can create a processing dir. Can't run..." 
   				echo "  //  Check parameters files and  change hard link if needed."
  	 			exit 1
 	  	fi
	fi

	# Path to data
	if [ -d "${DATAPATH}" ]
	then
	   echo "  //  OK: a directory exist where data in csl format are supposed to be stored." 
	   mkdir -p ${PROPATH}
	else
	   DATAPATH="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DATAPATH)"
	   if [ -d "${DATAPATH}/" ]
			then
				echo "  // Double mount of hp-storeesay. Renamed dir with -1"
			else 
	 			echo " "
	   			echo "  //  NO expected data directory. Can't run..." 
	   			echo "  //  PLEASE REFER TO SCRIPT and  change hard link if needed"
	   			exit 1
		fi
	fi

	if [ -d "${DEMDIR}" ]
	then
	   echo "  //  OK: a directory exist where DEM is supposed to be stored." 
	else
		DEMDIR="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$DEMDIR)"
	   if [ -d "${DEMDIR}/" ]
			then
				echo "  // Double mount of hp-storeesay. Renamed dir with -1"
			else 
	  			echo " "
	   			echo "  //  NO expected DEM directory. Can't run..." 
	   			echo "  //  PLEASE REFER TO SCRIPT and  change hard link if needed"
	   			exit 1		
	   	fi
	fi
# 	
# 	# Check that PROCESSMODE is consistent with unwrapping parameters
# 		if [ "${PROCESSMODE}" == "" ] 
# 			then 
# 				SpeakOut "PROCESSMODE parameter is missing in your Launch Parameters File, which must be version April 2019 or later. Please update." 
# 				exit 1
# 		fi
# 		if  [ "${PROCESSMODE}" != "${SNAPHUMODE}" ] && [ "${UW_METHOD}" == "SNAPHU" ]
# 			then 
# 				SpeakOut "You request a ${PROCESSMODE} processing but intend to unwrap with snaphu using ${UW_METHOD} default Snaphu parameters. Do you want to continue ?" 
# 				while true; do
# 					read -p "You request a ${PROCESSMODE} processing but intend to unwrap with snaphu using ${UW_METHOD} default Snaphu parameters. Do you want to continue ?"  yn
# 					case $yn in
# 						[Yy]* ) 
# 							echo "OK, you know..."
# 							break ;;
# 						[Nn]* ) 
# 	   						exit 1	
# 							break ;;
# 						* ) echo "Please answer yes or no.";;
# 					esac
# 				done
# 		fi

	echo "" 
	echo "  // ---------------------------------------------------------------------"
	echo "  //  Suppose data are stored somewhere on ${DATAPATH}"
	echo "  //          If not change hard link in parameters file"
	echo "  //  Suppose data will be processed somewhere in ${PROPATH}/"
	echo "  //          If not change hard link in parameters file"
	echo "  // ---------------------------------------------------------------------"
	echo ""

# define stuffs here below even if no SM because it may be usefull to pick up image coregistered on super master and hence skip coarse coreg 
if [ $# -eq 7 ] && [ "$5" != "NOSM" ] && [ "${S1MODE}" != "WIDESWATH" ] # && [ ${SATDIR} != "S1" ]
	then 
		EchoTee "OK you wanted a Global Primary (SuperMaster) coregistration"
		EchoTee "Coregistration of Primary onto the Global Primary (SuperMaster) MUST be in :" 
		EchoTee "${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/(No)Crop"
		EchoTee "Note : it must be with the same crop !!"
		SUPERMASTER=`GetDateCSL ${SUPMASINPUT}`
		if [ ${SATDIR} == "S1" ] ; then 
				SUPERMASNAME=`ls ${INPUTDATA} | ${PATHGNU}/grep ${SUPERMASTER} | cut -d . -f 1` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway
			else
				SUPERMASNAME=${SUPERMASTER} 
		fi	
		SUPERMASDIR=${SUPERMASNAME}.csl

		if [ ${CROP} == "CROPyes" ] 
			then 
				if [ ${ZOOM} -eq 1 ] 
					then 
						SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
					else
						SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}_Zoom${ZOOM}
					fi		
			else 
				SMCROPDIR=SMNoCrop_SM_${SUPERMASTER} #_Zoom${ZOOM}_ML${INTERFML}
		fi
		OUTPUTDATA=${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}
		SMFORCOREG=`basename ${OUTPUTDATA} | cut -d _ -f 3`  # i.e. SUPERMASTER what ever the form is
		
		if [ -d "${OUTPUTDATA}/" ] && [ ${SUPMASINPUT} != "NOSM" ]
			then
   				echo "  //  OK, there is a dir where Global Primary (SuperMaster) is already computed with all Secondaries:" 
				if [ -f ${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/InSARParameters.txt ] 
					then 
						echo "  //  ${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/InSARParameters.txt \n" 
						MODFROMSM="YES"
					else
						echo "  //  Missing :  ${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/TextFiles/InSARParameters.txt"
   						exit 1			
				fi
			else
				OUTPUTDATA="$(${PATHGNU}/gsed s/-Data_Share1/-Data_Share1-1/ <<<$OUTPUTDATA)"
			   if [ -d "${OUTPUTDATA}/" ]
					then
						echo "  // Double mount of hp-storeesay. Renamed dir with -1"
						MODFROMSM="YES"
					else 
  						echo "  //  There is no dir where Global Primary (SuperMaster) is already computed with all Secondaries. I can't run. "
  						echo "  //  I need this :"
  						echo ${OUTPUTDATA}
   						exit 1
				fi
		fi
	else 
		if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]
		then 
			# Not need to try taking advantage of existing Supermatser_Master and Supermaster_Slave coregistration because no coarsecoregistration is performed for S1
			EchoTee " No coregistration possible on a Global Primary (SuperMaster) with S1 data. Not needed anyway given the quality of the orbits."
			MODFROMSM="NO"		
			
		elif [ ${SATDIR} == "TDX" ] && [ ${MAS} == ${SLVORIG} ] ; then 
			# Not need to try taking advantage of existing Supermatser_Master and Supermaster_Slave for TandemX
			EchoTee " No coregistration possible on a Global Primary (SuperMaster) for TDX pair at same date."
			MODFROMSM="NO"		
		else
			# one must guess the SUPERMASTER (and let's name it SMFORCOREG) and define the SMCROPDIR if one wants to try skiping module and coarse coreg computation 
			#SMFORCOREG=`basename ${OUTPUTDATA} | cut -d _ -f 3`
# DO NOT TAKE THIS OPTION BECAUSE THIS SCRIPT IS MOSTLY USED FOR ALL2GIF AND MUST HENCE BE AUTOMATIC
#			say "Do you want to benefit from the coregistration of the master and slave on the super master to spare processing time ?" 
#			while true; do
#				read -p "Do you want to benefit from the coregistration of the master and slave on the super master to spare processing time ?"  yn
#				case $yn in
#					[Yy]* ) 
#						EchoTee "OK let's spare time... Here are the SuperMasters already used to coregister some images."
#						SMFORCOREG=`ls ${RESAMPDATPATH}/${SATDIR}/${TRKDIR} | ${PATHGNU}/grep SM | cut -d _ -f 3 | uniq `
#						EchoTee "  ${SMFORCOREG}"
#						echo "  Select one of them and if both of your images were already cropped with that master, we will use their module and skip Coarse Coreg. "
#						read SMFORCOREG
#						if [ ${CROP} == "CROPyes" ] 
#							then 
#								SMCROPDIR=SMCrop_SM_${SMFORCOREG}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP} #_Zoom${ZOOM}_ML${INTERFML}
#							else 
#								SMCROPDIR=SMNoCrop_SM_${SMFORCOREG} #_Zoom${ZOOM}_ML${INTERFML}
#						fi
#						OUTPUTDATA=${RESAMPDATPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}
#						if [ -s ${OUTPUTDATA}/${SMFORCOREG}_${MAS}/i12/InSARProducts/${MAS}.interpolated.csl ] &&  [ -s ${OUTPUTDATA}/${SMFORCOREG}_${SLV}/i12/InSARProducts/${SLV}.interpolated.csl ] 
#							then 
#								EchoTee " OK images are already cropped and coregistered on ${SMFORCOREG}. Will use it for sparing time."
#								SUPERMASTER=${SMFORCOREG}
#								SUPERMASNAME=${SMFORCOREG}  # because it can't be S1
#								SUPERMASDIR=${SMFORCOREG}.csl
#								MODFROMSM="YES"
#							else
#								EchoTee " Sorry, images were not cropped and coregistered yet on ${SMFORCOREG}." 
#								EchoTee " Let's do the usual processing : compute modules and coarse coreg."
#								MODFROMSM="NO"
#						fi
#						break ;;
#					[Nn]* ) 
#						EchoTee "OK, let's do the usual processing : compute modules and coarse coreg."
						MODFROMSM="NO"
#						break ;;
#					* ) 
#						echo "Please answer yes or no.";;
#				esac
#			done
		fi
fi


# Let's Go:
###########	

	echo "" > ${LOGFILE}
	EchoTee "--------------------------------"	
	EchoTee "Processing launched on ${RUNDATE} " 
	EchoTee "" 
	EchoTee "Main script version: " 
	EchoTee "    ${PRG} ${VER}, ${AUT}" 
	EchoTee ""
	EchoTee "Functions script version: " 
	EchoTee "    ${FCTFILE} ${FCTVER}, ${FCTAUT}"
	EchoTee "" 
	EchoTee "--------------------------------"	
	EchoTee "--------------------------------"
	EchoTee ""
	EchoTee "Command line used and parameters:"
	EchoTee "$(dirname $0)/${PRG} $1 $2 $3 $4 $5 $6 $7"
	EchoTee ""
	EchoTee " And this parameters file contains the following parameters:" 
	EchoTee "  (Parameters are echoed only in Logfile)"
	EchoTee ""
	EchoTee "--------------------------------"	
	cat ${PARAMFILE} >> ${LOGFILE}
	EchoTee "--------------------------------"	
	EchoTee "--------------------------------"
	EchoTee ""

# Crop
	EchoTee "Crop CSL"	
	EchoTee "--------------------------------"
		case ${CROP} in 
			"CROPyes")
				if [  ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]
					then
						EchoTee "No need to crop S1 WideSwath now..."
						CROPDIR=/NoCrop	
						INPUTDATA=${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}		
					else
						# Create Crop Dir on archive disk
						if [ ! -d "${INPUTDATA}/${MASDIR}" ] && [ ! -d "${INPUTDATA}/${SLVDIR}" ] ; then  # i.e. ${DATAPATH}/${SATDIR}/${TRKDIR}/${CROPDIR}
								EchoTee "No Crop of that size yet. Will create a dir and store data there"
								if [ "${CROPFCT}" == "Crop" ] ; then 
										Crop ${MASNAME}       
										Crop ${SLVNAME}
									else
										CropAtZeroAlt ${MASNAME}       
										CropAtZeroAlt ${SLVNAME}
								fi
								EchoTee "Crop applied : lines ${FIRSTL}-${LASTL} ; pixels ${FIRSTP}-${LASTP}"
								EchoTee "Crop applied : Zoom ${ZOOM} ; Interferometric products ML factor ${INTERFML}"
						else
							if [ ! -d "${INPUTDATA}/${MASDIR}" ]; then
									EchoTee "Primary ${MAS} not cropped yet. Will crop it."
									if [ "${CROPFCT}" == "Crop" ] ; then 
											Crop ${MASNAME}
										else
											CropAtZeroAlt ${MASNAME}
									fi
									EchoTee "Crop applied : lines ${FIRSTL}-${LASTL} ; pixels ${FIRSTP}-${LASTP}"
									EchoTee "Crop applied : Zoom ${ZOOM} ; Interferometric products ML factor ${INTERFML}"
							fi
							if [ ! -d "${INPUTDATA}/${SLVDIR}" ]; then
									EchoTee "Secondary ${SLV} not cropped yet. Will crop it."
									if [ "${CROPFCT}" == "Crop" ] ; then 
											Crop ${SLVNAME}
										else
											CropAtZeroAlt ${SLVNAME}
									fi
									EchoTee "Crop applied : lines ${FIRSTL}-${LASTL} ; pixels ${FIRSTP}-${LASTP}"
									EchoTee "Crop applied : Zoom ${ZOOM} ; Interferometric products ML factor ${INTERFML}"
							fi
							if [[ -d "${INPUTDATA}/${MASDIR}" && -d "${INPUTDATA}/${SLVDIR}" ]]; then
									EchoTee "Primary ${MAS} and Secondary ${SLV} already cropped."
									EchoTee ""
							fi
						fi 
				fi
				echo ;;
			"CROPno")		
				EchoTee "No crop applied. Keep full footprint" 
				echo ;;
			*.kml)  # do not quote this because of the wild card
				if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]
					then 
						EchoTee "Shall use ${CROP} file for pseudo crop by defining area of interest."
						CROPKML=${CROP}
					else 	
						EchoTee "Option for crop with kml not tested yet for non S1 IW images; Check scripts and test..."
						exit 0
				fi	;;
		esac

	# Compute ratio between Az and Range pix size
	# Ratio must be computed after Crop and zoom to get info from zoom 
	if [ "${SATDIR}" != "S1" ] && [ "${MODFROMSM}" == "YES" ] && [ "${S1MODE}" != "WIDESWATH" ]
		then
			EchoTee "Get Rg and Az sampling [m] from Global Primary (SuperMaster)"
			RGSAMP=`GetParamFromFile "Range sampling [m]" SuperMaster_SLCImageInfo.txt`   # not rounded 
			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SuperMaster_SLCImageInfo.txt` # not rounded
			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" SuperMaster_SLCImageInfo.txt` # not rounded
		else 
			EchoTee "Get Rg and Az sampling [m] from Primary"
			RGSAMP=`GetParamFromFile "Range sampling [m]" SinglePair_SLCImageInfo.txt`   # not rounded 
			AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SinglePair_SLCImageInfo.txt` # not rounded
			INCIDANGL=`GetParamFromFile "Incidence angle at median slant range [deg]" SinglePair_SLCImageInfo.txt` # not rounded
	fi

	EchoTee "Range sampling : ${RGSAMP}"
	EchoTee "Azimuth sampling : ${AZSAMP}"
	EchoTee "Incidence angle : ${INCIDANGL}"

	RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
	RATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l` # with 5 digits 

	EchoTee "--------------------------------"
	EchoTee "Pixel Ratio is ${RATIO}"
 	EchoTee "Pixel Ratio as Real is ${RATIOREAL}"
	EchoTee "--------------------------------"
	EchoTee ""

# Define Super Master if required and prepare stuffs
	if [ "${MODFROMSM}" == "YES" ]		# When processing SinglePair, SUPERMASTER is not read from ParametersFile. It is read from input cmd if 5 parameters are provided
		then 
			IMGWITHDEM=${SUPERMASNAME} 	# When computed during SinglePair with SuperMaster (or during mass processing)
		else 
			IMGWITHDEM=${MASNAME} 		# When computed during SinglePair without SuperMaster 
	fi

	# Need this for ManageDEM
	if [ "${ZOOM}" == "1"  ] 
		then
			PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
			PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
		else
# 
# 			if [ "${RATIO}" -eq 1 ] 
# 				then 
# 					EchoTee "Az sampling (${AZSAMP}m) is similar to Range sampling (${RGSAMP}m)." 
# 					EchoTee "   Probably processing square pixel data such as RS, CSK or TSX." 
# 					EchoTee "Uses same ZOOM factor in X and Y"
# 					ZOOMX=${ZOOM}
# 					ZOOMY=${ZOOM}	
# 				else
# 					RET=$(echo "$RGSAMP < $AZSAMP" | bc )  # Trick needed for if to compare integer nrs
# 					if [ ${RET} -ne 0 ] 
# 						then
# 							EchoTee "Az sampling (${AZSAMP}m) is larger than Range sampling (${RGSAMP}m)." 
# 							EchoTee "   Probably processing Sentinel data." 
# 							EchoTee "Uses original ZOOM factor (i.e. ${ZOOM}) in X and ZOOM*RATIO in Y (i.e. ${ZOOM} * ${RATIO})"
# 							ZOOMX=${ZOOM}
# 							ZOOMY=`echo "(${ZOOM} * ${RATIO})" | bc` # Integer	
# 						else
# 							EchoTee "Az sampling (${AZSAMP}m) is smaller than Range sampling (${RGSAMP}m)." 
# 							EchoTee "   Probably processing ERS or Envisat data." 
# 							EchoTee "Uses  ZOOM*RATIO in X  (i.e. ${ZOOM} * ${RATIO}) and original ZOOM factor (i.e. ${ZOOM}) in Y "
# 							ZOOMX=`echo "(${ZOOM} * ${RATIO})" | bc` # Integer
# 							ZOOMY=${ZOOM}	
# 					fi	
# 					unset RET	
# 			fi
			
			PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} * ${INTERFML} ) / ${ZOOM} " | bc`  # size of ML pixel in az (in m) 
			PIXSIZERG=`echo "scale=2; ( ${RGSAMP} * ${INTERFML} ) / ${ZOOM} " | bc`  # size of ML pixel in range (in m) 

	fi

# slantRangeDEM
	ManageDEM

# Initialise InSAR  - Preferabily performed AFTER slantRangeDEM as it may use info from DEM for computing baselines for initialising InSAR
	EchoTee "Initialise InSAR"		
	EchoTee "--------------------------------"
	EchoTee "--------------------------------"
	if [ "${SATDIR}" == "S1" ] && [ "${CROPKML}" != "" ] 
		then # pseudo crop based on kml file for S1 images. Not tested for other sat yet. 
			initInSAR ${INPUTDATA}/${MASDIR} ${INPUTDATA}/${SLVDIR} ${RUNDIR}/i12 ${CROPKML} P=${INITPOL}
		else 
			if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1"  ] 
				then 
					# if request zoom of S1 WS, data will be prepared in a i12.NoZoom to end up in a classica i12 for the rest of processing 
					initInSAR ${INPUTDATA}/${MASDIR} ${INPUTDATA}/${SLVDIR} ${RUNDIR}/i12.No.Zoom P=${INITPOL}
				else
					initInSAR ${INPUTDATA}/${MASDIR} ${INPUTDATA}/${SLVDIR} ${RUNDIR}/i12 P=${INITPOL}
			fi
	fi
	# If SUperMaster requested, must update file after initInSAR of course... 
	if [ "${MODFROMSM}" == "YES" ]
		then 
			EchoTee " Take into account Global Primary (SuperMaster) orbitography:"
			ChangeParam "Global master to master InSAR directory path" ${OUTPUTDATA}/${SUPERMASTER}_${MASNAME}/i12/ InSARParameters.txt
	fi

	# Bistatic only if BS mode AND mas = slv
	if [ "${SATDIR}" == "TDX" ] && [ ${MAS} == ${SLV} ] && [ ${BSORPM} == "BS" ] 
		then 
			EchoTee "Bistatic" 
			ChangeParam "Bistatic interferometric pair" YES InSARParameters.txt
		else
			#EchoTee "No Bistatic" 
			if [ "${SATDIR}" == "S1" ]  && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1"  ] 
				then
					ChangeParam "Bistatic interferometric pair" NO InSARParametersZoom.txt
				else
					ChangeParam "Bistatic interferometric pair" NO InSARParameters.txt
			fi
	fi
# Amplitude images"					
	EchoTee "--------------------------------"
	EchoTee "Amplitude images"					
	EchoTee "--------------------------------"
	EchoTee "--------------------------------"


	# So far MODFROMSM means that one wants to coreg on SM.
	#  in such a case, when orbits are good (i.e. S1 STRPMAP, ENV, TSX, TDX), we can skip module and coarse coregistration of MAS-SLV. 
	#  For ERS, RS, CSK, ALOS... it is advised to still comupte module and coarse coregistration.

	# Change reduction factor to 1 3 or even 1 1  and keep ratio for raster image only 
	if [ ${SATDIR} == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ]					
		then	
			EchoTee "Skip Amplitude generation because not needed for S1 coreg"
			EchoTee " If want to run it anyway, ensure to have read S1 image with -b option"
			if [ "${ZOOM}" == "1"  ] 
				then
					cd ${RUNDIR}/i12
				else
					cd ${RUNDIR}/i12.No.Zoom	
			fi
		elif [ ${SATDIR} == "TDX" ] && [ ${MAS} == ${SLVORIG} ] ; then 
			EchoTee "Skip Amplitude generation because not needed for TDX when MAS=SLV"
			cd ${RUNDIR}/i12	
		else
			if [ "${MODFROMSM}" == "YES" ] 
				then 
					if [ ${SATDIR} == "S1" ] 
						then 
							EchoTee "Skip module image and Coarse Coregistration computation for S1 because orbits are good enough." 
							EchoTee "Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
							cd ${RUNDIR}/i12
							FORCECOREG=NO  # will not need to force the coarse coregistration despite the SM
						else 
							if [ ${SATDIR} == "TSX" ] || [ ${SATDIR} == "TDX" ] || [ ${SATDIR} == "ENVISAT" ] # S1 wideswath are already excluded from MODFROMSM
								then 
									if [ ${CCOHWIN} == 0 ] 
										then 
											EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster) and TSX/TDX or ENVISAT orbits are good enough to Skip module image and Coarse Coregistration computation." 
											EchoTee "You choose that option by setting CCOHWIN=0. Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
											cd ${RUNDIR}/i12
											FORCECOREG=NO  # will not need to force the coarse coregistration despite the SM
										else 
											EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster). Although TSX/TDX or ENVISAT orbits are good enough, you choosed NOT to Skip module image and Coarse Coregistration computation by setting CCOHWIN=0." 
											EchoTee "Therefore one need to compute module image for the Coarse Coregistration."
											MakeAmpliImgAndPlot 1 1 ORIGINALFORM 	# Parameter is ML factor for RASTER image in x and y; force ORIGINALFORM for module used for coreg
											# test if mod is empty - may means that crop is outside of image
											if [ ! -s ${PATHMAS} ] || [ ! -s ${PATHSLV} ] ; then
												EchoTeeRed "  // Module file of Primary and/or Secondary is empty. May indicate that crop is outside of image or CSL image corrupted.  \n"
											fi	
											FORCECOREG=YES # will need to force the coarse coregistration despite the SM
									fi
								else 
									EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster) but ERS, RS, CSK, ALOS... orbits are not safe enough to Skip module image and Coarse Coregistration computation." 
									EchoTee "Therefore one need to compute module image for the Coarse Coregistration."
									MakeAmpliImgAndPlot 1 1 ORIGINALFORM 	# Parameter is ML factor for RASTER image in x and y; force ORIGINALFORM for module used for coreg
									# test if mod is empty - may means that crop is outside of image
									if [ ! -s ${PATHMAS} ] || [ ! -s ${PATHSLV} ] ; then
										EchoTeeRed "  // Module file of Primary and/or Secondary is empty. May indicate that crop is outside of image or CSL image corrupted.  \n"
									fi	
									FORCECOREG=YES # will need to force the coarse coregistration despite the SM
							fi
						
					fi
				else
					EchoTee "Primary and Secondary are not coregistered on a Global Primary (SuperMaster). Therefore one need to compute module image for the Coarse Coregistration."
					MakeAmpliImgAndPlot 1 1 ORIGINALFORM 	# Parameter is ML factor for RASTER image in x and y; force ORIGINALFORM for module used for coreg
					# test if mod is empty - may means that crop is outside of image
					if [ ! -s ${PATHMAS} ] || [ ! -s ${PATHSLV} ] ; then
						EchoTeeRed "  // Module file of Primary and/or Secondary is empty. May indicate that crop is outside of image or CSL image corrupted.  \n"
					fi	
			fi
	fi	

EchoTee "--------------------------------"
EchoTee "Coregistration - resampling"	
EchoTee "--------------------------------"

if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] 
	then
		# Performing zoom with S1 wide swath is possible if images are coreg with option -d
		if [ "${ZOOM}" != "1" ] 
			then 
				EchoTeeRed "Coregister Sentinel data with zoom factor not 1." 
				cd ${RUNDIR}/i12.No.Zoom
				S1Coregistration -n
				# should now have a master and a slave interpolated i12/InSARProducts => need apply cut and zoom
				# the master
				cd ${RUNDIR}/i12.No.Zoom/InSARProducts
				cutAndZoomCSLImage ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt -create
				ChangeParam "Input file path in CSL format" ${RUNDIR}/i12.No.Zoom/InSARProducts/${MASNAME}.csl CropZoom.txt
				ChangeParam "Output file path" ${RUNDIR}/i12.No.Zoom/InSARProducts/${MASNAME}.Z.csl CropZoom.txt
				# ChangeParam "Georeferenced DEM file path" ${DEMDIR}/${DEMNAME} CropZoom.txt # Not needed
				
				#RGSAMP=`GetParamFromFile "Range sampling [m]" SinglePair_SLCImageInfo.txt`   # not rounded 
				#AZSAMP=`GetParamFromFile "Azimuth sampling [m]" SinglePair_SLCImageInfo.txt` # not rounded
				#RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal

# 				if [ "${RATIO}" -eq 1 ] 
# 					then 
# 						EchoTee "Az sampling (${AZSAMP}m) is similar to Range sampling (${RGSAMP}m)." 
# 						EchoTee "   Probably processing square pixel data such as RS, CSK or TSX." 
# 						EchoTee "Uses same ZOOM factor in X and Y"
# 						ZOOMX=${ZOOM}
# 						ZOOMY=${ZOOM}	
# 					else
# 						RET=$(echo "$RGSAMP < $AZSAMP" | bc )  # Trick needed for if to compare integer nrs
# 						if [ ${RET} -ne 0 ] 
# 							then
# 								EchoTee "Az sampling (${AZSAMP}m) is larger than Range sampling (${RGSAMP}m)." 
# 								EchoTee "   Probably processing Sentinel data." 
# 								EchoTee "Uses original ZOOM factor (i.e. ${ZOOM}) in X and ZOOM*RATIO in Y (i.e. ${ZOOM} * ${RATIO})"
# 								ZOOMX=${ZOOM}
# 								ZOOMY=`echo "(${ZOOM} * ${RATIO})" | bc` # Integer	
# 							else
# 								EchoTee "Az sampling (${AZSAMP}m) is smaller than Range sampling (${RGSAMP}m)." 
# 								EchoTee "   Probably processing ERS or Envisat data." 
# 								EchoTee "Uses  ZOOM*RATIO in X  (i.e. ${ZOOM} * ${RATIO}) and original ZOOM factor (i.e. ${ZOOM}) in Y "
# 								ZOOMX=`echo "(${ZOOM} * ${RATIO})" | bc` # Integer
# 								ZOOMY=${ZOOM}	
# 						fi	
# 						unset RET	
# 				fi

				

				if [ "${CROP}" == "CROPyes" ] 
					then
						# test if crop is provided in pixels or in coordinates: if at least one of the coordinates has a dot, it must be GEO
						if [[ "${FIRSTL}${LASTL}${FIRSTP}${LASTP}" == *.* ]] 
							then
								EchoTee "At least one of the crop coordinates has a dot. Must hence be GEO coord system"
								ChangeParam "Coordinate system [SRA / GEO]" GEO CropZoom.txt
							else
								EchoTee "None of the crop coordinates has a dot. Must hence be SRA coord system"
								ChangeParam "Coordinate system [SRA / GEO]" SRA CropZoom.txt
						fi
						ChangeCropZoomCSLImage "lower left corner X coordinate" ${FIRSTP}
						ChangeCropZoomCSLImage "lower left corner Y coordinate" ${FIRSTL}
						ChangeCropZoomCSLImage "upper right corner X coordinate" ${LASTP}
						ChangeCropZoomCSLImage "upper right corner Y coordinate" ${LASTL}
					else 
						LASTPIX=`GetParamFromFile "Range dimension [pixels]" SinglePair_SLCImageInfo.txt`
						LASTLIN=`GetParamFromFile "Azimuth dimension [pixels]" SinglePair_SLCImageInfo.txt`
						ChangeParam "Coordinate system [SRA / GEO]" SRA CropZoom.txt
						ChangeCropZoomCSLImage "lower left corner X coordinate" 0
						ChangeCropZoomCSLImage "lower left corner Y coordinate" 0
						ChangeCropZoomCSLImage "upper right corner X coordinate" ${LASTPIX}
						ChangeCropZoomCSLImage "upper right corner Y coordinate" ${LASTLIN}
				fi
				ChangeCropZoomCSLImage "X zoom factor" ${ZOOM}
				ChangeCropZoomCSLImage "Y zoom factor" ${ZOOM}
				cutAndZoomCSLImage ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt
				mv ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt ${RUNDIR}/i12.No.Zoom/InSARProducts/Crop_${MASNAME}.txt	
				# the slave
				cutAndZoomCSLImage ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt -create
				ChangeParam "Input file path in CSL format" ${RUNDIR}/i12.No.Zoom/InSARProducts/${SLVNAME}.interpolated.csl CropZoom.txt
				ChangeParam "Output file path" ${RUNDIR}/i12.No.Zoom/InSARProducts/${SLVNAME}.interpolated.Z.csl CropZoom.txt
				#ChangeParam "Georeferenced DEM file path" ${DEMDIR}/${DEMNAME} CropZoom.txt # Not needed
				
				if [ "${CROP}" == "CROPyes" ]
					then
						# test if crop is provided in pixels or in coordinates: if at least one of the coordinates has a dot, it must be GEO
						if [[ "${FIRSTL}${LASTL}${FIRSTP}${LASTP}" == *.* ]] 
							then
								EchoTee "At least one of the crop coordinates has a dot. Must hence be GEO coord system"
								ChangeParam "Coordinate system [SRA / GEO]" GEO CropZoom.txt
							else
								EchoTee "None of the crop coordinates has a dot. Must hence be SRA coord system"
								ChangeParam "Coordinate system [SRA / GEO]" SRA CropZoom.txt
						fi
						ChangeCropZoomCSLImage "lower left corner X coordinate" ${FIRSTP}
						ChangeCropZoomCSLImage "lower left corner Y coordinate" ${FIRSTL}
						ChangeCropZoomCSLImage "upper right corner X coordinate" ${LASTP}
						ChangeCropZoomCSLImage "upper right corner Y coordinate" ${LASTL}
					else
						ChangeParam "Coordinate system [SRA / GEO]" SRA CropZoom.txt
						ChangeCropZoomCSLImage "lower left corner X coordinate" 0
						ChangeCropZoomCSLImage "lower left corner Y coordinate" 0
						ChangeCropZoomCSLImage "upper right corner X coordinate" ${LASTPIX}
						ChangeCropZoomCSLImage "upper right corner Y coordinate" ${LASTLIN}
				fi
				ChangeCropZoomCSLImage "X zoom factor" ${ZOOM}
				ChangeCropZoomCSLImage "Y zoom factor" ${ZOOM}
				cutAndZoomCSLImage ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt
				mv ${RUNDIR}/i12.No.Zoom/InSARProducts/CropZoom.txt ${RUNDIR}/i12.No.Zoom/InSARProducts/Crop_${SLVNAME}.txt	
				# then must create new InitInSAR
				initInSAR ${RUNDIR}/i12.No.Zoom/InSARProducts/${MASNAME}.Z.csl ${RUNDIR}/i12.No.Zoom/InSARProducts/${SLVNAME}.interpolated.Z.csl ${RUNDIR}/i12 ${CROPKML} P=${INITPOL}
				cd ${RUNDIR}/i12
				# must then change the Affine Transfo to 1
				ChangeParam "Ax" 1 InSARParameters.txt
				ChangeParam "Bx" 0 InSARParameters.txt
				ChangeParam "Cx" 0 InSARParameters.txt
				ChangeParam "Ay" 0 InSARParameters.txt
				ChangeParam "By" 1 InSARParameters.txt
				ChangeParam "Cy" 0 InSARParameters.txt
				# and change interpolated slave by slave
				ChangeParam "Interpolated slave image file path" ${RUNDIR}/i12.No.Zoom/InSARProducts/${SLVNAME}.interpolated.Z.csl InSARParameters.txt				
				# compute slantRangeDEM for ${MASNAME}.Z.csl
				INPUTDATA=${RUNDIR}/i12.No.Zoom/InSARProducts
				MASDIR=${MASNAME}.Z.csl
				SlantRangeExtDEM PAIR BlankRunNo # need ${INPUTDATA}/${MASDIR} defined to ${RUNDIR}/i12.No.Zoom/InSARProducts/${MASNAME}.Z.csl
			else 
				S1Coregistration
		fi
	else
		# Coarse Coregistration and quality testing
			# search for a supermaster that was used to coregister all images; if processed with 5 parameters, this is of course the same as SUPERMASTER
			if [ "${MODFROMSM}" == "YES" ] && [ "${FORCECOREG}" == "NO" ]
				then 
					EchoTee "Primary and Secondary are already coregistered on a Global Primary (SuperMaster). Let's take these interpolated.csl image as input image and skip coarse coreg"
					EchoTee "Ensure that InitInSAR was informed of the Global Primary (SuperMaster) orbitography"
					echo
				else 
					EchoTee "Primary and Secondary are not coregistered on a Global Primary (SuperMaster) or you choosed not to skip coarse coreg."
					if [ "${SATDIR}" == "TDX" ] && [ "${MAS}" == "${SLVORIG}" ]
						then 
							EchoTee "No need to CoraseCoregister TDX tandem"
						else 
							CoarseCoregTestQuality
					fi
			fi	

		# Fine Coregistration
			if [ "${SATDIR}" == "TDX" ] && [ "${MAS}" == "${SLVORIG}" ]
				then 
					EchoTee "No need to FineCoregister nor interpolate TDX tandem when MAS = SLV"
					# though need to update path to reasmpled image
					PATHSLVTDX=`GetParamFromFile "Slave image file path"  InSARParameters.txt`
					ChangeParam "Interpolated slave image file path" ${PATHSLVTDX} InSARParameters.txt
					EchoTee "--------------------------------"
					EchoTee ""
				else 
					EchoTee "--------------------------------"	

					ChangeParam "Fine registration range distance between anchor points [pix]" ${FCDISTANCHOR} InSARParameters.txt
					EchoTee ""
					ChangeParam "Fine registration azimuth distance between anchor points [pix]" ${FCDISTANCHOR} InSARParameters.txt
					EchoTee ""
					EchoTee ""
					ChangeParam "Fine coregistration correlation threshold" ${FCOH} InSARParameters.txt
					EchoTee ""
	
					RatioPix ${FCOHWIN}
					ChangeParam "Fine coregistration range window size [pix]" ${RGML} InSARParameters.txt
					ChangeParam "Fine coregistration azimuth window size [pix]" ${AZML} InSARParameters.txt
					unset RGML
					unset AZML
		
					fineCoregistration		| tee -a ${LOGFILE}
					# Test Fine Coreg 
					for ATTEMPT in 1 2 3
						do
							EchoTee "Fine coreg run nr ${ATTEMPT}:"
							TSTFINECOREG=`grep "Total number of anchor points" ${LOGFILE} | tail -n1 | tr -dc '[0-9]'`
							SIGMA=`grep sigmaRangeAzimuth ${LOGFILE} | tail -n1 |  cut -d = -f4 | ${PATHGNU}/gsed 's/\t//g' | xargs printf "%.*f\n" 0`  # rounded to 0th digits precision

							if [ "${TSTFINECOREG}" -le "4" ] ; then EchoTee " Fine processing seemed to have failes (less than 4 anchor points... Exiting" ; exit 0 ; fi
							# If Sigma too big, restart fine coreg with larger win size
							if [ "${SIGMA}" -le ${MAXSIGMARGAZ} ]   # If not aprpropriate, change hard coded param here above  
								then
									EchoTee "Fine Coregistration Sigma is less than ${MAXSIGMARGAZ}." 
									EchoTee "Suppose coregistration is OK"
									EchoTee "-----------------------------"
									break
								else 
									EchoTee "Fine Coregistration Sigma is more than ${MAXSIGMARGAZ}." 
									EchoTee "Suppose Fine coregistration is not OK "
									FCOHWINLARGER=`echo "${FCOHWIN} * ( ${ATTEMPT} + 1 ) " | bc `	
									EchoTee "    => try with larger window size	(${FCOHWINLARGER} instead of ${FCOHWIN})"		
						
									RatioPix ${FCOHWINLARGER}
									ChangeParam "Fine coregistration range window size [pix]" ${RGML} InSARParameters.txt
									ChangeParam "Fine coregistration azimuth window size [pix]" ${AZML} InSARParameters.txt
									unset RGML
									unset AZML
									fineCoregistration		| tee -a ${LOGFILE}
				
									TSTFINECOREG=`grep "Total number of anchor points" ${LOGFILE} | tail -n1 | tr -dc '[0-9]'`
									SIGMA=`grep sigmaRangeAzimuth ${LOGFILE} | tail -n1 |  cut -d = -f4 | ${PATHGNU}/gsed 's/\t//g' | xargs printf "%.*f\n" 0`  # rounded to 0th digits precision
						
							fi
					done
		
					EchoTeeYellow "  fine coreg done with ${TSTFINECOREG} anchor points"
					EchoTeeYellow "    and sigmaRangeAzimuth ${SIGMA}"
					EchoTee "--------------------------------------------------"

					# Interpolaton - Can try to Launch in background ?
					interpolation | tee -a ${LOGFILE}
				
					EchoTee "Interpolation done" 
					EchoTee "--------------------------------"
			fi	
fi	
if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1" ] 
	then
		EchoTee ""	
		EchoTee " Change the ML factor used for amplitude image generation for coregistration computation: "	
		EchoTee " S1 WideSwath with zoom"
		EchoTee " => Get back to desired ML factor for final product generation using ML from Parameters File"	
		EchoTee "    without squaring it because pixels were shared at Zoom"		
		ChangeParam "Range reduction factor" ${INTERFML} InSARParameters.txt
		ChangeParam "Azimuth reduction factor" ${INTERFML} InSARParameters.txt	  	
		PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
		PIXSIZERG=`echo "scale=2; ( ${RGSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
#		PIXSIZEAZ=`echo " ${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
#		PIXSIZERG=`echo " ${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
		

	else
		EchoTee ""	
		EchoTee " Change the ML factor used for amplitude image generation for coregistration computation: "	
		EchoTee " => Get back to desired ML factor for final product generation "	
			# Get back to desired ML factor for final product generation - compute it based on the pix size ratio
			if [ "${PIXSHAPE}" == "ORIGINALFORM" ] ; then
					ChangeParam "Range reduction factor" ${INTERFML} InSARParameters.txt
					ChangeParam "Azimuth reduction factor" ${INTERFML} InSARParameters.txt	  	
#					PIXSIZEAZ=`echo "${AZSAMP} * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
#					PIXSIZERG=`echo "${RGSAMP} * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 
					PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
					PIXSIZERG=`echo "scale=2; ( ${RGSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 

				else  
					RatioPix ${INTERFML}
					ChangeParam "Range reduction factor" ${RGML} InSARParameters.txt
					ChangeParam "Azimuth reduction factor" ${AZML} InSARParameters.txt
#					PIXSIZEAZ=`echo "${AZSAMP} * ${AZML}" | bc`  # size of ML pixel in az (in m) 
#					PIXSIZERG=`echo "${RGSAMP} * ${RGML}" | bc`  # size of ML pixel in range (in m) 
					PIXSIZEAZ=`echo "scale=2; ( ${AZSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in az (in m) 
					PIXSIZERG=`echo "scale=2; ( ${RGSAMP} / ${ZOOM} ) * ${INTERFML}" | bc`  # size of ML pixel in range (in m) 


					unset RGML
					unset AZML
			fi
fi
# INSAR

# To avoid possible offset when comparing products from same master and several slaves due to inaccurate orb, force here the area of 
# interest to start at pix 10 10 for instance (lower Left). Of offset is at opposite side of image, it will be filled with near zeros (noise).
	ChangeParam "Lower left range coordinate" ${LLRGCO} InSARParameters.txt
	ChangeParam "Lower left azimuth coordinate" ${LLAZCO} InSARParameters.txt
# DO NOT CHANGE THE COMMENTS BELOW BECAUSE THEY ARE NEEDED TO UPDATE THE SCRIPT FROM MultiLaunch.sh
# Insert here below Upper right range forced coordinates
# Insert here below Upper right azimuth forced coordinates

	case ${SATDIR} in
		"RS"|"RADARSAT") 
			InSARprocess 1 1	;;    #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"TSX") 
			InSARprocess 1 1 	;;   #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"TDX") 
			InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"CSK") 
			InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"S1") 
			InSARprocess 1 2  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"ENVISAT") 
			InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		"ERS") 
			InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
		*) 
			InSARprocess 1 1  	;;  #  Parameters = ML factor for raster figures only (eg 1 1 for square, 1 2 for S1 or 5 1 for ENV)
	esac

# Get master and slave modules at InSAR dimensions
EchoTee "---------------------------------------------------------------- \n"	
	RatioPix ${INTERFML}
	EchoTee "Range and Azimuth reduction factors are ${RGML} and ${AZML} resp. \n"
	RANGEML=${RGML}
	AZIMML=${AZML}
	unset RGML
	unset AZML

EchoTee " Compute amplitude image of Primary Zoomed x ML"

MASPOL=`GetParamFromFile "Master polarization channel" InSARParameters.txt`
SLVPOL=`GetParamFromFile "Slave polarization channel" InSARParameters.txt`

	if [ "${SATDIR}" == "S1" ] && [ "${S1MODE}" == "WIDESWATH" ] && [ "${ZOOM}" != "1" ] 
		then
			MASTERPOLNAME=${MASNAME}.Z.${MASPOL}
			SLAVEPOLNAME=${SLVNAME}.interpolated.Z.${SLVPOL}			 
		else 
			MASTERPOLNAME=${MASNAME}.${MASPOL}
			SLAVEPOLNAME=${SLVNAME}.${SLVPOL}		
	fi
		EchoTee " Compute amplitude image of Primary Zoomed x ML"

		# May not want to keep these files 
		if [ -e ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.ras ] ; then mv ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.beforeInSAR.ras ; fi
		if [ -e ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.ras ] ; then mv ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.beforeInSAR.ras ; fi
		if [ -e ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.ras.sh ] ; then mv ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.ras.sh ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.beforeInSAR.ras.sh ; fi
		if [ -e ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.ras.sh ] ; then mv ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.ras.sh ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.beforeInSAR.ras.sh ; fi

		MASX=`GetParamFromFile "Reduced master amplitude image range dimension [pix]" InSARParameters.txt`
		MASY=`GetParamFromFile "Reduced master amplitude image azimuth dimension [pix]" InSARParameters.txt`
		SLVX=`GetParamFromFile "Reduced slave amplitude image range dimension [pix]" InSARParameters.txt`
		SLVY=`GetParamFromFile "Reduced slave amplitude image azimuth dimension [pix]" InSARParameters.txt`
		INCIDX=`GetParamFromFile "Interferometric products range dimension" InSARParameters.txt`
		INCIDY=`GetParamFromFile "Interferometric products azimuth dimension" InSARParameters.txt`

		if [ ${MASX} != ${SLVX} ] || [ ${MASY} != ${SLVY} ] 
			then 
				EchoTeeRed "  // Amplitude reduced image size not the same for Primary and Secondary ??? Please check"
				EchoTee "MASX is ${MASX} and SLVX is ${SLVX}"
				EchoTee "MASY is ${MASY} and SLVY is ${SLVY}"
				exit 0
		fi

		if [ ${INCIDX} != ${MASX} ] || [ ${INCIDY} != ${MASY} ] 
				then 
					EchoTeeRed "  // Interferometric products size not the same as reduced Primary and Secondary ??? Please check"
					exit 0
		fi

		HEADINGDIRFULL=`updateParameterFile ${RUNDIR}/i12/TextFiles/masterSLCImageInfo.txt "Heading direction"`
		HEADINGDIR=`echo ${HEADINGDIRFULL} | cut -d " " -f 1`
		EchoTee "Satellite is ${HEADINGDIR}."

		case ${HEADINGDIR} in
				"Ascending")   
						   #SAT_ORBITS_IMAGE_DIRECTION="-flip" ;; # if ascending we need to flip it vertically
						   FLP=flip
						   	FLIPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod ${MASY} 
						   	FLIPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod ${SLVY}
						   	FLIPproducts.py.sh ${RUNDIR}/i12/InSARProducts/incidence ${INCIDY} 
						   if [ ${CALIBSIGMA} == "SIGMAYES" ] && [ ${SATDIR} == "S1" ] ; then 
								FLIPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0 ${MASY} 
								FLIPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0 ${SLVY}				   
						   fi ;;
				"Descending") 
						   #SAT_ORBITS_IMAGE_DIRECTION="-flop" ;; # if descending we need to flop it (horizontally)
						   FLP=flop
						   FLOPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod ${MASY}
						   FLOPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod ${SLVY}
						   FLOPproducts.py.sh ${RUNDIR}/i12/InSARProducts/incidence ${INCIDY} 
						   if [ ${CALIBSIGMA} == "SIGMAYES" ] && [ ${SATDIR} == "S1" ] ; then 
								FLOPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0 ${MASY} 
								FLOPproducts.py.sh ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0 ${SLVY}				   
						   fi ;;
			esac

		case ${SATDIR} in 
			"ENVISAT")
				MakeFig ${MASX} 1.0 2.0 normal gray 1/5 r4 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}
				MakeFig ${SLVX} 1.0 2.0 normal gray 1/5 r4 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP} ;;
			"S1")
				if [ "${S1MODE}" == "WIDESWATH" ] ; then MLS1FIG=4 ; else MLS1FIG=1 ; fi
				MakeFig ${MASX} 1.0 1.5 normal gray ${MLS1FIG}/1 r4 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}
				MakeFig ${SLVX} 1.0 1.5 normal gray ${MLS1FIG}/1 r4 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP} 
				#MakeFig ${MASX} 1.0 1.5 normal gray 1/1 r4 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}
				#MakeFig ${SLVX} 1.0 1.5 normal gray 1/1 r4 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP} 
				if [ ${CALIBSIGMA} == "SIGMAYES" ] ; then 
					MakeFig ${MASX} 1.0 1.0 normal gray ${MLS1FIG}/1 r4 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}
					MakeFig ${SLVX} 1.0 1.0 normal gray ${MLS1FIG}/1 r4 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP} 			   
				fi
				;;
			*)
				MakeFig ${MASX} 1.0 2.0 normal gray 1/1 r4 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}
				MakeFig ${SLVX} 1.0 2.0 normal gray 1/1 r4 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP} ;;
		esac

	# HEADERS
		EchoTee " Create headers for amplitude image of Primary and Secondary Zoomed x ML \n"	
		ORIGINALPROJ=${PROJ}
		PROJ=""
		CreateHDR ${MASX} ${MASY} 4 1 1 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}
		CreateHDR ${SLVX} ${SLVY} 4 1 1 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}
		CreateHDR ${INCIDX} ${INCIDY} 4 1 1 ${RUNDIR}/i12/InSARProducts/incidence.${FLP}
		 if [ ${CALIBSIGMA} == "SIGMAYES" ] && [ ${SATDIR} == "S1" ] ; then 
				CreateHDR ${MASX} ${MASY} 4 1 1 ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP} 
				CreateHDR ${SLVX} ${SLVY} 4 1 1 ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}				   
		 fi

		# Finish createing headers, can get the projection to its real value if needed further
		PROJ=${ORIGINALPROJ}

	# create jpg -  - flip for ease of comparison between modes
	# Date label in lower left corner
	#DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate +5+10 "

	# Date label close to Nyigo crater for NyigoAsc (attention Y position is given as Max-position measured in GraphicConverter for instance) 
	# Font 12 e.g. for S1
	#DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate"
	# Larger font for Ultra fine resoution images 
	#DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate"
	SinglePairNoUnwrapDATECELL
#    case ${TRKDIR} in
#        "RS2_UF_Asc") 
#     		DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
#         "RS2_F2F_Desc") 
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
#        "Virunga_Asc")  # for CSK
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
#        "Virunga_Desc")  # for CSK
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
#        "PF_SM_A_144")  # for S1 Pdf
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 2400 -fill black -annotate" ;;
#        "PF_SM_D_151")  # for S1 Pdf
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 2400 -fill black -annotate" ;;	 
#        *) 
#         	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate" ;;
#     esac
	
	if [ "${LABELX}" == "" ] # i.e. suppose you want to change the default label posirtion in jpg mod image
		then 
			POSDATECELL=" +5+10 "
		else 
			POSDATECELL=" +${LABELX}+${LABELY} "
	fi
	EchoTee "Making jpg files out of FullRes Sun rasters  \n"

	if [ "${SATDIR}" == "S1" ] ; then
		# S1 are huge and if jpg size is too small, pix are averaged and unusable for quick look
		SLVSHORT=`echo "${SLV}" | cut -d "_" -f 3`
		#/opt/local/bin/convert -format jpg -quality 100% -sharpen 0.1 -resize '10640>' ${DATECELL}${POSDATECELL} "${MAS}" ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.jpg 2> /dev/null
		#/opt/local/bin/convert -format jpg -quality 100% -sharpen 0.1 -resize '10640>' ${DATECELL}${POSDATECELL} "${SLVSHORT}" ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.jpg 2> /dev/null
		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}_temp.jpg 2> /dev/null
		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}_temp.jpg 2> /dev/null
	 	if [ ${CALIBSIGMA} == "SIGMAYES" ] ; then 
	 		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}_temp.jpg 2> /dev/null
	 		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}_temp.jpg 2> /dev/null
	 	fi 
		else
		SLVSHORT=${SLV}
		#/opt/local/bin/convert -format jpg -quality 100% -sharpen 0.1 -resize '2640>' ${DATECELL}${POSDATECELL} "${MAS}" ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.jpg 2> /dev/null
		#/opt/local/bin/convert -format jpg -quality 100% -sharpen 0.1 -resize '2640>' ${DATECELL}${POSDATECELL} "${SLV}" ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.jpg 2> /dev/null
		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '2640>' ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}_temp.jpg 2> /dev/null
		${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '2640>' ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}_temp.jpg 2> /dev/null
	fi
	# print tag after convertion to avoid saturation
	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${MAS}" ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}.jpg 2> /dev/null
	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${SLVSHORT}" ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.jpg 2> /dev/null
	rm ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.mod.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}_temp.jpg

	 if [ ${CALIBSIGMA} == "SIGMAYES" ] && [ ${SATDIR} == "S1" ] ; then 
	 	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${MAS}" ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}.jpg 2> /dev/null
	 	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${SLVSHORT}" ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}.jpg 2> /dev/null
	 	rm ${RUNDIR}/i12/InSARProducts/${MASTERPOLNAME}.sigma0.${FLP}_temp.jpg ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.sigma0.${FLP}_temp.jpg
	 fi


EchoTee "--------------------------------------------------------"
EchoTee "Dump script ${PRG} in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 

if [ -e  $(dirname $0)/${PRG} ] 
	then 
		cat $(dirname $0)/${PRG} >> ${LOGFILE} 			# If does not exist it is most probably becaused used from another script
	else
		cat ${PROPATH}/${PRG}  >> ${LOGFILE} 			# This is needed for MultiLaunch.sh
fi
EchoTee "" 

EchoTee "--------------------------------------------------------"
EchoTee "Dump Functions related to script in ${LOGFILE} for debugging " 
EchoTee "--------------------------------------------------------" 
cat ${FCTFILE} >> ${LOGFILE}
EchoTee "" 	

if [ "${SATDIR}" == "S1" ] ; then rm -f ${FLAGUSAGE} ; fi

SpeakOut " ${SATDIR}, ${TRKDIR}. Hope it worked."
if [ ! -s ${PATHINTERF} ] 
	then 
		SpeakOut " Interferogram seems wrong"
		xattr -wx com.apple.FinderInfo "0000000000000000000C00000000000000000000000000000000000000000000" ${RUNDIR} 		
fi

# done
