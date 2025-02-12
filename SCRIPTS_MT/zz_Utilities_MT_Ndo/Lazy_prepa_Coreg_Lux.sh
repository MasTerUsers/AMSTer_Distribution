#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at coregistrating all modes of LUX
# -----------------------------------------------------------------------------------------
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# prepare sets
Lazy_prepa_msbas_all_sets_andPlotBaselines_Lux.sh &

wait

# Make coregs 
for i in `seq 1 6`
do
	
	case $i in
		1) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_15/LaunchMTparam_S1_LUX_A_15_Zoom1_ML4_Coreg.txt FORCE"'"
			end tell' ;;
		2) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_88/LaunchMTparam_S1_LUX_A_88_Zoom1_ML4_Coreg.txt FORCE"'" 
			end tell' ;;
		3) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_161/LaunchMTparam_S1_LUX_A_161_Zoom1_ML4_Coreg.txt FORCE"'"
			end tell' ;;
		4) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_37/LaunchMTparam_S1_LUX_D_37_Zoom1_ML4_Coreg.txt FORCE"'"
			end tell' ;;
		5) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_66/LaunchMTparam_S1_LUX_D_66_Zoom1_ML4_Coreg.txt FORCE"'"
			end tell' ;;
		6) 
			osascript -e 'tell app "Terminal"
			do script "SuperMasterCoreg.sh '"/Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_139/LaunchMTparam_S1_LUX_D_139_Zoom1_ML4_Coreg.txt FORCE"'"
			end tell' ;;
	esac		
done

# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_15/LaunchMTparam_S1_LUX_A_15_Zoom1_ML4_Coreg.txt FORCE
# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_88/LaunchMTparam_S1_LUX_A_88_Zoom1_ML4_Coreg.txt FORCE
# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_A_161/LaunchMTparam_S1_LUX_A_161_Zoom1_ML4_Coreg.txt FORCE
# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_37/LaunchMTparam_S1_LUX_D_37_Zoom1_ML4_Coreg.txt FORCE
# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_66/LaunchMTparam_S1_LUX_D_66_Zoom1_ML4_Coreg.txt FORCE
# /Users/doris/PROCESS/SCRIPTS_MT/SuperMasterCoreg.sh /Volumes/hp-1650-Data_Share1/Param_files_SuperMaster/S1/LUX_D_139/LaunchMTparam_S1_LUX_D_139_Zoom1_ML4_Coreg.txt FORCE



