#!/bin/bash
######################################################################################
# This script interactively install MasTer Toolbox on a Mac or Linux computer. 
# You will need your admin password and answer a lot of questions. Read carefully. 
#
# Structure of the script:
#
# At Full installation:
#	- definition of several functions
#	- Warning to the user to erase old versions of MasTer config in bashrc to avoid problems
#	- Checks Operating System and its version
#	- Creates directories where MasTer components will be installed (${HOMEDIR}/SAR)
#	- offers a full installation, or an update (mostly msbas, MasTerEngine and SCRIPTS)
#	- check bashrc and bash_profile
#	- Offer to update apt or ports depending on the OS 
#	- Offer to Install some optional stuffs : 
#		+ Gitkraken
#		+ GIMP
#	- Offer to Install mandatory (or highly recommanded) stuffs : 
#		+ gmt and gdal
#		+ gnu fortran
#		+ gnu functions (gawk, gsed, coreutils, wget, curl etc...)
#		+ Libraries for software compilation 
#		+ Java
#		+ Fiji/ImageJ
#		+ snaphu
#		+ cpxfiddle
#		+ gnuplot
#		+ python version 3
#		+ QGIS
#	- In addition for linux users: x-terminal-emulator 
#	- In addition for mac users: Xcode 
#
# For update only (and full installation of course):
#	- MasTerEngine
#	- msbas + extract tools
#	- MasTer Toolbox, ie. SCRIPTS
# 
# And in any case, if not done yet:
# - check and adapt all path in bashrc for making these directories executables:
#		+ PATHGNU			(one of the most important one...)
#		+ /opt/local/bin 	(mandatory for calling python scripts)
#		+ SCRIPTS directory and its subdirectories  
#		+ MasTerEngine directory and its subdirectories
#		+ MSBAS 
#		+ EXEC 				(where several usefull stuffs will be added and)
#		+ curl 				(to prevent any fancy error)
# - define the necessary state variables in bashrc:
#		+ PATHTOCPXFIDDLE
#		+ PATHGNU
#		+ PATHFIJI
#		+ PATHCONV
#		+ PATH_SCRIPTS
#		+ S1_ORBITS_DIR
#		+ ENVISAT_PRECISES_ORBITS_DIR
#		+ EARTH_GRAVITATIONAL_MODELS_DIR
# - define the necessary path or mounting points for mandatory dirs/disks:
#		+ DataSAR 	(MANDATROY: i.e. disk/dir where ancillary data will be stored like orbits or geoid...)
#		+ 1650		(MANDATROY: 1 or the 4 common disks/dir where data, intermediate results and final results will be stored)
#		+ 3600		(MANDATROY: 1 or the 4 common disks/dir where data, intermediate results and final results will be stored)	
#		+ 3601		(MANDATROY: 1 or the 4 common disks/dir where data, intermediate results and final results will be stored)		
#		+ 3602		(MANDATROY: 1 or the 4 common disks/dir where data, intermediate results and final results will be stored)		
#		Note : these 4 variables for the 4 disks may have other names but you will spare a lot of time by keeping these stupid variable names... 
#		+ HOMEDATA	(OPTIONAL; useful in case of internal hard drive)
#		+ SynoData 	(OPTIONAL; you can of course define as much additional disks as wished/needed by changing the script accordingly)
#
# - add some specific things e.g. to prepare the script to limit the nr of CPU during parallel processing of msbas if needed, or avoid errror messages in case of specific installations 
# - create, if not done yet, the MANDATORY directories to store required ancillary data (DEM, ORBITS and GEOID)
# - tell a warning for the linux users that would need to run cronjobs... because default bashrc may hide tricky lines that need to be commented 
# - download the S1 presice orbit (from scratch or from chosen date)
# - offers to reboot to source the bashrc for all Terminals to be open.. 
#
#
# NOTE: it sources the .bashrc each time it modifies in order to take into account possible variables that would be already defined when defninig new ones during the installation process. 
#
# Parameters : - none
#
# Dependencies:	- none
#
# New in 1.1:	- add x-terminal-emulator for linux
#			 	- check apt and ports and offer altenratives if it does not exist
#				- chack last version of available apt and ports
# New in 1.2:	- remove call $PATHGNU/gsed
#				- cd in SAR/EXEC before changing line for Linux
#				- properly unzip SCRIPTS in SCRIPTS_MT
#				- install gitkraken with snap 
#				- avoid using ${HOMEDIR} which seems a problem in some cases
#				- optional definition of EXTERNAL_DEMS_DIR
# New in 1.3:	- Search manual installation of GitKraken and QGIS for mac as well
# New in 2.0:	- change installation dir as MasTerToolbox	
#				- improve procedure for installing MasTerEngine	
# 				- improve questions display
#				- allows skip by pressing n
#				- allows autocompletion while using read command
# 				- get/ask home dir to avoid possible problems with tilde and $Home
#				- keep installed sources in EXEC/Installed_Sources rather than rm them  
# New in 2.1:	- correct  EARTH_GRAVITATIONAL_MODELS_DIR and ENVISAT_PRECISES_ORBITS_DIR
# New in 2.2:	- download goid in proper dir
#				- ensure starting in HOME dir
# New in 2.3:	- check that make is installed for Linux computers
#				- force using clang14 on Mac (mandatory for parallel processing)
#				- proper check of Mac gnuplot install 
#				- setup compilation of msbas 
# New in 2.4:	- typo AptInstalll removed
#				- add new libraries needed for msbas 
#				- keep snaphu source in Sources_Installed 
# New in 2.5:	- link gnu du
#				- revised optimisation for msbas using openblas for Linux. Set OPENBLAS_NUM_THREADS to 1
#				- change ImageMagick policy domain rights to read/write also for EPS 
#				- install java developpment kit (jdk, that also install jde) from apt or MacPorts
# New in 2.6:	- make for msbas_extract was missing...  
#				- add several comments for installation (eg. in cas of problem with DISPLAY)
# New in 2.7:	- clang was missing for Linux installation
# New in 2.8:	- Test DISPLAY before testing x-terminal-emulator
#				- change policy.xml for ImageMagick to allow large image processing
#				- add install gzip pour ubuntu 
# New in 2.9:	- typo /dev/null 
#				- create EXTERNAL_DEMS_DIR if needed
# New in 2.10:	- add MasTer Toolbox organizer 
# 				- Rename _Sources_ME dir
# New in 2.11:	- typos in several remarks 
# New in 2.12:	- add gnu parallel
#				- typo PortInstall instead of PortInsatll
# New in 2.13:	- also increase max width image size in Linux for ImageJ 
# New in 2.14:	- debug symbolic link to g-functions in Linux
#				- to avoid possible problem while sourcing bashrc, recompute OS after each source
# New in 2.15:	- install msbas version Optimized_v1.1_Gilles, that is using g++ instaed of clang
# New in 2.16:	- add module optimisation
#				- Linux libgdal30 instead of libgdal26
# New in 2.17:	- Define path to MasTer Toolbox scripts in the right order (do not change it!)
#				- test Mac OSX bash at the beginning just in case 
# New in 3.00:	- Change fct to search for existing PATH in .bashrc (in UpdatePATHBashrcAFTER). Now can change order or search
#				- use PATHGNU/sed in every fct
#				- compile sources for MasTer Engine
#				- Check all type of compressed msbas versions 
#				- linux was installing GitKraken from snap & apt
#				- ask where MasTerToolbox_Distribution is stored
#				- check msbas version till v20
#				- allows installing msbasv10 (need mpich) 
#				- reclaim old ports
#				- offer to install more disks (for ECGS needs)
#				- update DOC from Distribution and store at right place (in MasTerToolbox)
# New in 3.01:	- In Mac, search for Figi* and QGIS* instead of Fiji.app and Fiji.app because old OSX had no .app extension 
# New in 3.02:	- Linux: remove DISPLAY definition as it may prevent usage of __SplitSession.sh or __SplitCoerg.sh
#				- Linux: more robust search of DISPLAY values
# New in 3.03:  - was not escaping the DISPLAY selection loop
# New in 3.04:  - improve search/display for GitKralen version in Mac
#				- debug getting directory where MasTer Toolbox sources are stored 
#				- more robust way to get GIMP version with Mac OSX 
#				- show Fiji version when available with Mac OSX
# New in 3.05:  - add gsl libraries for Mac and Linux
# New in 3.06:  - When OS was Linux, it was offering to change Zsh...
# New in 3.07:  - Allows option for compilation ME with parallelisation 
# New in 3.08:  - Use new makefile with variable for parallelisation  
# New in 3.09:  - manage the parallelisation option as requested from MasTerEngine V20230826
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v Beta 1.0 2022/08/31 -                         
######################################################################################
PRG=`basename "$0"`
VER="version 4.0 - Interactive Mac/Linux installation of MasTer Toolbox"
AUT="Nicolas d'Oreye', (c)2020, Last modified on Aug 30 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

clear
echo

############
# Check OS #
############
OS=`uname -a | cut -d " " -f 1 `

TSTSH=`echo "$SHELL"`
if [ "${OS}" == "Darwin" ] 
	then 
		if [ "${TSTSH}" == "/bin/bash" ] 
			then 
				echo " // Your OS is probably older than v 10.15 or shell was already changed to bash. No action required. "
			else	
				echo " // Your OS is probably v 10.15 or more recent. Need to change default shell Zsh with bash for scripts compatibility issues. "
				chsh -s /bin/bash 	
				echo " // It will only be effective in a new Terminal, hence close the present Terminal and relaunch the prensent script in that new terminal"
				exit
		fi
fi
				

eval RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm%Ss" | sed "s/ //g"`


##########################################################
# Define variables to display echo on reverse background #
##########################################################

smso=$(tput smso)
rmso=$(tput rmso)

####################
# Define functions #
####################

function EchoInverted()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo "${smso}${MESSAGE}${rmso}"
	}

function AptInsatll()
	{
	unset APTNAME
	unset NEWAPTNAME
	local APTNAME=$1

	TSTEXISTAPT=`apt show ${APTNAME} 2>/dev/null | wc -w`
	if [ "${TSTEXISTAPT}" == "" ] 
		then 
			#apt does not exist; search for similar
			echo "  // Sorry, can't find your apt. " 
			echo "    Here is however the list of similar apt I can find:"
			FIRSTAPT=`echo ${APTNAME} | cut -d " " -f 1 `
			apt search --names-only ${FIRSTAPT}  
			while true; do
				read -p "Do you want to install one of those (similar) ones ?  [y/n] "  yn
				case $yn in
					[Yy]* ) 
						echo
						echo "  // OK, let's try. "
						read -e -p "Enter the exact name of apt to install (DO NOT FORGET DEPENDENCES IF ANY and frame them within quotes):  "  NEWAPTNAME
						sudo apt install "${NEWAPTNAME}"
						break ;;
					[Nn]* ) 
						echo
						echo "  // OK, you know... "
						break ;;
					* ) 
						echo "Please answer [y]es or [n]o.";;
				esac
			done
		else 
			#apt exists ; install it
			sudo apt install ${APTNAME}
	fi
	}
	
function CheckLastAptVersion()
	{
	unset APTNAME
	local APTNAME=$1	
	# Last version of apt available online 
	echo "  // The last version available seems to be : "
	apt show ${APTNAME} 2>/dev/null | grep Version
	}

function PortInstall()
	{
	unset PORTNAME
	unset NEWPORTNAME
	local PORTNAME=$1

	TSTEXISTPORT=`port search ${PORTNAME} 2>/dev/null | wc -l`
	if [ ${TSTEXISTPORT} -le 1 ] 
		then 
			#port does not exist; search for similar
			echo "  // Sorry, can't find your port. " 
			echo "    Here is however the list of similar port I can find:"
			#take only 1st name in port name
			FIRSTPORT=`echo ${PORTNAME} | cut -d " " -f 1 `
			port search ${FIRSTPORT}  
			while true; do
				read -p "Do you want to install one of those (similar) ones ?  [y/n] "  yn
				case $yn in
					[Yy]* ) 
						echo
						echo "  // OK, let's try. "
						read -e -p "Enter the exact name of port to install (DO NOT FORGET DEPENDENCES IF ANY and frame them within quotes):  "  NEWPORTNAME
						sudo port install ${NEWPORTNAME}
						break ;;
					[Nn]* ) 
						echo
						echo "  // OK, you know... "
						break ;;
					* ) 
						echo "Please answer [y]es or [n]o.";;
				esac
			done
		else 
			#port exists ; install it
			sudo port install ${PORTNAME}
	fi
	}

function CheckLasPortVersion()
	{
	unset PORTNAME
	local PORTNAME=$1	
	# Last version of apt available online 
	echo "  // The last version available seems to be : "
	port search --exact ${APTNAME} 2>/dev/null | head -1
	}




function AskExternalComponent()
	{
		local COMPONENT
		local LOCATION
		
		COMPONENT=$1
		LOCATION=$2
		
		cd ${HOMEDIR}/SAR/EXEC
		read -e -p "Enter the name of the source file (without path!) downloaded from ${LOCATION} and that you stored in ${HOMEDIR}/SAR/EXEC. You can use Tab for autocompletion: " RAWFILE
			
		while true ; do
		read -p  "Press [y] if you want to use it or [s] to skip [y/s]" ys
			case $ys in
				[Yy]* ) 
					echo "  // OK, I will try to install it."
					echo "  // I will try to use ${HOMEDIR}/SAR/EXEC/${RAWFILE}"
					SKIP="No"
					break ;;
				[Ssn]*)
					echo "  // OK, you know..." 
					SKIP="Yes"
					break ;;
				* ) 
					echo "Please answer [y]es when done or [s]kip." ;;
			esac
		done
	}

function AskDistroComponent()
	{
		local COMPONENT
		local LOCATION
		
		COMPONENT=$1
		LOCATION=$2

		cd ${PATHDISTRO}/${COMPONENT}_sources
		read -e -p "Enter the name of the ${COMPONENT} source file (without path!) downloaded from ${LOCATION}. It must be in ${PATHDISTRO}/${COMPONENT}_sources. You can use Tab for autocompletion: " RAWFILE
			
		while true ; do
		read -p  "Press [y] if you want to use it or [s] to skip [y/s]" ys
			case $ys in
				[Yy]* ) 
					echo "  // OK, I will try to install ${COMPONENT} using "
					echo "  // ${PATHDISTRO}/${COMPONENT}_sources/${RAWFILE}"
					SKIP="No"
					break ;;
				[Ssn]*)
					echo "  // OK, you know..." 
					SKIP="Yes"
					break ;;
				* ) 
					echo "Please answer [y]es when done or [s]kip." ;;
			esac
		done
	}


function SearchForSimilar()
	{
		RAWFILE=$1
		FILETOINSTALL=$2
		
		if [ ! -f ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ]
			then
				while true; do
					read -p "I cant find ${RAWFILE} in ${HOMEDIR}/SAR/EXEC/ but I found ${FILETOINSTALL}. Can I use it ? [y/n] "  yn
					case $yn in
					[Yy]* ) 
						echo "  // OK, I will try to install it."
						RAWFILE=$(basename ${FILETOINSTALL})
						break
						;;
					[Nn]*)
						echo "  // OK, then start again the installation and provide me with the good file. " 
						exit
						;;
					* ) 
						echo "Please answer [y]es or [n]o.";;
					esac
				done
		fi 
	}

function InsertBelowVARIABLESTitle()
	{
		local EXPECTED
		local TSTTITLE
		local TEST
		local EXPECTEDCLN
		EXPECTED=$1

		# Replace $ by \$ in EXPECTED
		EXPECTEDCLN=`echo ${EXPECTED} | sed 's%$%\$%g'`
		
		# Back it up first if not done yet
		if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi
	
		# Check if variable exist in /.bashrc
		TEST=$(grep "${EXPECTEDCLN}" ${HOMEDIR}/.bashrc)
		if [ `echo "${TEST}" | wc -w` -eq 0 ]  
			then 
				# Check if # MasTer VARIABLES exists
				TSTTITLE=$(grep "# MasTer VARIABLES" ${HOMEDIR}/.bashrc)
				if [ `echo "${TSTTITLE}" | wc -w` -eq 0 ]  
					then
						echo "  // No section named # MasTer VARIABLES exists in /.bashrc. Let's create it and add the variable after"	
						sudo echo "" >> ${HOMEDIR}/.bashrc
						sudo echo "# MasTer VARIABLES" >> ${HOMEDIR}/.bashrc
						sudo echo "##################" >> ${HOMEDIR}/.bashrc
						sudo echo "" >> ${HOMEDIR}/.bashrc
						sudo echo "${EXPECTED}" >> ${HOMEDIR}/.bashrc
					else
						echo "  // Let's add the variable after the section named # MasTer VARIABLES in /.bashrc. "
						TITLEPOS=`grep -n "# MasTer VARIABLES" ${HOMEDIR}/.bashrc | cut -d : -f 1 | head -1`
						WHERETOINSTERT=`echo "${TITLEPOS} + 3" | bc -l`
						sudo ${PATHGNU}/sed -i ''"${WHERETOINSTERT}"' i '"${EXPECTED}"'' ${HOMEDIR}/.bashrc
				fi
			else 
				echo "  // ${EXPECTED} already in /.bashrc. "
		fi
		
		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
	}

function InsertBelowPATHTitle()
	{
		local STRINGTOSEARCH
		local TSTTITLE
		STRINGTOSEARCH=$1

		# Back it up first if not done yet
		if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi
		
		# Check if # MasTer VARIABLES exists
		TSTTITLE=$(grep "# MasTer PATHS" ${HOMEDIR}/.bashrc)
		if [ `echo "${TSTTITLE}" | wc -w` -eq 0 ]  
			then
				echo "  // No section named # MasTer PATHS exists in /.bashrc. Let's create it and add the variable after"	
				sudo echo "" >> ${HOMEDIR}/.bashrc
				sudo echo "# MasTer PATHS" >> ${HOMEDIR}/.bashrc
				sudo echo "##################" >> ${HOMEDIR}/.bashrc
				sudo echo "" >> ${HOMEDIR}/.bashrc
				sudo echo "PATH=\$PATH:${STRINGTOSEARCH}" >> ${HOMEDIR}/.bashrc 
			else
				echo "  // Let's add the variable after the section named # MasTer PATHS in /.bashrc. "
				TITLEPOS=`grep -n "# MasTer PATHS" ${HOMEDIR}/.bashrc | cut -d : -f 1 | head -1`
				WHERETOINSTERT=`echo "${TITLEPOS} + 3" | bc -l`
				sudo ${PATHGNU}/sed -i ''"${WHERETOINSTERT}"' i PATH=\$PATH:'"${STRINGTOSEARCH}"'' ${HOMEDIR}/.bashrc

				# to avoid problem of interpreting search and replace, do it in two steps
				#sudo sed -i ''"${WHERETOINSTERT}"' i PATH=\$PATH:STRINGTOREPLACEATNEXTLINEAFTERTITLE' ${HOMEDIR}/.bashrc
				#sudo sed -i "s%STRINGTOREPLACEATNEXTLINEAFTERTITLE%${STRINGTOSEARCH}%" ${HOMEDIR}/.bashrc
		fi

		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
	}

function UpdateVARIABLESBashrc()
	{
		local STRINGTOSEARCHIN
		local STRINGTOSEARCH
		local EXPECTED
		local TST
		local EXPECTEDCLN
		local TEST1
		local TEST2
		
		STRINGTOSEARCHIN=$1
		EXPECTED=$2

		TST=$(grep "export ${STRINGTOSEARCHIN}" ${HOMEDIR}/.bashrc )
		if [ `echo "${TST}" | wc -w` -eq 0 ] 
			then 
				STRINGTOSEARCH=${STRINGTOSEARCHIN}
				echo "  // /.bashrc does not contain ${smso}${EXPECTED}${rmso} yet. Add it now (former /.bashrc was saved in /.bashrc_${RUNDATE}). "

				# Back it up first if not done yet
				if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

				InsertBelowVARIABLESTitle "${EXPECTED}"
				echo
			else 
				for STRINGTOSEARCH in `grep "export ${STRINGTOSEARCHIN}" ${HOMEDIR}/.bashrc | cut -d t -f 2 | sort | uniq` 		# for multiple occurrence of an exported variable in bashrc, take only one run. Search for string after expor[t] 
				do 
					TST=$(grep "export ${STRINGTOSEARCH}" ${HOMEDIR}/.bashrc )
					if [ "${TST}" == "${EXPECTED}" ] 
						then 
							echo "  // /.bashrc does contain ${STRINGTOSEARCH} as ${smso}${EXPECTED}${rmso}. OK "
						else 
							while true; do
							read -p "Your .bashrc contains the variable ${smso}${TST}${rmso} and you expected ${smso}${EXPECTED}${rmso}. Are you satified ? [y/n] "  yn
								case $yn in
									[Yy]* ) 
										echo "  // OK, I keep it like that." 
										break ;;
									[Nn]* ) 
										while true ; do
										read -p "Do you want to ADD it manually at the end of your .bashrc (the former can be deleted just after if desired) ? [y/n] "  yn
											case $yn in
												[Yy]* ) 
													read -p "Enter the declaration of your state variable (something like: export VARNAME=VALUE) : " DECLAREVAR
													
													# Check again if variable exist in /.bashrc

													# Replace $ by \$ in EXPECTED just in case...
													EXPECTEDCLN=`echo ${DECLAREVAR} | sed 's%\$%\\$%g'`
													TEST1=$(grep "${DECLAREVAR}" ${HOMEDIR}/.bashrc | grep -v ":")
													TEST2=$(grep "${EXPECTEDCLN}" ${HOMEDIR}/.bashrc)
													if [ `echo "${TEST1}" | wc -w` -eq 0 ] && [ `echo "${TEST2}" | wc -w` -eq 0 ] 
														then 
															InsertBelowVARIABLESTitle "${DECLAREVAR}"
													fi		
																						
													while true ; do
													read -p "Do you want to delete the former ${smso}${TST}${rmso} from .bashrc) ? [y/n] "  yn
														case $yn in
															[Yy]* ) 
																# Back it up first if not done yet
																if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

																grep -v "${TST}"  ${HOMEDIR}/.bashrc >  ${HOMEDIR}/.bashrc_tmp
																cp -f  ${HOMEDIR}/.bashrc_tmp  ${HOMEDIR}/.bashrc
																rm -f ${HOMEDIR}/.bashrc_tmp
																break ;;
															[Nn]* )
																echo " // OK, you know"
																break ;;
															* )
																echo "  // Answer [y]es or [n]o." ;;
														esac
													done	
													break ;;
												[Nn]* )
													echo "  // OK, then edit manually your /.bashrc as you want" 
													break ;;
												* )
													echo "  // Answer [y]es or [n]o." ;;
											esac
										done
										break ;;
									* ) 
										echo "  // Answer [y]es or [n]o." ;;
								esac
							done
					fi	
				echo	
				done
			fi
		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
		echo
	}

function UpdatePATHBashrcBEFORE()
	{
		local STRINGTOSEARCH
		local TST
		local OCCUR
		
		STRINGTOSEARCH=$1
				
		TST=$(grep "PATH=" ${HOMEDIR}/.bashrc)

		if [ `echo "${TST}" | wc -w` -eq 0 ] 
			then 
				echo "  // /.bashrc does not contain PATH yet. Add it now (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
				echo "  // and add ${smso}${STRINGTOSEARCH}${rmso}"
				# Back it up first if not done yet
				if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi
						
				sudo echo "PATH=${STRINGTOSEARCH}:\$PATH" >> ${HOMEDIR}/.bashrc 
			else 
				TST=$(grep "PATH=" ${HOMEDIR}/.bashrc | grep "${STRINGTOSEARCH}")
				
				if [ `echo "${TST}" | wc -w` -eq 0 ] 
					then 
					
						echo "  // /.bashrc already contains PATH though it does not contains ${smso}${STRINGTOSEARCH}${rmso}. Will add here new path BEFORE existing PATH (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
						# Back it up first if not done yet
						if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

						# add PATH=STRINGTOSEARCH:$PATH before the first line of bashrc	containing PATH=
						eval FIRSTPATH=$(grep -n "PATH=" ${HOMEDIR}/.bashrc | cut -d : -f1  | head -1)	# line nr of first PATH definition in bashrc
						
						# to avoid problem of interpreting search and replace, do it in two steps with a DUMMYSTRING

						sudo ${PATHGNU}/sed -i "${FIRSTPATH} i DUMMYSTRING" ${HOMEDIR}/.bashrc
						sudo ${PATHGNU}/sed -i "s%DUMMYSTRING%PATH=${STRINGTOSEARCH}:\$PATH%" ${HOMEDIR}/.bashrc

					
					else
					
						OCCUR=$(grep "PATH=" ${HOMEDIR}/.bashrc | grep -n "PATH=${STRINGTOSEARCH}" | cut -d : -f1  | head -1)	# check if exist at beginning of a PATH line 
						if [ "${OCCUR}" != "1" ] && [ "${OCCUR}" != "2" ]
							then 
								echo "  // /.bashrc already contains PATH with ${STRINGTOSEARCH}, though not on the 1st or 2nd but the ${OCCUR}th line of PATH. "
								echo "  // To avoid problem, lets add ${smso}${STRINGTOSEARCH}${rmso} on the 1st line of PATH (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
								# Back it up first if not done yet
								if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

								# add PATH=STRINGTOSEARCH:$PATH before the first line of bashrc	containing PATH=
								eval FIRSTPATH=$(grep -n "PATH=" ${HOMEDIR}/.bashrc | cut -d : -f1  | head -1)	# line nr of first PATH definition in bashrc

								# to avoid problem of interpreting search and replace, do it in two steps with a DUMMYSTRING
								sudo ${PATHGNU}/sed -i "${FIRSTPATH} i DUMMYSTRING" ${HOMEDIR}/.bashrc
								sudo ${PATHGNU}/sed -i "s%DUMMYSTRING%PATH=${STRINGTOSEARCH}:\$PATH%" ${HOMEDIR}/.bashrc

							else
								echo "  // OK, /.bashrc already contains PATH with ${STRINGTOSEARCH} on the ${OCCUR}st line of PATH. "
						fi
						
				fi
		fi
		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
		echo
	}
	
function UpdatePATHBashrcAFTER()
	{
		local STRINGTOSEARCH
		local TST
		local PATTERN	
			
		STRINGTOSEARCH=$1
		PATTERN="^PATH=${STRINGTOSEARCH}$"
	
		TST=$(grep "PATH=" ${HOMEDIR}/.bashrc)

		if [ `echo "${TST}" | wc -w` -eq 0 ] 
			then 
				echo "  // /.bashrc does not contain PATH yet. Add it now (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
				echo "  // and add ${smso}${STRINGTOSEARCH}${rmso}"
				
				#sudo echo "PATH=\$PATH:/${STRINGTOSEARCH}" >> ${HOMEDIR}/.bashrc 
				InsertBelowPATHTitle "${STRINGTOSEARCH}"
			else 
				while IFS= read -r line ; do
 					if [[ ${line} =~ ${PATTERN} ]]
 						then
    						echo "  // OK, /.bashrc already contains PATH with ${smso}${STRINGTOSEARCH}${rmso}. "
    						ADD="NO"
    						break
						else 
							ADD="YES"
  					fi
				done < ${HOMEDIR}/.bashrc
				
				if [ "${ADD}" == "YES" ] 
					then 
						echo "  // .bashrc already contains PATH though it does not contains ${smso}${STRINGTOSEARCH}${rmso}."
						echo "  //  Will add here new path AFTER existing PATH (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
						InsertBelowPATHTitle "${STRINGTOSEARCH}" 
					else 
						echo "  // No need to add it to PATH. " 
				fi
				ADD=""
				#TST=`grep "PATH=" ${HOMEDIR}/.bashrc | grep "${STRINGTOSEARCH}"`
				#if [ `echo "${TST}" | wc -w` -eq 0 ] 
				#	then 
				#		echo "  // /.bashrc already contains PATH though it does not contains ${smso}${STRINGTOSEARCH}${rmso}. Will add here new path AFTER existing PATH (former /.bashrc was saved in /.bashrc_${RUNDATE}). "
				#		
				#		#sudo sed -i '/.*PATH=.*/a PATH=\$PATH:\/'"${${STRINGTOSEARCH}}"' ' ${HOMEDIR}/.bashrc
				#		InsertBelowPATHTitle "${STRINGTOSEARCH}"
				#	else
				#		echo "  // OK, /.bashrc already contains PATH with ${smso}${STRINGTOSEARCH}${rmso}. "
				#fi
		fi
		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
		echo
	}

function NecessaryDisk()
	{
		local DISKNAME
		local EXAMPLE
		
		DISKNAME=$1
		EXAMPLE=$2
		
		TST=$(grep "export PATH_${DISKNAME}=" ${HOMEDIR}/.bashrc)
		if [ `echo "${TST}" | wc -w` -eq 0 ] 
			then 
				echo "  // 	   No ${DISKNAME} state varaibale defined yet to point toward a mounted disk. "
				echo "  // 	   Example: ${EXAMPLE}"
				while true; do
					read -p "Do you want to define a state variable ${smso}PATH_${DISKNAME}${rmso} now ? [y/n] "  yn
					case $yn in
					[Yy]* ) 
						echo "  // OK, I will add its mounting point or path here as a state variable."
						cd ${HOMEDIR}
						read -e -p "Enter the name of the mounting point (e.g. /mnt/YourDisk/PATH_TO/YOUR_DIR) or path (e.g. /users/your_account/PATH_TO/YOUR_DIR). You can use Tab for autocompletion: " DIRMOUNT
						if [ -d "${DIRMOUNT}" ]
							then 
								echo "  // OK, dir can be accessed. State variable defined in ./bashrc"
								UpdateVARIABLESBashrc "PATH_${DISKNAME}" "export PATH_${DISKNAME}=${DIRMOUNT}"
								break
							else 
								echo "  // Dir can NOT be accessed..."
								# ask to confirm or try again
								while true; do
									echo "Do you want to [e]nter again the mounting point or path,"
									echo "   or [s]kip this state variable and try later, or "
									echo "   or, if it is a mounting point, define it anyway and create the [m]ounting point later, "
									echo "   or, if it is a dir, define it anyway and create the [d]ir now ?"
									read -p "Select [e/s/m/d] "  des
									case $des in
									[Ee]* ) 
											read -e -p "Enter the name of the mounting point or path (will be added in the .bashrc as export PATH_${DISKNAME}=MOUNT_POINT_NAME). You can use Tab for autocompletion : " DIRMOUNT
											if [ -d "${DIRMOUNT}" ]
												then 
													echo "  // OK, dir can be accessed. State variable defined in /.bashrc"
													UpdateVARIABLESBashrc "PATH_${DISKNAME}" "export PATH_${DISKNAME}=${DIRMOUNT}"
													break
												else
													echo "  // Dir can still NOT be accessed... I give up here "
													echo "  // DO NOT FORGET TO DEFINE THE STATE VARIABLE ${DIRMOUNT} LATER !"
													break
											fi	
											;;
									[Ss]* ) 
											echo "  // DO NOT FORGET TO DEFINE THE STATE VARIABLE ${DIRMOUNT} LATER !"
											break
											;;
									[Mm]* ) 
											echo "  // DO NOT FORGET TO CREATE ${DIRMOUNT} LATER !"
											UpdateVARIABLESBashrc "PATH_${DISKNAME}" "export PATH_${DISKNAME}=${DIRMOUNT}"
											break
											;;
									[Dd]* ) 
											echo "  // OK, I define it now and try to create the directory"
											UpdateVARIABLESBashrc "PATH_${DISKNAME}" "export PATH_${DISKNAME}=${DIRMOUNT}"
											mkdir -p ${DIRMOUNT}
											if [ ! -d "${DIRMOUNT}" ] ; then echo "I can't create ${DIRMOUNT}. Please check your path !" ; exit ; fi
											break
											;;

									* )  
											echo "Please answer [d]efine, [e]nter or [s]kip.";;
									esac
								done
								break
						fi
				
						;;
					[Nn]*)
						if [ `grep "PATH_${DISKNAME}" ${HOMEDIR}/.bashrc | wc -w` -eq 0 ] 
							then
								echo "  // OK, you know... It seems that a state variable PATH_${DISKNAME} is already defined in /.bashrc:  "
								grep "PATH_${DISKNAME}" ${HOMEDIR}/.bashrc
								echo "  // OK, you know... " 
				
							else
								echo "  // OK, you know... You can do ot later but remember that MasTer will NOT work without it.  " 
						fi
						break
						;;
					* ) 
						echo "Please answer [y]es or [n]o.";;
					esac
				done
			else 
				echo "  // 	A ${DISKNAME} state varaibale is already defined to point toward a mounted disk: "
				MLUNTEDDISK=`grep "export PATH_${DISKNAME}=" ${HOMEDIR}/.bashrc`
				echo "  // 		${MLUNTEDDISK} "
				DISK=`grep "export PATH_${DISKNAME}=" ${HOMEDIR}/.bashrc | cut -d = -f 2 | sed 's/"//g'`
				if [ -d "${DISK}" ] 
					then 
						echo "  // and that disk ${DISK} is reachable. "
					else 
						echo "  // though that disk ${DISK} is NOT reachable. Please check its mounting point or path."		
				fi
		fi
		echo ""
		source ${HOMEDIR}/.bashrc
		OS=`uname -a | cut -d " " -f 1 `
	}

function InstallSnaphu()
	{
		EchoInverted "  // snaphu is mandatory for phase unwrapping. "
		while true; do
			read -p "Do you want to [c]heck, [i]nstall or [s]kip snaphu ? [c/i/s] "  cis
			case $cis in
			[Cc]* ) 	
				echo "  // OK, let's check its version. "
				SNAPHUVER=`snaphu 2>/dev/null | grep snaphu | head -1`
				if [ "${SNAPHUVER}" == "" ] 
					then 
						echo "snaphu seems not installed. "
						while true ; do
						read -p "Do you want to install it now [y]es or [n]o ? "  yn
							case $yn in
								[Yy]* ) 
									echo "  // OK, I will try to install it."
									AskExternalComponent "snaphu" "https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/ "
									if [ "${SKIP}" == "No" ] ; then 
										# just if there is a typo in the version, or name... hoping that at least the main name is OK					
										if [ ! -f  ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ] ; then 
											FILETOINSTALL=`find ${HOMEDIR}/SAR/EXEC/ -maxdepth 1 -type f -name "*snaphu*" 2>/dev/null`
											SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
										fi
										
										FILEXT="${RAWFILE##*.}"
 
										if [ "${FILEXT}" == "gz" ] || [ "${FILEXT}" == "tar" ] 
											then 
												tar -zxvf ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
												#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
												mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
												mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/
												SNAPHUSOURCEDIR=`find ${HOMEDIR}/SAR/EXEC/ -type d -name "*snaphu*"`
												cd ${SNAPHUSOURCEDIR}/src
												make
												mv ${SNAPHUSOURCEDIR}/bin/snaphu ${HOMEDIR}/SAR/EXEC/
												mv ${SNAPHUSOURCEDIR} ${HOMEDIR}/SAR/EXEC/Sources_Installed
												echo "  // "
											else 
												echo " Format not as expected (gz). May not be genuine file ? Please do manually"			
										fi
									fi
									break ;;
								[Nn]*)
									echo "  // OK, you know..." 
									break ;;
								* ) 
									echo "Please answer [y]es or [n]o." ;;
							esac
						done
					else 
						echo "${SNAPHUVER} is installed"
						echo "  // It is your responsability to verify that it is the last one though..."
						
				fi
				break ;;		
			[Ii]* ) 				
					echo "  // OK, I do it now."
					AskExternalComponent "snaphu" "https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/ "
					# just if there is a typo in the version, or name... hoping that at least the main name is OK					
 					if [ ! -f  ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ] ; then 
 						FILETOINSTALL=`find ${HOMEDIR}/SAR/EXEC/ -maxdepth 1 -type f -name "*snaphu*" 2>/dev/null`
 						SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
 					fi
 			
 					FILEXT="${RAWFILE##*.}"
 
					if [ "${FILEXT}" == "gz" ] || [ "${FILEXT}" == "tar" ]  
						then 
							cd ${HOMEDIR}/SAR/EXEC/
							tar -zxvf ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
							SNAPHUSOURCEDIR=`find ${HOMEDIR}/SAR/EXEC/ -type d -name "*snaphu*"`

							cd ${SNAPHUSOURCEDIR}/src
							make
							mv ${SNAPHUSOURCEDIR}/bin/snaphu ${HOMEDIR}/SAR/EXEC/
							#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
							mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
							mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/
							mv ${SNAPHUSOURCEDIR} ${HOMEDIR}/SAR/EXEC/Sources_Installed
							echo "  // "
						else 
							echo " Format not as expected (gz). May not be genuine file ? Please do manually"			
					fi
					break ;;
			[Ssn]* ) 
					echo "  // OK, I skip it."
					break ;;
				* )  
					echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
			esac
		done							
		echo ""	
	}

DoInstallCpxfiddle()
	{
		AskExternalComponent "cpxfiddle.cc" " https://github.com/TUDelftGeodesy/Doris/tree/master/sar_tools"
		if [ "${SKIP}" == "No" ] ; then 
			# just if there is a typo in the version, or name... hoping that at least the main name is OK					
			if [ ! -f  ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ] ; then 
				FILETOINSTALL=`find ${HOMEDIR}/SAR/EXEC/ -maxdepth 1 -type f -name "*cpxfiddle*" 2>/dev/null`
				SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
			fi
		
			FILEXT="${RAWFILE##*.}"
 
			if [ "${FILEXT}" == "cc" ] 
				then 
					cd ${HOMEDIR}/SAR/EXEC/
					if [ "${OS}" == "Linux" ] ; then 													
						ORIGINAL="if (argv\[optind\]==" 
						NEW="if (argv\[optind\]==0 || argv\[optind\]\[0\]==\'\\\0\'\)" 		# this is a tricky one... 
						${PATHGNU}/sed -i 's/.*'"${ORIGINAL}"'.*/'"${NEW}"'/' ${RAWFILE}				# this is a tricky one... 
					fi
					make -n cpxfiddle
					g++ -O -c -ocpxfiddle.o cpxfiddle.cc  
					g++ -O cpxfiddle.o -o cpxfiddle
					rm -f cpxfiddle.o # cpxfiddle.cc
					mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
					mv cpxfiddle.cc ${HOMEDIR}/SAR/EXEC/Sources_Installed/

				else 
					echo " Format not as expected (cc). May not be genuine file ? Please do manually"			
			fi
		fi
	}
	
function InstallCpxfiddle()
	{
		EchoInverted "  // cpxfiddle is not mandatory but it is called thousands of time to create (very convenient) raster files. "
		while true; do
			read -p "Do you want to [c]heck, [i]nstall or [s]kip cpxfiddle  ? [c/i/s] "  cis
			case $cis in
			[Cc]* ) 	
					echo "  // OK, let's check its version."
					cpxfiddle 2> tmp_cpx.txt
					CPXVER=`cat tmp_cpx.txt | grep version | cut -d " " -f6` 
					rm -f tmp_cpx.txt
					
					if [ "${CPXVER}" == "" ] 
						then 
							echo "cpxfiddle seems not installed. "
							while true ; do
							read -p "Do you want to install it now [y]es or [n]o ? "  yn
								case $yn in
									[Yy]* ) 
										echo "  // OK, I will try to install it."
										DoInstallCpxfiddle
										break ;;
									[Nn]*)
										echo "  // OK, you know..." 
										break ;;
									* ) 
										echo "Please answer [y]es or [n]o." ;;
								esac
							done

						else 
							echo "cpxfiddle version ${CPXVER} is installed"
							echo "  // It is your responsability to verify that it is the last one though..."
					fi
					break ;;
			[Ii]* ) 				
					echo "  // OK, I do it now."
					DoInstallCpxfiddle
					break ;;
			[Ssn]* ) 
					echo "  // OK, I skip it."
					break ;;
				* )  
					echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
			esac
		done							
		echo ""			
	}

DoInstallMasTerEngine()
	{
		# Below assign MasTer Engine to install as RAWFILE
		AskDistroComponent "MasTerEngine" "https://github.com/ndoreye/MasTerToolbox_Distribution"

		if [ "${SKIP}" == "No" ] ; then 
			# just if there is a typo in the version, or name... hoping that at least the main name is OK					
			if [ ! -f  ${PATHDISTRO}/MasTerEngine_sources/"${RAWFILE}" ] ; then 
				FILETOINSTALL=`find ${PATHDISTRO}/MasTerEngine_sources/ -maxdepth 1 -type f -name "*MasTerEngine*" 2>/dev/null`
				SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
			fi

			FILEXT="${RAWFILE##*.}"

			if [ "${FILEXT}" == "xz" ] 
				then 
					MASTERENGINEDATE=`echo "${RAWFILE}" | grep -Eo "[0-9]{8}" `
		
					MESOURCEDIR="${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/_Sources_ME/Older/V${MASTERENGINEDATE}_MasterEngine/"
					mkdir -p "${MESOURCEDIR}"
					cp -f ${PATHDISTRO}/MasTerEngine_sources/${RAWFILE} ${MESOURCEDIR}
					cd ${MESOURCEDIR}
					TARDIRNAME=`ls -t *.tar.xz | head -1 | cut -d . -f 1`
					echo "  // Decompress ${TARDIRNAME}.tar.xz..."
					tar -xf ${TARDIRNAME}.tar.xz
					# Check if unzipped MasTerEngine file contains subdirs (i.e. compilable version), or only binaries (i.e. not compilable version)
					if [ -d "${MESOURCEDIR}/" ] 
						then  
							NRSUBDIR=`find ${MESOURCEDIR} -mindepth 1 -maxdepth 1 -type d | wc -l`
					fi
					if [ ${NRSUBDIR} -eq 0 ]
						then 
							echo "  // It seems that you install MasTerEngine binaries... Let's move the executables to the appropriate place "	
							cd ${MESOURCEDIR}/${TARDIRNAME}
							mv -f * ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/
						else 
							echo "  // Compile and install MasTerEngine"							
							if [ -d ${MESOURCEDIR}/${TARDIRNAME}/Archives ]
								then 
									# seems to be the new version of MasterEngine distrubution, that is made for the installer
									VERSION=NEW
									cd ${TARDIRNAME}/Archives
									TARNAME=`ls Mas*.tar.xz`
									echo "   Decompress ${TARNAME}.tar.xz..."
									tar -xf Mas*.tar.xz
									cd InSAR/sources
								else
									# seems to be the old version of MasterEngine distrubution
									VERSION=OLD
									if [ -d ${TARDIRNAME} ]		# because sometimes tar decompress in current dir or in dir named by the tar file...
										then 
											cd ${TARDIRNAME}/InSAR/sources
										else 
											TARDIRNAME=""
											cd InSAR/sources			
									fi
							fi 

							echo "  // Compile MasTerEngine "

							if [ "${PARALLELOPTION}" == "-p" ]
								then 
									ParalleliseME "YES" 
								else 
									ParalleliseME "NO" 
							fi

							#make 
							cp _History.txt ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/
							cd ../bin
							mv -f * ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/
							cd ../..

							echo "  // Compile MSBAS Tools as well "
							cd MSBASTools/sources
							
							if [ "${PARALLELOPTION}" == "-p" ]
								then 
									ParalleliseME "YES" 
								else 
									ParalleliseME "NO" 
							fi
							#make 

							cd ../bin
							mv -f * ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/
							cd ../..
		
							echo "  // Clean sources "
							cd ${MESOURCEDIR}
							if [ "${TARDIRNAME}" == "" ]
								then 
									rm -R InSAR
									rm -R MSBASTools
								else
									rm -R ${TARDIRNAME}
							fi
					fi
					echo "  // "
				else 
					echo " Format not as expected (xz). May not be genuine file ? Please do manually"			
			fi	
			cd ${HOMEDR}	
		fi	
	}

function InstallMasTerEngine()
	{
		EchoInverted "  // MasTerEngine is the InSAR processor.  "
		while true; do
			read -p "Do you want to [c]heck, [i]nstall/compile or [s]kip MasTerEngine  ? [c/i/s] "  cis
			case $cis in
			[Cc]* ) 	
				echo "  // OK, let's check its version. It is your responsability to verify that it is the last one though..."
				LASTDIRINFO=`find ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/_Sources_ME/Older -type d -name "V*" -printf "%T@ %Tc %p\n" 2>/dev/null | sort -n | tail -1 `  # get last creater dir
				#	Get everything after the last /:
				LASTDIRNAME="${LASTDIRINFO##*/}"
				MEVER=`echo ${LASTDIRNAME} | cut -d _ -f1`
				if [ "${MEVER}" == "" ] 
					then 
						echo "MasTerEngine seems not installed. "
						while true ; do
						read -p "Do you want to install it now [y]es or [n]o ? "  yn
							case $yn in
								[Yy]* ) 
									echo "  // OK, I will try to install it."
									DoInstallMasTerEngine
									break ;;
								[Nn]*)
									echo "  // OK, you know..." 
									break ;;
								* ) 
									echo "Please answer [y]es or [n]o." ;;
							esac
						done

					else 
						echo "MasTerEngine version ${MEVER} is installed"
						echo "  // It is your responsability to verify that it is the last one though..."
				fi
				break ;;				
			[Ii]* ) 				
					echo "  // OK, I do it."
					DoInstallMasTerEngine			
					break ;;
			[Ssn]* ) 
					echo "  // OK, I skip it."
					break ;;
				* )  
					echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
			esac
		done							
		echo ""	
	}
	
function TstPathGnuFctMac()
	{
		local GFCT
		local WHEREISGFCT
		local TSTPATHGFCT
		local FCT
		
		GFCT=$1

		WHEREISGFCT=`which ${GFCT}`
		TSTPATHGFCT=`dirname ${WHEREISGFCT}`
		FCT="${GFCT:1}" 
		
		if [ "${WHEREISGFCT}" != "${PATHGNU}/${GFCT}" ] 
			then 
				echo "${GFCT} is in ${TSTPATHGFCT} instead of ${PATHGNU}. Let's link it to ${PATHGNU}/${GFCT} (and to ${PATHGNU}/${FCT} for security)" 
				#sudo ln -s "${WHEREISGFCT}" ${PATHGNU}/${GFCT} 2>/dev/null 
				if [ ! -f ${PATHGNU}/${GFCT} ] ; then sudo ln -s "${WHEREISGFCT}" ${PATHGNU}/${GFCT} 2>/dev/null ; else echo "	// ${GFCT} already linked in ${PATHGNU}" ; fi
				
				#sudo ln -s "${WHEREISGFCT}" ${PATHGNU}/${FCT} 2>/dev/null 
				if [ ! -f ${PATHGNU}/${FCT} ] ; then sudo ln -s "${WHEREISGFCT}" ${PATHGNU}/${FCT} 2>/dev/null ; else echo "	// ${FCT} already linked in ${PATHGNU}" ; fi
			else 
				echo "Link ${GFCT} to ${FCT} in ${PATHGNU} for security" 
				#sudo ln -s "${WHEREISFCT}" ${PATHGNU}/${FCT} 2>/dev/null
				if [ ! -f ${PATHGNU}/${FCT} ] ; then sudo ln -s "${WHEREISGFCT}" ${PATHGNU}/${FCT} 2>/dev/null ; else echo "	// ${FCT} already linked in ${PATHGNU}" ; fi

		fi
	}

function TstPathGnuFctLinux()
	{
		local FCT			# gnu fct by default though without g-prefix
		local WHEREISFCT
		local TSTPATHFCT
		local GFCT
		
		FCT=$1

		WHEREISFCT=`which ${FCT}`
		TSTPATHFCT=`dirname ${WHEREISFCT}`
		GFCT="g${FCT}" 
		
		if [ "${WHEREISFCT}" != "${PATHGNU}/${FCT}" ] 
			then 
				echo "${FCT} is in ${TSTPATHFCT} instead of ${PATHGNU}. Let's link it to ${PATHGNU}/${FCT} (and to ${PATHGNU}/${GFCT} for security)" 
				sudo ln -s "${WHEREISFCT}" ${PATHGNU}/${FCT} 2>/dev/null 
				sudo ln -s "${WHEREISFCT}" ${PATHGNU}/${GFCT} 2>/dev/null 
			else 
				echo "Link ${FCT} to ${GFCT} in ${PATHGNU} for security" 
				sudo ln -s "${WHEREISFCT}" ${PATHGNU}/${GFCT} 2>/dev/null
		fi
	}


DoInstallMSBAS()
	{
		echo "  // msbas software performs the svd inversion for the ground deformation time series." 
		echo "  //     The sources were prepared to be Mac and Linux compliant for this installer." 
		echo "  // Several versions are possible, e.g.: " 
		echo "  //      msbas_20201009_wExtract_Unified_20220919_Optimized_v1.1_Gilles.zip runs msbasv4 (2D) in parallel on ALL the available cores for a maximum of efficiency. "
		echo "  //      msbas_20201009_wExtract_Unified_20220919_Optimized_v1_Gilles.zip runs msbasv4 (2D) on only one core. "
		echo "  //      msbas_20201009_wExtract_Unified_20220818-Gilles.zip runs msbasv4 (2D) on a LIMITED number of cores (max 12 threads). "
		echo "  //      msbas_v10_20230601_Gilles.zip runs msbasv10 (3/4D)... Not ready for the MasTer Toolbox yet, i.e. for manual usage only . "
		echo "  //   If you want another version, please install it manually. "
		echo "  //   You can contact directely the autor (sergey.samsonov@NRCan-RNCan.gc.ca) for other version or for more info. In that case, you will have to compile it manually "
		echo "  //   i.e.: unzip the package, go to sources subdirs and run make; move binaries in MSBAS dir)"

		# Below assign msbas zipped version to install as RAWFILE
		AskDistroComponent "msbas" "https://github.com/ndoreye/MasTerToolbox_Distribution"

		echo "  // OK, I will try to install msbas and msbas_extract using ${RAWFILE}. "

		if [ "${SKIP}" == "No" ] ; then 
			FILEXT="${RAWFILE##*.}"
 			FILENOXT=`echo "${RAWFILE%.*}"`
			if [ "${FILEXT}" == "zip" ] 
				then 
					# Save possible former versions
					FORMERVERSION=`ls ${HOMEDIR}/SAR/MasTerToolbox/MSBAS/msbasv* 2>/dev/null | grep -v "zip"`
					if [ "${FORMERVERSION}" != "" ] ; then
						echo "  // Save former version in SAR/MasTerToolbox/MSBAS/Former_version/. "
						mkdir -p ${HOMEDIR}/SAR/MasTerToolbox/MSBAS/Former_version
						mv -f ${FORMERVERSION} ${HOMEDIR}/SAR/MasTerToolbox/MSBAS/Former_version/
					fi

					unzip ${PATHDISTRO}/msbas_sources/${RAWFILE}
					cd ${PATHDISTRO}/msbas_sources/${FILENOXT}
					
					make all 
					
					# Check version 
					MSBASVERSION=`ls msbasv* | grep -v "zip" | cut -d v -f2`
					echo "  // msbas version ${MSBASVERSION} compiled. "

	
					# store compiled msbas in SAR/MasTerToolbox/MSBAS/
					echo "  // store compiled msbasv${MSBASVERSION} in SAR/MasTerToolbox/MSBAS/"
					cp ${PATHDISTRO}/msbas_sources/${FILENOXT}/msbasv${MSBASVERSION} ${HOMEDIR}/SAR/MasTerToolbox/MSBAS/

					case ${MSBASVERSION} in 
						"4")
							# msbas_extract only available in v4
							echo "  // msbas_extract available with msbasv${MSBASVERSION}; Compile it now "
							cd msbas_extract
							make
							cp ${PATHDISTRO}/msbas_sources/${FILENOXT}/msbas_extract/msbas_extract ${HOMEDIR}/SAR/MasTerToolbox/MSBAS/
							cd ${HOMEDIR} 
							;;
						"10")
							echo "  // msbas_extract not available with msbasv${MSBASVERSION}; Compile it with a former version if needed... "
							;;
						*) 
							echo " Unknown version. Please do manually"	
							;;
					esac
					
					# Keep sources
					mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
					cp -f ${PATHDISTRO}/msbas_sources/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed
					rm -rf ${PATHDISTRO}/msbas_sources/${FILENOXT}
					rm -rf ${PATHDISTRO}/msbas_sources/${FILENOXT}/__MACOSX
					
				else 
					echo " Format not as expected (zip). May not be genuine file ? Please do manually"		
			fi	
		fi
		echo "  // "
	}

function InstallMSBAS()
	{
		EchoInverted "  // msbas is the software required to create the deformation time series.   "
		while true; do
			read -p "Do you want to [c]heck, [i]nstall or [s]kip msbas  ? [c/i/s] "  cis
			case $cis in
				[Cc]* ) 				
						echo "  // OK, let's check its version. It is your responsability to verify that it is the last one though..."
					
						which msbas > List_msbas.txt
						for i in `seq 1 20` ; do which msbasv${i}; done >> List_msbas.txt
						NROFMSBAS=$(cat List_msbas.txt | wc -l)
						if [ ${NROFMSBAS} -gt 0 ]
							then
								MSBASVER=`tail -1 List_msbas.txt`
								echo "  // You have ${NROFMSBAS} msbas versions"		
 								rm -f List_msbas.txt
							else
								MSBASVER=""
						fi
						
						if [ "${MSBASVER}" == "" ] 
							then 
								echo "msbas seems not installed. "
								while true ; do
								read -p "Do you want to install it now [y]es or [n]o ? "  yn
									case $yn in
										[Yy]* ) 
											DoInstallMSBAS
											break ;;
										[Nn]*)
											echo "  // OK, you know..." 
											break ;;
										* ) 
											echo "Please answer [y]es or [n]o." ;;
									esac
								done
							else 
								echo "last msbas version installed is ${MSBASVER}"
								while true ; do
								read -p "Do you want to install a new version [y]es or [n]o ? "  yn
									case $yn in
										[Yy]* ) 
											DoInstallMSBAS
											break ;;
										[Nn]*)
											echo "  // OK" 
											break ;;
										* ) 
											echo "Please answer [y]es or [n]o." ;;
									esac
								done

						fi
						break ;;
				[Ii]* ) 				
						DoInstallMSBAS
						break ;;
				[Ssn]* ) 
						echo "  // OK, I skip it."
						break ;;
					* )  
						echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
				esac
		done							
		echo ""	
	}
	
function ParalleliseME()
	{
		SEARCHSTRING=$1 	# YES or NO
		
		# Check if the line for parallelisation exists in the makefile 
 		if ${PATHGNU}/ggrep -qF "USEOPENMP = " makefile 
 			then
 				if [ "${SEARCHSTRING}" == "YES" ]
					then 
						echo " using the parallelistaion option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = YES
						# ${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = YES"'/' makefile
						make USEOPENMP=YES
					else 
						echo " without using the parallelistaion option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = NO
						# ${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = NO"'/' makefile
						make
				fi
			else
			    if [ "${SEARCHSTRING}" == "YES" ]
			    	then 
			  			echo "The parallelistaion option line doesn't exist in the makefile ? It must have a line like this: "
			    		echo "USEOPENMP = ... or USEOPENMP?=..."
			    		echo "If your version of MasTer Engine is not planned for parallelistaion, just run the script without the -p option."
			    		exit
			    fi
		fi
	}

	
###############
# Some advice #
###############
# ensure to start in home dir 
cd

EchoInverted "  // If you had old MasTer Toolbox config in your .bashrc (i.e. not setup from the present script), "
EchoInverted "  //    it is advised to first backup your .bashrc, then remove manually the old MasTer Toolbox config, then relaunch the installation script ${PRG}... "
while true; do
	read -p "Do you want to continue ?  [y/n] "  yn
	case $yn in
		[Yy]* ) 
			echo "  // OK, let's go. "
			eval HOMEDIR=$(pwd)
			while true; do
				read -p "Please, confirm that your home directory is: ${HOMEDIR}  ? [y/n] "  yn
				case $yn in
					[Yy]* ) 
						echo ""
						break
						;;
					[Nn]* ) 
						read -e -p "Then enter here your home dir (e.g. /Users/Your_Account ; do not mess up with name !). You can use Tab for autocompletion. "  HOMEDIR
						if [ ! -d "${HOMEDIR}" ] ; then echo " Sorry ${HOMEDIR} does not exist" ; exit ; fi
						break
						;;
					
						* )  
						echo "Please answer [y]es or [n]o." ;;
			esac
			done							
			break ;;
		[Nn]* ) 
			echo
			echo "  // OK, see you next time... "
			exit			
			break ;;
		* ) 
			echo "Please answer [y]es or [n]o";;
	esac
done

############
# Check OS #
############
case ${OS} in 
	"Linux") 
		EchoInverted "  // We shall install/update MasTer Toolbox on this Linux Computer. Your OS is:  "
		echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "
		lsb_release -a 2> /dev/null
		UBUNTUVER=`lsb_release -a 2> /dev/null | grep "Release" | awk '{ print $2 }' | cut -d . -f1`
		if [ ${UBUNTUVER} -lt 18 ] ; then 
			echo "  // Ubuntu versions before 18 does not have snap; install it now. " 
			sudo apt install snapd
		fi
		TSTMAKE=`make -version 2>/dev/null`
		if [ "${TSTMAKE}" == "" ] 
			then sudo apt install make 
		fi
		echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "
		;;
	"Darwin")
		EchoInverted "  // We shall install/update MasTer Toolbox on this Mac Computer. Your OS is:  "
		echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "
		sw_vers
		echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "
		
		# Will need /opt/local/bin hence create it now if it does not exist yet
		cd ${HOMEDIR}
		mkdir -p /opt/local/bin/
		;;
esac			

echo

################################
# Create mandatory directories #
################################
cd ${HOMEDIR}
mkdir -p SAR
mkdir -p SAR/EXEC
mkdir -p SAR/MasTerToolbox/DOC
mkdir -p SAR/MasTerToolbox/MasTerEngine
mkdir -p SAR/MasTerToolbox/MasTerEngine/_Sources_ME
mkdir -p SAR/MasTerToolbox/MasTerEngine/_Sources_ME/Older
mkdir -p SAR/MasTerToolbox/MSBAS
mkdir -p SAR/MasTerToolbox/SCRIPTS_MT

#########################
# Check type of install #
#########################
while true; do
	read -p "Do you need a [f]ull installation or an [u]pdate of some components ?  [f/u] "  fu
	case $fu in
		[Ff]* ) 
			echo
			echo "  // OK, let's start from scratch. "
			TYPERUN="I"
			break ;;
		[Uu]* ) 
			echo
			echo "  // OK, let's ignore external components and libraries. Only update MasTer Toolbox components. "
			TYPERUN="U"			
			break ;;
		* ) 
			echo "Please answer [i]nstallation or an [u]pdate.";;
	esac
done

echo 

#################################################################################
# Proceed first to external components and libraries - mandatory at 1st install #
#################################################################################
if [ "${TYPERUN}" == "I" ] ; then

	# setup the ${HOMEDIR}/.bash_profile
	# -------------------------
	EchoInverted "  // Test your /.bash_profile:"
	if [ -f ${HOMEDIR}/.bash_profile ]
		then 
			echo "  // You already have a ${HOMEDIR}/.bash_profile "
			TST=`grep "source ~/.bashrc" ${HOMEDIR}/.bash_profile | wc -w`
			if [ "${TST}" -gt 0 ] ; then 
					echo "  // and /.bashrc is already sourced in there."
				else 
					echo "  // but no /.bashrc is sourced in there. Let's do it to be sure... (former /.bash_profile is saved as /.bash_profile_${RUNDATE}) "
					if [ ! -f ${HOMEDIR}/.bash_profile_${RUNDATE} ] ; then cp ${HOMEDIR}/.bash_profile ${HOMEDIR}/.bash_profile_${RUNDATE} ; fi
					
					sudo echo "source ~/.bashrc" >> ${HOMEDIR}/.bash_profile
			fi		
		else 
			echo "  // No /.bash_profile exists. Create one and source the /.bashrc in the /.bash_profile to be sure"
			sudo echo "source ~/.bashrc" > ${HOMEDIR}/.bash_profile	
			sudo chmod 700 ${HOMEDIR}/.bash_profile
	fi
	echo ""
	
	# setup the ${HOMEDIR}/.bashrc
	# -------------------
	EchoInverted "  // Test your /.bashrc:"
	if [ -f ${HOMEDIR}/.bashrc ]
		then 
			echo "  // You already have a /.bashrc "
		else 
			echo "  // No /.bashrc exists. Create one"
			sudo touch ${HOMEDIR}/.bashrc
			sudo chmod 700 ${HOMEDIR}/.bashrc
	fi
	echo ""	
	
	case ${OS} in 
		"Linux") 
# LINUX
			EchoInverted "  // We shall install/update various MasTer Toolbox (side)components on this Linux Computer"
			# display Ubuntu version
			lsb_release -a
			echo ""
			echo ""
			echo "  // Watch the messages displayed during installations as it may inform you about errors and/or warnings that may require your attention and actions."
			echo ""


			# 1) Update apts - Linux
			# ---------------
				EchoInverted "  // Although not mandatory, it might be advised to update apt first. "
				while true; do
					read -p "Do you want to update apt ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, it will request your admin pwd and may take time... "	
							sudo apt update
							sudo apt upgrade
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o." ;;
					esac
				done							
				echo ""			

			# to be sure... 
			AptInsatll "gzip"

			# 2) Some optional stuffs - Linux
			# -----------------------
				# GITKRAKEN - Linux
				# .........
					EchoInverted "  // Although not mandatory, Gitkraken is a useful tool to sync with the last versions of MasTer Toolbox."
					echo "  // It requires credentials to access MasTer private repositories on Github (contact ndo@ecgs.lu)."
					echo "  // GitKraken used to access private repositories requires a license though. "
					while true; do
						read -p "Do you want to [c]heck, [i]nstall or [s]kip GITKRAKEN  ? [c/i/s] "  cis
						case $cis in
						[Cc]* ) 				
								echo "  // OK, let's check its version. .."
								GITVER=`gitkraken --version 2>/dev/null`
								if [ "${GITVER}" == "" ] 
									then 
										echo "Gitkraken seems not installed. "
										while true ; do
										read -p "Do you want to install it now [y]es or [n]o ? "  yn
											case $yn in
												[Yy]* ) 
													echo "  // OK, I will try to install it."
													sudo snap install gitkraken --classic
													#AptInsatll "gitkraken --classic"
													break ;;
												[Nn]*)
													echo "  // OK, you know..." 
													break ;;
												* ) 
													echo "Please answer [y]es or [n]o." ;;
											esac
										done
									else 
										echo "Gitkraken version ${GITVER} is installed"
										CheckLastAptVersion "gitkraken --classic"
										echo "  // It is your responsability to compare your version with the last one available..."
								fi
								break ;;
						[Ii]* ) 				
								sudo snap install gitkraken --classic
								#AptInsatll "gitkraken --classic"
								break ;;
						[Ssn]* ) 
								echo "  // OK, I skip it."
								break ;;
							* )  
								echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
						esac
					done
					echo " WARNING: if Gitkraken install but close at launch (as observed on some Ubuntu 22.04), install it manually with flatpack: "	
					echo "           flatpak install flathub com.axosoft.GitKraken"			
					echo "         see https://flathub.org/apps/details/com.axosoft.GitKraken"	
							
				# GIMP - Linux
				# ....
					EchoInverted "  // Although not mandatory, Gimp is a usefull tool to display raster images. "
					while true; do
						read -p "Do you want to [c]heck, [i]nstall or [s]kip GIMP  ? [c/i/s] "  cis
						case $cis in
						[Cc]* ) 				
								echo "  // OK, let's check its version. "
								GIMPVER=`gimp -version 2>/dev/null`
								if [ "${GIMPVER}" == "" ] 
									then 
										echo "Gimp seems not installed. "
										while true ; do
										read -p "Do you want to install it now [y]es or [n]o ? "  yn
											case $yn in
												[Yy]* ) 
													echo "  // OK, I will try to install it."
													sudo add-apt-repository ppa:ubuntuhandbook1/gimp 

													AptInsatll "gimp"
													break ;;
												[Nn]*)
													echo "  // OK, you know..." 
													break ;;
												* ) 
													echo "Please answer [y]es or [n]o." ;;
											esac
										done
									else 
										echo "${GIMPVER} is installed"
										CheckLastAptVersion "gimp"
										echo "  // It is your responsability to compare your version with the last one available..."
								fi
								break ;;
						[Ii]* ) 				
								echo "  // OK, I will try to install it."
								sudo add-apt-repository ppa:ubuntuhandbook1/gimp 
								#sudo apt update
								AptInsatll "gimp"
								break ;;
						[Ssn]* ) 
								echo "  // OK, I skip it."
								break ;;
							* )  
								echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
						esac
					done							
					echo ""			


			
			# 3) Some external components - Linux
			# ---------------------------
				# gmt, GDAL - Linux
				# .........
				EchoInverted "  // GMT, GDAL and some associated utilities are required for plots, images and GIS manipulations. "
				while true; do
					read -p "Do you want to install/update GMT, GDAL... ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, install GMT (last version ?) and GDAL..."
							AptInsatll "gdal-bin" 
							AptInsatll "libgdal-dev"
							#AptInsatll "libgdal26" 
							AptInsatll "libgdal30" 
							AptInsatll "libhdf5-dev" 
							AptInsatll "gmt"
							AptInsatll "libnetcdf-dev"

							#sudo apt install openjpeg  
							AptInsatll "graphicsmagick ffmpeg "
							echo "  // Your GDAL version is:"
							gdalinfo --version
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# gnu fortran - Linux
				# ...........
				EchoInverted "  // Maybe not mandatory but always good to have: gnu fortran.  "
				while true; do
					read -p "Do you want to install/update gnu fortran ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, install gnu fortran."
							AptInsatll "gfortran" 
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# gnu functions - Linux
				# .............
				EchoInverted "  // Several commands might exist by default on Linux, but getting the ${smso}gnu version${rmso} again is wise.  "
				while true; do
					read -p "Do you want to install/update gnu utilities ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, install gnu utilities and make appropriate alias."
							AptInsatll "sed"
							AptInsatll "gawk"
							AptInsatll "coreutils"  	#(i.e. for gdate, gstat)
							AptInsatll "findutils"		#(i.e. for find)
							AptInsatll "grep"			#(i.e. for ggrep)
							AptInsatll "wget"			#(needed i.e. to download the S1 orbits)
							sudo snap install curl			#and add the path to curl (e.g. /snap/bin) in your $PATH 

							# To be sure, prepare to add curl in PATH (see at the bottom of the script)
							WHEREISCURL=`which curl`
							PATHCURL=`dirname ${WHEREISCURL}`						
							
							# To be sure, prepare to add gnu-named versions in PATHGNU state variable (see at the bottom of the script)
							PATHGNU="/usr/bin" 	# should be this in Linux
							
							# awk might not be installed by default on Linux, hence we got gawk - all other will be made with function
							WHEREISGAWK=`which gawk`  	# (beware if awk already exist and would be a link pointing toward another version of awk. Replace it with our gawk)
							PATHGAWK=`dirname ${WHEREISGAWK}`
							if [ "${WHEREISGAWK}" != "${PATHGNU}/gawk" ] 
								then 
									echo "gawk is in ${PATHGAWK} instead of ${PATHGNU}. Let's link it to ${PATHGNU}/gawk (and to ${PATHGNU}/awk for security)" 
									sudo ln -s "${WHEREISGAWK}" ${PATHGNU}/gawk 2>/dev/null 
									sudo ln -s "${WHEREISGAWK}" ${PATHGNU}/awk 2>/dev/null 
								else 
									echo "Link agwk to awk in ${PATHGNU} for security" 
									sudo ln -s "${WHEREISGAWK}" ${PATHGNU}/awk 2>/dev/null
							fi

							TstPathGnuFctLinux "sed"
							TstPathGnuFctLinux "grep"
							TstPathGnuFctLinux "seq"
							TstPathGnuFctLinux "uniq"
							TstPathGnuFctLinux "readlink"
							TstPathGnuFctLinux "xargs"
							TstPathGnuFctLinux "du"
							
							if [ `which date` != "${PATHGNU}/date" ] ; then echo "coreutils seems not in ${PATHGNU}; please check. I arrange it at least for date  here though" ; fi
							TstPathGnuFctLinux "date"
							
							if [ `which stat` != "${PATHGNU}/stat" ] ; then echo "findutils seems not in ${PATHGNU}; please check. I arrange it at least for stat and find here though" ; fi
							TstPathGnuFctLinux "stat"
							TstPathGnuFctLinux "find"
							
							WHEREISWGET=`which wget`
							if [ "${WHEREISWGET}" != "${PATHGNU}/wget" ] ; then echo "wget seems not in ${PATHGNU}; please check. I make a link though" ; sudo ln -s "${WHEREISWGET}" ${PATHGNU}/wget 2>/dev/null ; fi

							cd  ${HOMEDIR}
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			


				# libraries - Linux
				# .........
				EchoInverted "  // Several libraries are mandatory for MasTer compilation.  "
				while true; do
					read -p "Do you want to install/update the libraries? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I install mandatory libraries"
							AptInsatll "clang"
							AptInsatll "libfftw3-dev"
							AptInsatll "libfftw3-long3" 
							AptInsatll "libfftw3-single3"
							AptInsatll "libgeotiff-dev"
							AptInsatll "libtiff-dev"
							AptInsatll "libxml2"
							AptInsatll "libxml2-dev"
							AptInsatll "liblapack-dev"
							AptInsatll "libomp-dev"
							#AptInsatll "libatlas-base-dev"
							AptInsatll "libopenblas-dev"
							AptInsatll "graphicsmagick-imagemagick-compat"
							AptInsatll "imagemagick-6-common"
							AptInsatll "imagemagick"				# for convert
							WHEREISCONV=`which convert`					# To be sure, prepare to add convert in PATHCONV state variable (see at the bottom of the script)
							PATHCONV=`dirname ${WHEREISCONV}`
							sudo apt install "g++"
							AptInsatll "espeak -y" 		#(to make your computer talking during mass processing)
							if [ -f /etc/ImageMagick/policy.xml ] ; then 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"coder\" rights=\"none\" pattern=\"PS\"/policy domain=\"coder\" rights=\"read|write\" pattern=\"PS\"/" /etc/ImageMagick/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"coder\" rights=\"none\" pattern=\"EPS\"/policy domain=\"coder\" rights=\"read|write\" pattern=\"EPS\"/" /etc/ImageMagick/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"height\" value=\"16KP\"/policy domain=\"resource\" name=\"height\" value=\"32KP\"/" /etc/ImageMagick/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"width\" value=\"16KP\"/policy domain=\"resource\" name=\"width\" value=\"32KP\"/" /etc/ImageMagick/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"disk\" value=\"1GiB\"/policy domain=\"resource\" name=\"disk\" value=\"8GiB\"/" /etc/ImageMagick/policy.xml 
							fi
							if [ -f /etc/ImageMagick-6/policy.xml ] ; then 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"coder\" rights=\"none\" pattern=\"PS\"/policy domain=\"coder\" rights=\"read|write\" pattern=\"PS\"/" /etc/ImageMagick-6/policy.xml
								sudo ${PATHGNU}/sed -i "s/policy domain=\"coder\" rights=\"none\" pattern=\"EPS\"/policy domain=\"coder\" rights=\"read|write\" pattern=\"EPS\"/" /etc/ImageMagick-6/policy.xml
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"height\" value=\"16KP\"/policy domain=\"resource\" name=\"height\" value=\"32KP\"/" /etc/ImageMagick-6/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"width\" value=\"16KP\"/policy domain=\"resource\" name=\"width\" value=\"32KP\"/" /etc/ImageMagick-6/policy.xml 
								sudo ${PATHGNU}/sed -i "s/policy domain=\"resource\" name=\"disk\" value=\"1GiB\"/policy domain=\"resource\" name=\"disk\" value=\"8GiB\"/" /etc/ImageMagick-6/policy.xml 
							fi
							AptInsatll "parallel"
							AptInsatll "mpich"
							AptInsatll "libgsl-dev"	
							
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			


				# JAVA - Linux
				# ....
				
				EchoInverted "  // Java is required for some processings using Fiji or ImageMagick. "
				AptInsatll default-jdk

				echo "  // In case of instalation problem, you can also try manual install from http://www.java.com following the instructions"
				echo "  //"
				echo
				echo "  // May need to define JAVA_HOME state variable for some application using it. I will try to do it, though in case of problem, check its location by typing:"
				echo "  //    java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' "
				echo "  //    and note the path to the desired version of java, though dropping everything before the sign = , e.g. /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home "  
				echo
				echo "  // If it fails, you can also try:"
				echo "  //    sudo update-alternatives --config java" 
				echo "  //    and note the path to the desired version of java, though dropping everything from /bin, e.g. /usr/lib/jvm/java-11-openjdk-amd64 "  
				echo
				echo "  //  Then edit add it to your bashrc (or /etc/environment ?) as export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
				echo
				echo "  NOTE: if some scripts crash with the following message, re-install java and then re-install Fiji: "
				echo "        << The operation couldn't be completed. Unable to locate a Java Runtime that supports (null). >>"
				echo 

				JAVAHOMEPATH=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | cut -d = -f2- | cut -d " " -f2-` 
				JVHP="\"${JAVAHOMEPATH}\""
				UpdateVARIABLESBashrc "JAVA_HOME" "export JAVA_HOME=${JVHP}"
			


				# FIJI/IMAGEJ - Linux
				# ...........
				EchoInverted "  // Fiji/ImageJ is required for some processings converting images. "
				while true; do
					read -p "Do you want to [c]heck, [i]nstall or [s]kip Fiji/ImageJ  ? [c/i/s] "  cis
					case $cis in
						[Cc]* ) 
							FIJIEXEC=`find ${HOMEDIR}/SAR/EXEC/Fiji.app/ -type f -name "ImageJ-linux*" 2>/dev/null`
							if [ "${FIJIEXEC}" == "" ] 
								then
									echo "Fiji/ImageJ seems not installed. "
									while true ; do
										read -p "Do you want to install it now [y]es or [n]o ? "  yn
											case $yn in
												[Yy]* ) 
													echo "  // OK, I will try to install it."
													AskExternalComponent "Fiji/ImageJ" "https://imagej.net/software/fiji/downloads" 
													if [ "${SKIP}" == "No" ] ; then 
														# just if there is a typo in the version, or name... hoping that at least the main name is OK					
														if [ ! -f  ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ] ; then 
															FILETOINSTALL=`find ${HOMEDIR}/SAR/EXEC/ -maxdepth 1 -type f -name "*ImageJ*" 2>/dev/null`
															SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
														fi
														
														FILEXT="${RAWFILE##*.}"
 
														if [ "${FILEXT}" == "zip" ] 
															then 
																unzip ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
																#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
																mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
													 			mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/

																FIJIEXEC=`find ${HOMEDIR}/SAR/EXEC/Fiji.app/ -type f -name "ImageJ-linux*"  2>/dev/null`
																if [ "${FIJIEXEC}" == "" ] ; then FIJIEXEC=`find ${HOMEDIR}/Fiji.app/ -type f -name "ImageJ-linux*"` ; fi

																PATHFIJI=`dirname ${FIJIEXEC}`
																echo "  // "
															else 
																echo " Format not as expected (zip). May not be genuine file ? Please do manually"			
														fi		
													fi											
													break ;;
												[Nn]*)
													echo "  // OK, you know..." 
													break ;;
												* ) 
													echo "Please answer [y]es or [n]o." ;;
											esac
										done
									else 
										echo "Fiji/ImageJ seems installed"
								fi
								break ;;
						[Ii]* ) 				
							echo "  // OK, I do it now."
							AskExternalComponent "Fiji/ImageJ" "https://imagej.net/software/fiji/downloads" 
							if [ "${SKIP}" == "No" ] ; then 
								# just if there is a typo in the version, or name... hoping that at least the main name is OK					
								if [ ! -f  ${HOMEDIR}/SAR/EXEC/"${RAWFILE}" ] ; then 
									FILETOINSTALL=`find ${HOMEDIR}/SAR/EXEC/ -maxdepth 1 -type f -name "*ImageJ*" 2>/dev/null`
									SearchForSimilar ${RAWFILE} ${FILETOINSTALL}
								fi
								
								FILEXT="${RAWFILE##*.}"
 
								if [ "${FILEXT}" == "zip" ] 
									then 
										unzip ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
										#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
										mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
										mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/
										FIJIEXEC=`find ${HOMEDIR}/SAR/EXEC/Fiji.app/ -type f -name "ImageJ-linux*" 2>/dev/null`
										if [ "${FIJIEXEC}" == "" ] ; then FIJIEXEC=`find ${HOMEDIR}/Fiji.app/ -type f -name "ImageJ-linux*"` ; fi

										PATHFIJI=`dirname ${FIJIEXEC}`
										echo "  // "
									else 
										echo " Format not as expected (zip). May not be genuine file ? Please do manually"			
								fi
							fi
							break ;;
					[Ssn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
					esac
				done							
				echo ""			

				# SNAPHU - Linux
				# ......

				InstallSnaphu		

	
				# CPXFIDDLE - Linux
				# .........
				
				InstallCpxfiddle
				
				# GNUPLOT - Linux
				# ......
				EchoInverted "  // gnuplot is used e.g. to create time series figures or baseline plots. "
				while true; do
					read -p "Do you want to install/update gnuplot ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I do it."
							AptInsatll "gnuplot-x11"
							if [ `which gnuplot` != "${PATHGNU}" ] ; then echo "gnuplot seems not in ${PATHGNU}; please check" ; fi
							echo "  // "
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			


				# PYTHON3 - Linux
				# .......
				EchoInverted "  // Some scripts use python and it must be v3. "
				while true; do
					read -p "Do you want to install/update Python3 ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I do it."
							AptInsatll "python3"
							AptInsatll "python3-opencv"
							AptInsatll "python3-numpy"
							AptInsatll "python3-scipy"
							AptInsatll "python3-matplotlib"
							AptInsatll "python3-gdal"
					
							echo "  // Check python3 version:"
							python -c 'import sys ; print(sys.path)'

							echo "  // Create link for smooth call of python by all the scripts"
							sudo mkdir -p /opt/local/
							sudo mkdir -p /opt/local/bin
							WHEREISPYTHON=`which python3`				#(To know where it is installed, e.g. /usr/bin)
							sudo ln -s ${WHEREISPYTHON} /opt/local/bin/python	2>/dev/null
							sudo ln -s ${WHEREISPYTHON} /opt/local/bin/python3 2>/dev/null

							# UTM package
							echo "  // Install also utm packege for python v3. "
							pip install --upgrade pip
							AptInsatll "python3-pip"
							pip install utm
							
							# MasTer Toolbox Organizer
							/opt/local/bin/python -m pip install pyqt6
							
							# MasTer Toolbox Optimisation 
							/opt/local/bin/python -m pip install networkx
							
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			


				# QGIS - Linux
				# ....
				EchoInverted "  // Although not mandatory, QGIS is a usefull tool to work with GIS products. "
				while true; do
					read -p "Do you want to [c]heck, [i]nstall or [s]kip QGIS  ? [c/i/s] "  cis
					case $cis in
					[Cc]* ) 				
							echo "  // OK, let's check its version. "
							QGISVER=`QGIS --version 2>/dev/null`
							QGISVER2=`qgis --version 2>/dev/null`
							if [ "${QGISVER}" == "" ] && [ "${QGISVER2}" == "" ]
								then 
									echo "QGIS seems not installed. "
									while true ; do
									read -p "Do you want to install it now [y]es or [n]o ? "  yn
										case $yn in
											[Yy]* ) 
												echo "  // OK, I will try to install it."
												AptInsatll "gnupg software-properties-common"
												wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg -import
												sudo chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg
												sudo add-apt-repository "deb https://qgis.org/ubuntu $(lsb_release -c -s) main"
												#sudo apt update
												AptInsatll "qgis qgis-plugin-grass"
												echo ""
												echo "  // Note that the following plugins are highly convenients. It might be a good idea to install them"
												echo "  // It is conveniently done manually from within QGIS:"
												echo "  	- point sampling tool"
												echo "  	- PointConnetor"
												echo "  	- Profile tool"
												echo "  	- Qdraw"
												echo "  	- QuickMapServices"
												echo "  	- RasterDataPlotting	(may require to install python first) "
												echo "  	- Serval"
												echo "  	- Temporal/Spectal Profile Tool"
												echo "  	- Value Tool"
												break ;;
											[Nn]*)
												echo "  // OK, you know..." 
												break ;;
											* ) 
												echo "Please answer [y]es or [n]o." ;;
										esac
									done

								else 
									echo "${QGISVER}${QGISVER2} is installed"	# yep, that's a lazy way for not testing which version is the good one
									CheckLastAptVersion "qgis"
									CheckLastAptVersion "QGIS"
									echo "  // It is your responsability to compare your version with the last one available..."
									echo
							fi
							break ;;
					[Ii]* ) 				
							echo "  // OK, I do it."
							AptInsatll "gnupg software-properties-common"
							wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg -import
							sudo chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg
							sudo add-apt-repository "deb https://qgis.org/ubuntu $(lsb_release -c -s) main"
							#sudo apt update
							AptInsatll "qgis qgis-plugin-grass"
							echo ""
							echo "  // Note that the following ${smso}plugins${rmso} are highly convenients. It might be a good idea to install them."
							echo "  // It is conveniently done ${smso}manually from within QGIS${rmso}:"
							echo "  	- point sampling tool"
							echo "  	- PointConnetor"
							echo "  	- Profile tool"
							echo "  	- Qdraw"
							echo "  	- QuickMapServices"
							echo "  	- RasterDataPlotting	(may require to install python first) "
							echo "  	- Serval"
							echo "  	- Temporal/Spectal Profile Tool"
							echo "  	- Value Tool"
							break ;;
					[Ssn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
					esac
				done							
				echo ""			

				# x-terminal-emulator - Linux
				# ...................
				EchoInverted "  // A terminal emulator is required to open temrinal from command line (e.g. when splitting mass processing). "

				eval MYDISPLAY=`who -m | cut -d "(" -f 2  | cut -d ")" -f 1`

				if [ "$MYDISPLAY" == "" ]
					then 
						eval MYDISPLAY=`who | cut -d "(" -f 2  | cut -d ")" -f 1`
						TSTNRDISPL=`who | cut -d "(" -f 2  | cut -d ")" -f 1 | wc -l`
				fi 
				if [ "$MYDISPLAY" == "" ] || [ ${TSTNRDISPL} -gt 1 ]
					then 
						echo "I can't find out which is your current DISPLAY value. "
						echo "I can however see that you have the following DISPLAYs on your server:"
						# The following line list all the DISPLAYs:
						ps -u $(id -u) -o pid=     | xargs -I PID -r cat /proc/PID/environ 2> /dev/null     | tr '\0' '\n'     | grep ^DISPLAY=:     | sort -u
						
						while true; do
							read -p "Which one do you want to use (answer someting like \":0.0\" without the quotes) ? "  MYDISPLAY
							echo "If no Terminal pops up here after, cancel the current script and start again with another DISPLAY"
							break
						done
						eval MYDISPLAY=`echo ${MYDISPLAY}`
				fi 

				echo "  // Your current session runs on DISPLAY ${MYDISPLAY}"

				while true; do
					read -p "Do you want to [c]heck, [i]nstall or [s]kip x-terminal-emulator  ? [c/i/s] "  cis
					case $cis in
					[Cc]* ) 				
							echo "  // OK, let's check its version. "
							XTERMVER=`export DISPLAY=${MYDISPLAY} ; x-terminal-emulator --version  2>/dev/null | cut -d " " -f 2`
							if [ "${XTERMVER}" == "" ] ; then 
								XTERMVER=`export DISPLAY=${MYDISPLAY} ; x-terminal-emulator --help  2>/dev/null`
								if [ "${XTERMVER}" == "" ] ; then XTERMVER="Can't tell; check yourself" ; fi
							fi
							
							if [ "${XTERMVER}" == "" ] 
								then 
									echo "x-terminal-emulator seems not installed. "
									while true ; do
									read -p "Do you want to install it now [y]es or [n]o ? "  yn
										case $yn in
											[Yy]* ) 
												echo "  // OK, I will try to install it."
												AptInsatll "deepin-terminal"
												break ;;
											[Nn]*)
												echo "  // OK, you know..." 
												break ;;
											* ) 
												echo "Please answer [y]es or [n]o." ;;
										esac
									done

								else 
									echo "x-terminal-emulator is installed: "
									echo ${XTERMVER}
									CheckLastAptVersion "deepin-terminal"
									echo "  // It is your responsability to compare your version with the last one available..."
									echo
							fi
							break ;;
					[Ii]* ) 				
							echo "  // OK, I do it."
							AptInsatll "deepin-terminal"
							break ;;
					[Ssn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
					esac
				done							
				echo ""	
			;;

		"Darwin")
# MAC OSX
			EchoInverted "  //  We shall install/update various MasTer Toolbox (side)components on this Mac Computer"	
			# display osx version
			sw_vers
			echo ""
			
			# 0) Mandatory stuffs - Mac OS X
			# -------------------

				# Need bash as default shell - must change Zsh in bash from Catalina (i.e. 10.15)
				
				echo ""
				echo "  // Watch the messages displayed during installations as it may inform you about errors and/or warnings that may require your attention and actions."
				echo ""

				# Need Xcode  - Mac OS X
				if [ `pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | grep version | wc -w` -eq 0 ] 
					then 
						echo "  // Xcode  is not installed. Let's install it first'"
						xcode-select --install
					else 
						EchoInverted "  // Xcode is installed and has the following version: "
						pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep version
						echo "  // It is your responsability to verify that it is the last one though... "
						echo
				fi
				
				# Check mac ports - Mac OS X
				if [ `port version 2>/dev/null | wc -w` -eq 0 ] 
					then 
						echo "  // Mac ports is not installed. Let's try to install it now. "
						echo "  // Visit https://guide.macports.org and download the MacPorts package consistent with your OS version,"
						echo "     e.g. for OS 12 Monterey: MacPorts-2.7.2-12-Monterey.pkg "

						AskExternalComponent "MacPorts-_YOUR_VERSION_NAME" "https://guide.macports.org "

						if [ "${SKIP}" == "No" ] ; then 
						FILEXT="${RAWFILE##*.}"
 
						if [ "${FILEXT}" == "pkg" ] 
								then 
									sudo installer -pkg ${HOMEDIR}/SAR/EXEC/${RAWFILE} -target /
									#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE}
									mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
									mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/
									echo "  // "
								else 
									echo " Format not as expected (pkg). Please check or install manually"			
							fi
						fi
					else 
						EchoInverted "  // Mac ports is installed and has the following version: "
						port version
						echo "  // It is your responsability to verify that it is the last one though... "
						echo
				fi

			# 1) Update ports - Mac OS X
			# ---------------				
				EchoInverted "  // Although not mandatory, it might be advised to update the ports first. "
								
				while true; do
					read -p "Do you want to update the ports ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, it will request your admin pwd and may take time... "	
							sudo port selfupdate
							echo ""
							echo "  // Upgrading outdated ports. May take time... "
							sudo port upgrade outdated
							echo "  // Reclaiming outdated ports... "
							sudo port reclaim
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o." ;;
					esac
				done							
				echo ""			
			
			# 2) Some optional stuffs - Mac OS X
			# -----------------------
				# GITKRAKEN - Mac OS X
				# .........
					EchoInverted "  // Although not mandatory, Gitkraken is a usefull tool to sync with the last versions of MasTerEngine."
					echo "  // It requires creditentials to access MasTer private repositories on Github (contact ndo@ecgs.lu)."
					echo "  // GitKraken used to access private repositories requires a license though. "
					while true; do
						read -p "Do you want to [c]heck, [i]nstall or [s]kip GITKRAKEN  ? [c/i/s] "  cis
						case $cis in
						[Cc]* ) 				
								echo "  // OK, let's check its version. "
								GITVER=`gitkraken --version 2>/dev/null`
								GITVER2=`/Applications/GitKraken.app/Contents/MacOS/GitKraken --version 2>/dev/null ` 
								if [ "${GITVER}" == "" ] && [ "${GITVER2}" == "" ] 
									then 
										echo "Gitkraken seems not installed. "
										while true ; do
										read -p "Do you want to install it now [y]es or [n]o ? "  yn
											case $yn in
												[Yy]* ) 
													echo "  // OK, Visit https://www.gitkraken.com/, download GitKraken Client and install it manually" 
													#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null ; brew install caskroom/cask/brew-cask 2> /dev/null
													#brew install --cask gitkraken
													break ;;
												[Nn]*)
													echo "  // OK, you know..." 
													break ;;
												* ) 
													echo "Please answer [y]es or [n]o." ;;
											esac
										done

									else 
										if [ "${GITVER}" == "" ]
											then 
												echo "Gitkraken version ${GITVER2} is installed"
											else 
												echo "Gitkraken version ${GITVER} is installed"
										fi
										echo "  // It is your responsability to verify that it is the last one though..."
								fi
								break ;;
						[Ii]* ) 				
								echo "  // OK, Visit https://www.gitkraken.com/, download GitKraken Client and install it manually" 
								#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null ; brew install caskroom/cask/brew-cask 2> /dev/null
								#brew install --cask gitkraken
								break ;;
						[Ssn]* ) 
								echo "  // OK, I skip it."
								break ;;
							* )  
								echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
						esac
					done							
					echo ""			
			
				# GIMP - Mac OS X
				# ....
					EchoInverted "  // Although not mandatory, Gimp is a usefull tool to display raster images. "
					while true; do
						read -p "Do you want to [c]heck, [i]nstall or [s]kip GIMP  ? [c/i/s] "  cis
						case $cis in
						[Cc]* ) 				
								echo "  // OK, let's check its version. "
								GIMPVER=`gimp -version 2>/dev/null`
								if [ "${GIMPVER}" == "" ] 
									then 
										if [ `port list 2>/dev/null | ${PATHGNU}/grep gimp2 | wc -l` -gt 0 ] 
											then 
												GIMPVER=$(port info 'gimp2' 2>/dev/null | ${PATHGNU}/grep " @" | ${PATHGNU}/gawk '{ print $2 }' )
												echo "GIMP version ${GIMPVER} is installed"
												echo "  // It is your responsability to compare your version with the last one available..."
												#printf "%-60s%-20s\n" "--> GIMP (gimp2):" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${GIMPVER}$(tput sgr 0)"
											else
												echo "Gimp seems not installed. "
												while true ; do
												read -p "Do you want to install it now [y]es or [n]o ? "  yn
													case $yn in
														[Yy]* ) 
															echo "  // OK, I will try to install it. Please wait; download can take a few minutes"
															PortInstall "gimp2" 
															#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null ; brew install caskroom/cask/brew-cask 2> /dev/null
															#brew install --cask gimp
															break ;;
														[Nn]*)
															echo "  // OK, you know..." 
															break ;;
														* ) 
															echo "Please answer [y]es or [n]o." ;;
													esac
												done
										fi
									else 
										echo "${GIMPVER} is installed"
										CheckLasPortVersion "gimp2" 
										echo "  // It is your responsability to compare your version with the last one available..."
								fi
								break ;;
						[Ii]* ) 				
								echo "  // OK, I will try to install it. Please wait; download can take a few minutes"
								PortInstall "gimp2" 
								#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null ; brew install caskroom/cask/brew-cask 2> /dev/null
								#brew install --cask gimp
								break ;;
						[Ssn]* ) 
								echo "  // OK, I skip it."
								break ;;
							* )  
								echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
						esac
					done							
					echo ""			

			# 3) Some external components - Mac OS X
			# ---------------------------
				# gmt, GDAL - Mac OS X
				# .........
				EchoInverted "  // GMT, GDAL and some associated utilities are required for plots, images and GIS manipulations. "
				while true; do
					read -p "Do you want to install/update GMT, GDAL... ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, install GMT6 (change script if you want another version) and GDAL..."
							PortInstall "gdal +hdf5 +netcdf +openjpeg" 
							PortInstall "gmt6"
							PortInstall "graphicsmagick ffmpeg"
							# make link for portability
							GMTPATH=`which gmt6`
							mkdir -p /opt/local/bin
							sudo ln -sf ${GMTPATH} /opt/local/bin/gmt
							
							echo "  // Your GDAL version is:"
							gdalinfo --version
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# C compiler and gnu fortran - Mac OS X
				# ............................
				EchoInverted "  // clang compiler  "
				CLANGVER=`clang --version 2>/dev/null`
				if [ `clang --version 2>/dev/null  | wc -w ` -gt 0 ] 
					then 
						echo "  // Current version is:"
						echo ""
						gcc --version
				fi
				
				while true; do
					read -p "Requires clang v14 (mandataory to allows parallel processing). Do you want to install/update clang v14 compiler ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							PortInstall "clang-14"
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""


				EchoInverted "  // Maybe not mandatory but always good to have: gnu fortran.  "
				while true; do
					read -p "Do you want to install/update gnu fortran ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // Please visit https://github.com/fxcoudert/gfortran-for-macOS/releases to get the latest version for your OS, e.g. gfortran-Intel-12.1-Monterey.dmg."
							AskExternalComponent "gfortran-YOUR_VERSION.dmg" "https://github.com/fxcoudert/gfortran-for-macOS/releases "
							
							FILEXT="${RAWFILE##*.}"
 
							if [ "${FILEXT}" == "dmg" ] 
								then 
									sudo hdiutil attach ${HOMEDIR}/SAR/EXEC/${RAWFILE}
									
									LISTING=$(sudo hdiutil attach ${HOMEDIR}/SAR/EXEC/${RAWFILE} | grep Volumes) # exec and store output in variable 
    								VOL=$(echo "$LISTING" | cut -f 3)		# take 3rd element 
									
									PCKG=`find ${VOL}/ -type f -name "*.pkg"`
									sudo installer -package ${PCKG} -target /
									sudo hdiutil detach ${VOL}
									#rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE}
									mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
									mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/
									
								else 
									echo " Format not as expected (dmg). Please check or do manually"			
							fi

							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			


				# gnu functions - Mac OS X
				# .............
				EchoInverted "  // Several commands might exist by default on Mac, but getting the ${smso}gnu version${rmso} if mandatory !  "
				while true; do
					read -p "Do you want to install/update gnu utilities ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, install gnu utilities and make appropriate alias."
							PortInstall "gsed"
							PortInstall "gawk"
							PortInstall "coreutils"  	#(i.e. for gdate, gstat)
							PortInstall "findutils"		#(i.e. for find)
							PortInstall "grep"			#(i.e. for ggrep)
							PortInstall "wget"			#(needed i.e. to download the S1 orbits)
							PortInstall "curl"			

							# To be sure, prepare to add curl in PATH (see at the bottom of the script)
							WHEREISCURL=`which curl`
							PATHCURL=`dirname ${WHEREISCURL}`						
							
							# To be sure, make all gnu fct and their g-named version in PATHGNU 
							PATHGNU="/opt/local/bin"
							
							TstPathGnuFctMac "gawk" # (beware if awk already exist and would be a link pointing toward another version of awk. Replace it with our gawk)
							TstPathGnuFctMac "gsed"
							TstPathGnuFctMac "ggrep"
							TstPathGnuFctMac "gseq"
							TstPathGnuFctMac "guniq"
							TstPathGnuFctMac "greadlink"
							TstPathGnuFctMac "gxargs"
							TstPathGnuFctMac "gdu"
							
							if [ `which gdate` != "${PATHGNU}/gdate" ] ; then echo "coreutils seems not in ${PATHGNU}; please check. I arrange it at least for gdate  here though" ; fi
							TstPathGnuFctMac "gdate"

							if [ `which gstat` != "${PATHGNU}/gstat" ] ; then echo "findutils seems not in ${PATHGNU}; please check. I arrange it at least for gstat and gfind here though" ; fi
							TstPathGnuFctMac "gstat"
							TstPathGnuFctMac "gfind" 
							
							WHEREISWGET=`which wget`
							if [ "${WHEREISWGET}" != "${PATHGNU}/wget" ] ; then echo "wget is in ${WHEREISWGET} instead of ${PATHGNU}; please check. I make a link though" ; sudo ln -s "${WHEREISWGET}" ${PATHGNU}/wget 2>/dev/null ; fi
					
							cd ${HOMEDIR}
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# libraries - Mac OS X
				# .........
				EchoInverted "  // Several libraries are mandatory for MasTer compilation.  "
				while true; do
					read -p "Do you want to install/update the libraries ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I install mandatory libraries"
							PortInstall "fftw-3-long"
							PortInstall "fftw-3-single" 
							PortInstall "hdf5"
							PortInstall "tiff"
							PortInstall "libgeotiff"
							PortInstall "libxml2"
							PortInstall "lapack"
							PortInstall "libomp-devel"
							PortInstall "ImageMagick"
							PortInstall "gdal +libkml"			
							PortInstall "parallel"
							
							PortInstall "mpich"
							PortInstall "libomp"
							
							PortInstall "gsl"
							
							WHEREISCONV=`which convert`					# To be sure, prepare to add convert in PATHCONV state variable (see at the bottom of the script)
							PATHCONV=`dirname ${WHEREISCONV}`

							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# JAVA - Mac OS X
				# ....
				
				EchoInverted "  // Java is required for some processings using Fiji or ImageMagick. "
				PortInstall jdk19 
				
				echo "  // In case of instalation problem, you can also try manual install from http://www.java.com (e.g. jre-8u341-macosx-x64.dmg) following the instructions"
				echo "  //"
				echo

				echo "  // May need to define JAVA_HOME state varaiable for some application using it. I will try to do it, though in case of prblem, check its location by typing:"
				echo "  //    java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' " 
				echo "  //    and note the path to the desired version of java, though dropping everything before the sign = , e.g. /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home "  
				echo "  // Then edit add it to your bashrc as export JAVA_HOME=/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home (path may be quoted)"
				echo 
				echo "  NOTE: if some scripts crash with the following message, re-install java and then re-install Fiji: "
				echo "        << The operation couldn't be completed. Unable to locate a Java Runtime that supports (null). >>"
				echo 

				JAVAHOMEPATH=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | cut -d = -f2- | cut -d " " -f2-` 
				JVHP="\"${JAVAHOMEPATH}\""
				UpdateVARIABLESBashrc "JAVA_HOME" "export JAVA_HOME=${JVHP}"


				
				# FIJI/IMAGEJ - Mac OS X
				# ...........
				EchoInverted "  // Fiji/ImageJ is required for some processings converting images. "
				while true; do
					read -p "Do you want to [c]heck, [i]nstall or [s]kip Fiji/ImageJ  ? [c/i/s] "  cis
					case $cis in
						[Cc]* ) 
							echo "  // OK, let's check its version. "
							FIJIEXEC=`find /Applications/Fiji*/Contents/MacOS/  -type f -name "ImageJ-macosx*" 2>/dev/null`
							if [ "${FIJIEXEC}" == "" ] 
								then
									echo "Fiji/ImageJ seems not installed. "
									while true ; do
										read -p "Do you want to install it now [y]es or [n]o ? "  yn
											case $yn in
												[Yy]* ) 
													echo "  // OK, let's try to install it."
													echo "  // Visit https://imagej.net/software/fiji/downloads"
													echo "  // and click on macOSX download icon (with Java). It should install by itself in /Applications."

													break ;;
												[Nn]*)
													echo "  // OK, you know..." 
													break ;;
												* ) 
													echo "Please answer [y]es or [n]o." ;;
											esac
										done
									else 
										FIJIVERMAC=`${PATHFIJI}/ImageJ-macosx --headless -h 2>&1 > /dev/null | grep launcher`
										echo "Fiji/ImageJ seems installed and is version ${FIJIVERMAC}"
										echo  "  // It is your responsability to verify that it is the last one though..."
										
								fi
								break ;;
						[Ii]* ) 				
							echo "  // OK, let's try to install it."
							echo "  // Visit https://imagej.net/software/fiji/downloads"
							echo "  // and click on macOSX download icon (with Java). It should install by itself in /Applications."
							
							break ;;
					[Ssn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
					esac
				done							
				echo ""			

				# SNAPHU - Mac OS X
				# ......
		
				InstallSnaphu
	
				# CPXFIDDLE - Mac OS X
				# .........

				InstallCpxfiddle
				
				# GNUPLOT - Mac OS X
				# ......
				EchoInverted "  // gnuplot is used e.g. to create time series figures or baseline plots. "
				while true; do
					read -p "Do you want to install/update gnuplot ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I do it."
							PortInstall "gnuplot"
							TstPathGnuFctMac "gnuplot" 
							echo "  // "
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""			

				# PYTHON3 - Mac OS X
				# .......
				EchoInverted "  // Some scripts use python and it must be v3. "
				while true; do
					read -p "Do you want to install/update Python3 ? [y/n] "  yn
					case $yn in
					[Yy]* ) 				
							echo "  // OK, I do it."
							PortInstall "python310"
							sudo port select --set python python310 	# To make this the default Python or Python 3
							sudo port select --set python3 python310 	# To make this the default Python or Python 3
							PortInstall "py310-opencv4"
							PortInstall "py-numpy"
							PortInstall "py310-scipy"
							PortInstall "py310-matplotlib"
							PortInstall "py310-gdal"
					
							echo "  // Check python3 version:"
							python -c 'import sys ; print(sys.path)'

							echo "  // Create link for smooth call of python by all the scripts"
							sudo mkdir -p /opt/local/
							sudo mkdir -p /opt/local/bin
							WHEREISPYTHON=`which python3`				#(To know where it is installed, e.g. /usr/bin)
							sudo ln -s ${WHEREISPYTHON} /opt/local/bin/python	2>/dev/null
							sudo ln -s ${WHEREISPYTHON} /opt/local/bin/python3 2>/dev/null

							# UTM package
							echo "  // Install also utm packege for python v3 using pip. "
							curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
							python get-pip.py
							
							${HOMEDIR}/Library/Python/3.10/bin/pip install utm
														
							# MasTer Toolbox Organizer
							/opt/local/bin/python -m pip install pyqt6
							/opt/local/bin/python -m pip install appscript
	
							# MasTer Toolbox Optimisation
							/opt/local/bin/python -m pip install networkx
						
							break ;;
					[Nn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [y]es or [n]o.";;
					esac
				done							
				echo ""		
				
				# QGIS - Mac OS X
				# ....

				EchoInverted "  // Although not mandatory, QGIS is a usefull tool to work with GIS products. "
				while true; do
					read -p "Do you want to [c]heck, [i]nstall or [s]kip QGIS  ? [c/i/s] "  cis
					case $cis in
					[Cc]* ) 				
							echo "  // OK, let's check its version. "
							QGISVER=`/Applications/QGIS*/Contents/MacOS/QGIS --version 2>/dev/null`
							QGISVER2=`find /Applications/QGIS*/  -type f -name "QGIS" 2>/dev/null`
							if [ "${QGISVER}" == "" ] && [ "${QGISVER2}" == "" ] 
								then 
									echo "QGIS seems not installed. "
									while true ; do
									read -p "Do you want to install it now [y]es or [n]o ? "  yn
										case $yn in
											[Yy]* ) 
												echo "  // OK, I will try to install it."
												echo "  // Visit https://qgis.org/en/site/forusers/download.html# and download the most recent version for Mac OSX, e.g. QGIS macOS Installer Version 3.26 "
												AskExternalComponent "qgis-macosx-pr.dmg" "https://qgis.org/en/site/forusers/download.html#" 
												
												FILEXT="${RAWFILE##*.}"
 
												if [ "${FILEXT}" == "dmg" ] 
													then 
														# trick to mute the License agreement questions 
														sudo hdiutil convert  ${HOMEDIR}/SAR/EXEC/${RAWFILE}  -format UDTO -o  ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr

														LISTING=$(sudo hdiutil attach ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr | grep Volumes) # exec and store output in variable 
    													VOL=$(echo "$LISTING" | cut -f 3)		# take 3rd element 
														
														echo " // move /SAR/EXEC/QGIS(.app) in /Applications. "
														if [ -d /Applications/QGIS.app ] || [ -d /Applications/QGIS ] ; then 
															echo "  // backup first the former version available in /Applications..." 
															sudo mv -f /Applications/QGIS* /Applications/QGIS.bak.${RUNDATE}
														fi 
														sudo cp -rf ${VOL}/QGIS* /Applications/
														#sudo cp -rf ${VOL}/QGIS.app ${HOMEDIR}/SAR/EXEC/
														#mv -f /SAR/EXEC/QGIS.app /Applications/

														# detach and clean
														sudo hdiutil detach ${VOL}
														sudo rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr # ${HOMEDIR}/SAR/EXEC/${RAWFILE}
														mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
													 	mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/

														echo "  // "
													else 
														echo " Format not as expected (dmg). Please check or do manually"			
												fi		

												echo ""
												echo "  // Note that the following plugins are highly convenients. It might be a good idea to install them"
												echo "  // It is conveniently done manually from within QGIS:"
												echo "  	- point sampling tool"
												echo "  	- PointConnetor"
												echo "  	- Profile tool"
												echo "  	- Qdraw"
												echo "  	- QuickMapServices"
												echo "  	- RasterDataPlotting	(may require to install python first) "
												echo "  	- Serval"
												echo "  	- Temporal/Spectal Profile Tool"
												echo "  	- Value Tool"
												break ;;
											[Nn]*)
												echo "  // OK, you know..." 
												break ;;
											* ) 
												echo "Please answer [y]es or [n]o." ;;
										esac
									done

								else 
									echo "${QGISVER} is installed"
									echo "  // It is your responsability to verify that it is the last one though... "
									echo
							fi
							break ;;
					[Ii]* ) 				
							echo "  // OK, I do it."
							echo "  // Visit https://qgis.org/en/site/forusers/download.html# and download the most recent version for Mac OSX, e.g. QGIS macOS Installer Version 3.26 "
							AskExternalComponent "qgis-macosx-pr.dmg" "https://qgis.org/en/site/forusers/download.html#" 
							
							FILEXT="${RAWFILE##*.}"
 
							if [ "${FILEXT}" == "dmg" ] 
								then 
									# trick to mute the License agreement questions 
									sudo hdiutil convert  ${HOMEDIR}/SAR/EXEC/${RAWFILE}  -format UDTO -o  ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr

									LISTING=$(sudo hdiutil attach ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr | grep Volumes) # exec and store output in variable 
    								VOL=$(echo "$LISTING" | cut -f 3)		# take 3rd element 

									echo " // move /SAR/EXEC/QGIS(.app) in /Applications. "
									if [ -d /Applications/QGIS.app ] || [ -d /Applications/QGIS ] ; then 
										echo "  // backup first the former version available in /Applications..." 
										sudo mv -f /Applications/QGIS* /Applications/QGIS.bak.${RUNDATE} 
									fi 
									sudo cp -rf ${VOL}/QGIS* /Applications/
									#sudo cp -rf ${VOL}/QGIS.app ${HOMEDIR}/SAR/EXEC/
									#mv -f /SAR/EXEC/QGIS.app /Applications/

									# detach and clean
									sudo hdiutil detach ${VOL}
									sudo rm -f ${HOMEDIR}/SAR/EXEC/${RAWFILE}.cdr # ${HOMEDIR}/SAR/EXEC/${RAWFILE} 
									mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed
									mv ${HOMEDIR}/SAR/EXEC/${RAWFILE} ${HOMEDIR}/SAR/EXEC/Sources_Installed/

									echo "  // "
								else 
									echo " Format not as expected (dmg). Please check or do manually"			
							fi		

							echo ""
							echo "  // Note that the following ${smso}plugins${rmso} are highly convenients. It might be a good idea to install them."
							echo "  // It is conveniently done ${smso}manually from within QGIS${rmso}:"
							echo "  	- point sampling tool"
							echo "  	- PointConnetor"
							echo "  	- Profile tool"
							echo "  	- Qdraw"
							echo "  	- QuickMapServices"
							echo "  	- RasterDataPlotting	(may require to install python first) "
							echo "  	- Serval"
							echo "  	- Temporal/Spectal Profile Tool"
							echo "  	- Value Tool"
							break ;;
					[Ssn]* ) 
							echo "  // OK, I skip it."
							break ;;
						* )  
							echo "Please answer [c]heck, [i]nstall or [s]kip." ;;
					esac
				done							
				echo ""		
				
				
						
			;;
	esac
fi


#####################################################
# Now install/update MasTer Toolbox main components #
#####################################################

EchoInverted "  // MasTer Toolbox main components:"
echo 
echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "
echo "  // MasTer Toolbox is freely available (under GPL licence) from https://github.com/ndoreye/MasTerToolbox_Distribution."

	cd
   	read -e -p "Enter the path to the MasTerToolbox_Distribution (that is the directory synchronised from github). You can use Tab for autocompletion (e.g. SAR/MasTerToolbox/MasTerToolbox_DIstribution): " PATHDISTRO

	while true; do
	    if [ -d "${PATHDISTRO}" ] && [ -n "$(find "${PATHDISTRO}/" -empty)" ] ; then # [[ -d ${PATHDISTRO} ]] only test if exist
	        echo "Directory ${PATHDISTRO} exists and is not empty : Let's take the source in there...'"
	        break
	    else
	        echo "Directory ${PATHDISTRO} does not exist or is empty. Please try again."
  			read -e -p "Enter the path to the MasTerToolbox_Distribution (that is the directory synchronised from github). You can use Tab for autocompletion (e.g. SAR/MasTerToolbox/MasTerToolbox_DIstribution): " PATHDISTRO
	        break
	    fi
	done




echo
echo "  // OK, I will try to install/update MasTer Toolbox from ${PATHDISTRO}."
echo "  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

	# MASTER Engine 
	# -------------
	while true; do
		read -p "Do you want to compile MasTer Engine with the parallelisation option ? [Y/N] "  yn
		case $yn in
			[Yy]* ) 				
					echo "  // OK, I will do it."
					PARALLELOPTION="-p"
					break ;;
			[Nn]* ) 
					echo "  // OK, I will compile it without the parallel option."
					PARALLELOPTION=""
					break ;;
				* )  
					echo "Please answer [y]es or [n]o.";;
			esac	
		done							
	InstallMasTerEngine
	
	# MSBAS and EXTRACT TOOL 
	# ----------------------
	InstallMSBAS	
	
	# SCRIPTS 
	# -------
	EchoInverted "  // MasTer Toolbox scrpits are required for interfacing MasTerEngine, msbas and their automation.   "
	while true; do
		echo "Do you want to install/update MasTer Toolbox SCRIPTS using those from https://github.com/ndoreye/MasTerToolbox_Distribution ?"
		echo "  Scripts will be copied from ${PATHDISTRO}/SCRIPTS_sources to ${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT"
		echo "      and sources will be kept in ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Installed_on_${RUNDATE}/"
		echo "  If former scripts exist, they will be strored in ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Removed_on_${RUNDATE}/"

		read -p " Proceed ? [y/n] "  yn
		case $yn in
			[Yy]* ) 				
					echo "  // OK, I do it."
					
					if [ `ls -l ${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT | wc -l ` -gt 0 ] ; then 
						# Save former scripts to ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/SCRIPTS_DATE
						mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Removed_on_${RUNDATE}
						mv ${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/* ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Removed_on_${RUNDATE}/
					fi 
					# install
					cp -Rf ${PATHDISTRO}/SCRIPTS_sources/* ${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/
					# keep installed sources 
					mkdir -p ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Installed_on_${RUNDATE}/
					cp -Rf ${PATHDISTRO}/SCRIPTS_sources/* ${HOMEDIR}/SAR/EXEC/Sources_Installed/SCRIPTS_MT/Installed_on_${RUNDATE}/

					break ;;
			[Nn]* ) 
					echo "  // OK, I skip it."
					break ;;
				* )  
					echo "Please answer [y]es or [n]o.";;
			esac	
		done							
		echo ""			

	# DOC 
	# -------
	EchoInverted "  // Documentation for MasTer Toolbox is stored in ${PATHDISTRO}/DOC.   "
	while true; do
		echo "Do you want to copy/update MasTer Toolbox documentation using those from https://github.com/ndoreye/MasTerToolbox_Distribution ?"

		read -p " Proceed ? [y/n] "  yn
		case $yn in
			[Yy]* ) 
					cp -Rf ${PATHDISTRO}/DOC/* ${HOMEDIR}/SAR/MasTerToolbox/DOC/
					break
					;;
			[Nn]* ) 
					echo " OK, you know..."
					break
					;;					
				* )  
					echo "Please answer [y]es or [n]o."
					break
					;;
		esac
	done
echo 

##########################################
# update PATH and VARIABLES in ${HOMEDIR}/.bashrc #
##########################################
if [ "${TYPERUN}" == "I" ] ; then

	# PATH
	######
		echo
		EchoInverted "  // Update now some PATH in /.bashrc"
		echo "  // "
		echo "  // The /.bashrc contains the following PATH:"		
		grep "PATH=" ${HOMEDIR}/.bashrc | grep -v "export" | grep -v "#"  | ${PATHGNU}/sed -e "s/^[ \t]*//" | ${PATHGNU}/sed "s/^/\t/" # remove all leading white space then add a tab at beginning of each line for lisibility 
		echo "  // "
		EchoInverted "  // Let's review and update the PATH state variable if needed"	

		# default main
		# ------------
		#   Note that PATH to PATHGNU and /opt/local/bin MUST be before other default bin dir
		#   to prevent the computer to use default commands that may differ from the installed ones. 
		# Note that PATHGNU must be ok to use sed -i in fct UpdatePATHBashrcBEFORE
				
		echo "  // One of the most important is the ${smso}path to gnu functions (PATHGNU)${rmso}: "	
		if [ "${PATHGNU}" != "" ] ; then 
				UpdatePATHBashrcBEFORE "${PATHGNU}"
			else 
				WHEREISGNU=`which gawk`			# gawk is probably always installed in PATHGNU 
				PATHGNU=`dirname ${WHEREISGNU}`		
				UpdatePATHBashrcBEFORE "${PATHGNU}"	
		fi

		echo "  // The following is required for ${smso}python3${rmso}. Do not change it."	
		UpdatePATHBashrcBEFORE "/opt/local/bin" 

		
		# scripts 
		# -------
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/optimtoolbox"
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/MasTerOrganizer"	
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/_cron_scripts"	
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/zz_Utilities_MT_Ndo"			
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT/zz_Utilities_MT"
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/SCRIPTS_MT"	
			
		# MasTerEngine sources
		# --------------------
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/_Sources_ME"	
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine"	
	
		# msbas
		# -----
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/MasTerToolbox/MSBAS"		
	
		# EXEC
		# ----
		UpdatePATHBashrcAFTER "${HOMEDIR}/SAR/EXEC"		

		# curl
		# ----
		if [ "${PATHCURL}" != "" ] ; then 
				UpdatePATHBashrcAFTER  "${PATHCURL}"
			else
				WHEREISCURL=`which curl`
				PATHCURL=`dirname ${WHEREISCURL}`
				UpdatePATHBashrcAFTER  "${PATHCURL}"		
		fi	


	# VARIABLES (for those not done yet)
	# ##################################
		echo
		EchoInverted "  // Update now some VARIABLES in /.bashrc"
		echo "  // "
		echo "  // Currently, the state variables in the /.bashrc are :"
		cat ${HOMEDIR}/.bashrc | grep export | grep -v "#"  | ${PATHGNU}/sed -e "s/^[ \t]*//" | ${PATHGNU}/sed "s/^/\t/" # remove all leading white space then add a tab at beginning of each line for lisibility 
		echo "  // "
		echo "  // Let's review and update the ${smso}other state variables${rmso} if needed."	
		
		# Some path variables
		# -------------------
		UpdateVARIABLESBashrc "PATH=" "export PATH=\$PATH "		# must be defined first as next will be added before 
		# Paths with which some cmds are called in scripts
		UpdateVARIABLESBashrc "PATHTOCPXFIDDLE" "export PATHTOCPXFIDDLE=${HOMEDIR}/SAR/EXEC/"
		if [ "${PATHGNU}" != "" ] ; then 
				UpdateVARIABLESBashrc "PATHGNU" "export PATHGNU=${PATHGNU}"
			else 
				WHEREISGNU=`which gawk`			# gawk is probably always installed in PATHGNU 
				PATHGNU=`dirname ${WHEREISGNU}`		
				UpdateVARIABLESBashrc "PATHGNU" "export PATHGNU=${PATHGNU}"
		fi
		if [ "${PATHFIJI}" != "" ] ; then 
				UpdateVARIABLESBashrc "PATHFIJI" "export PATHFIJI=${PATHFIJI}"
			else 
				if [ "${OS}" == "Linux" ] 
					then 													
						FIJIEXEC=`find ${HOMEDIR}/SAR/EXEC/Fiji.app/ -type f -name "ImageJ-linux*"`
					else 
						FIJIEXEC=`find /Applications/Fiji*/Contents/MacOS/  -type f -name "ImageJ-macosx*"`
				fi

				PATHFIJI=`dirname ${FIJIEXEC}`	
				UpdateVARIABLESBashrc "PATHFIJI" "export PATHFIJI=${PATHFIJI}"
		fi
		if [ "${PATHCONV}" != "" ] ; then 
				UpdateVARIABLESBashrc "PATHCONV" "export PATHCONV=${PATHCONV}"
			else 
				WHEREISCONV=`which convert`					# To be sure, prepare to add convert in PATHCONV state variable (see at the bottom of the script)
				PATHCONV=`dirname ${WHEREISCONV}`
				UpdateVARIABLESBashrc "PATHCONV" "export PATHCONV=${PATHCONV}"
		fi


		# Paths to MasTer Toolbox scripts
		# -------------------------------
		UpdateVARIABLESBashrc "PATH_SCRIPTS" "export PATH_SCRIPTS=${HOMEDIR}/SAR/MasTerToolbox"

		# Paths to auxiliary data - DataSAR disks MUST be defined first ! 
		# Because UpdateVARIABLESBashrc add variable in bashrc below the title, DataSAR disks MUST be defined after in order to be defined first...
		EchoInverted "  // Update now some PATH to ORBITS and GEOID data in /.bashrc"
		UpdateVARIABLESBashrc "S1_ORBITS_DIR" "export S1_ORBITS_DIR=\${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB"
		UpdateVARIABLESBashrc "ENVISAT_PRECISES_ORBITS_DIR" "export ENVISAT_PRECISES_ORBITS_DIR=\${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ENV_ORB"
		UpdateVARIABLESBashrc "EARTH_GRAVITATIONAL_MODELS_DIR" "export EARTH_GRAVITATIONAL_MODELS_DIR=\${PATH_DataSAR}/SAR_AUX_FILES/EGM"

		while true; do
			read -p "Do you want to define an EXTERNAL_DEMS_DIR state variable (not needed ; may be conflicting with full automation with MasTer Toolbox ) ?  [y/n] "  yn
			case $yn in
				[Yy]* ) 
					echo
					echo "  // OK, let's tdo it. "
					UpdateVARIABLESBashrc "EXTERNAL_DEMS_DIR" "export EXTERNAL_DEMS_DIR=\${PATH_DataSAR}/DEMS"
					mkdir -p ${PATH_DataSAR}/DEMS
					break ;;
				[Nn]* ) 
					echo
					echo "  // OK, you know... "
					break ;;
				* ) 
					echo "Please answer [y]es or [n]o.";;
			esac
		done



		# Paths to disks
		# --------------
		echo ""
		case ${OS} in 
			"Linux") 
				echo
				EchoInverted "  // MasTer Toolbox requires a disk named DataSAR defined as a state variable and where orbits and other auxiliary data must be stored. "
				echo "  // It can either be a path to an existing directory, or better, an external disk mounted on your computer."
					NecessaryDisk "DataSAR" "/mnt/syno_sar where syno_sar mounting point is defined in /etc/fstab"
				echo "  //"
				EchoInverted "  // MasTer Toolbox may use disks named ${DISKNAME} defined as a state variable, sometimes used as hardcoded in some scripts. "
				echo "  // It might be convenient to have them as well (e.g for __SplitSession.sh), thtough it might not be mandatory but remember that you will have to edit some scripts. "
				echo "  // It can either be a path to an existing directory, or an external disk mounted on your computer."
					NecessaryDisk "1650" "/mnt/1650 where 1650 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir1"
					NecessaryDisk "3600" "/mnt/3600 where 3600 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir2"
					NecessaryDisk "3601" "/mnt/3601 where 3601 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir3"
					NecessaryDisk "3602" "/mnt/3602 where 3602 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir4"
					
				echo "  // If you have more directories or disks where you want to run more processes, you can add them also." 
				echo "  //    I suggest here two names but feel free to change the present script if you want to give them other names or add more of them. "					
					NecessaryDisk "1660" "/mnt/1660 where 1660 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir5"
					NecessaryDisk "3610" "/mnt/3610 where 3610 mounting point is defined in /etc/fstab; you can also add a path instead of a disk /Path/To_Your/Dir6"

					NecessaryDisk "SynoData" "/mnt/syno_data where syno_data mounting point is defined in /etc/fstab"
					NecessaryDisk "HOMEDATA" "/mnt/dellrack_data where dellrack_data mounting point is defined in /etc/fstab"
				;;
			"Darwin")
				echo
				EchoInverted "  // MasTer Toolbox requires a disk named DataSAR defined as a state variable and where orbits and other auxiliary data must be stored. "
				echo "  // It can either be a path to an existing directory, or better, an external disk mounted on your computer."
					NecessaryDisk "DataSAR" "/Volumes/syno_sar if it is an external disk, or provide here with a path"
				echo "  //"
				EchoInverted "  // MasTer Toolbox may use disks named ${DISKNAME} defined as a state variable, sometimes used as hardcoded in some scripts. "
				echo "  // It might be convenient to have them as well (e.g for __SplitSession.sh), thtough it might not be mandatory but remember that you will have to edit some scripts. "
				echo "  // It can either be a path to an existing directory, or an external disk mounted on your computer."
					NecessaryDisk "1650" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
					NecessaryDisk "3600" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
					NecessaryDisk "3601" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
					NecessaryDisk "3602" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
				echo "  // If you have more directories or disks where you want to run more processes, you can add them also. "
				echo "  //    I suggest here two names but feel free to change the present script if you want to give them other names or add more of them. "					
					NecessaryDisk "1660" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
					NecessaryDisk "3610" "/Volumes/You_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"

					NecessaryDisk "SynoData" "/Volumes/ou_Mounting_Point if it is an external disk, or provide here with a path to your chosen dir"
					NecessaryDisk "HOMEDATA" "Path to an additionnal internal disk if any"
				;;
		esac


	# Update specifi stuffs in ${HOMEDIR}/.bashrc 
	####################################
		
		TST=$(grep "export OMP_NUM_THREADS=" ${HOMEDIR}/.bashrc)
		if [ `echo "${TST}" | wc -w` -eq 0 ]  
			then
				# Back it up first if not done yet
				if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

				echo "#export OMP_NUM_THREADS=10,8,4" >> ${HOMEDIR}/.bashrc 	# in case someone needs to limit hardware usage while running msbas in parallel with opemp
				echo "#export OMP_NUM_THREADS=4,3,2" >> ${HOMEDIR}/.bashrc 	# in case someone needs to limit hardware usage while running msbas in parallel with opemp		
		fi



		case ${OS} in 
			"Linux") 
				TST=$(grep "# Trick to avoid error at usage of say function" ${HOMEDIR}/.bashrc)
				if [ `echo "${TST}" | wc -w` -eq 0 ]  
					then				
						# Back it up first if not done yet
						if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi

						echo "# Trick to avoid error at usage of say function" >> ${HOMEDIR}/.bashrc 	
						echo "alias say='echo "$1" | espeak -s 120 2>/dev/null'" >> ${HOMEDIR}/.bashrc 
				fi 

# 				TST=$(grep "# Trick to solve possible ImageJ issues" ${HOMEDIR}/.bashrc)
# 				if [ `echo "${TST}" | wc -w` -eq 0 ]  
# 					then				
# 						# Back it up first if not done yet
# 						if [ ! -f ${HOMEDIR}/.bashrc_${RUNDATE} ] ; then cp ${HOMEDIR}/.bashrc ${HOMEDIR}/.bashrc_${RUNDATE} ; fi
# 
# 						echo "# Trick to solve possible ImageJ issues. In case of prblm opening Terminal windows from command line, " >> ${HOMEDIR}/.bashrc 
# 						echo "#   check you DISPLAY value using the command who (shows all displays) or who -m (shows your current display) and change below accordingly" >> ${HOMEDIR}/.bashrc 
# 						echo "export DISPLAY=:0.0" >> ${HOMEDIR}/.bashrc 
# 				fi
				
				UpdatePATHBashrcAFTER "/usr/local/tigervnc/bin/"			# in case of usage of tigervnc 
				echo " "
				echo "  // Set up OPENBLAS_NUM_THREADS = 1 in bashrc (i.e. nr of threads for parallel computation) as needed for msbas optimized compilation. Higher value would cause msbas to crash."
				echo "  // Keep in mind that you set it so if one day you need to run another parallelized application that would be able to handle a higher value." 
				UpdateVARIABLESBashrc "OPENBLAS_NUM_THREADS" "export OPENBLAS_NUM_THREADS=1"
					
				echo "  //" 
				;;
			"Darwin")
				echo "  //" 
				;;
		esac

fi
echo "  //"

#########################
# Create dir in DataSAR #
#########################
EchoInverted "  // MasTer Toolbox requires auxiliary files stored in PATH_DataSAR, which is a state variable that must be defined in your /.bashrc"		
if [ -d "${PATH_DataSAR}" ] 
	then 
		echo "  // And the directory associated to PATH_DataSAR does exist ; OK."	
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/DEM
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96
		if [ ! -f ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC ] ; then 
			echo "  // I need the geoid file e.g. from here :"
			echo "  https://web.archive.org/web/20130314064801/http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC"
			echo "  // and store it in ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC"	
			while true; do
				read -p "Do you want me to download the GEOID data ? [y/n] "  yn
				case $yn in
				[Yy]* ) 				
						echo "  // OK, I do it."
						wget https://web.archive.org/web/20130314064801/http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC
						if [ -f WW15MGH.DAC ] 
							then 
								if [ -d ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/ ] ; then
										mv WW15MGH.DAC ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC
										echo "  // OK, file dowloaded and moved"
									else
										echo "  // File was dowloaded in pwd but ccan't be moved to \${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/ because the dir does not exist (yet). Try again after first installation."
								fi
							else 
								echo "Sorry, I can't get it with wget. Please proceed manually."
						fi
 						break ;;
				[Nn]* ) 
						echo "  // OK, I skip it."
						break ;;
					* )  
						echo "Please answer [y]es or [n]o.";;
				esac
			done							
		fi 
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ENV_ORB
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ENV_ORB/vor_gdr_d
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ERS
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB/AUX_POEORB
		mkdir -p ${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB/AUX_RESORB

	else 
		echo "  // However, no directory associated to the variable PATH_DataSAR can be accessed (supposed to be ${PATH_DataSAR})"	
		echo "  // Either create it and/or reboot or source your bashrc before trying again."
		echo "  // Several dirs must be created in that PATH_DataSAR before MasTer can store there mandatory data."
fi
echo ""	

#########################################
# Warning for Linux in case of cronjobs #
#########################################
echo ""	
if [ "${OS}" == "Linux" ] ; then 
	echo 
	echo
	EchoInverted "  //  As final notes: if you intend to run cron jobs, "
	EchoInverted "  //  	1) ensure that the following lines are commented in your .bashrc (if any) !! : "
	echo " 						  # If not running interactively, don't do anything"
	echo "  						 case $- in"
	echo "   						    *i*) ;;"
	echo "   						      *) return;;"
	echo " 							 esac"
	EchoInverted "  //  	2) ensure that the following state variable are exported at the beginning or the crontab !! : "
	cd 
	cat .bashrc | grep "export" | grep -v "#"
fi	
echo ""	


#############################
# S1 Precise Orbits dwnload #
#############################
while true; do
	read -p "Do you want to download the S1 precise orbits ? Beware, the first download may take a lot of fime ! [y/n] "  yn
	case $yn in
	[Yy]* ) 
		echo "  // OK, Let's do it. Please wait..."
		# Check that MasTerEngine fct exists
		if [ ! -f ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/updateS1Orbits ]
			then 
				echo "Sorry, MasTerEngine is not installed yet in /SAR/MasTerEngine/. Can't perform the S1 orbit update..."
				break	
		fi
		# check that orbit dir exists
		if [ ! -d "${S1_ORBITS_DIR}" ]
			then 
				echo "Sorry, target ${S1_ORBITS_DIR} not reachable. Can't perform the S1 orbit update..."
				break	
		fi
		# updateS1Orbits [S1_ORBITS_DIR] [-ASF] [from=YYYYMMDD]
		# All or from a given date ? :
		while true; do
			read -p "Do you want to download [a]ll the orbits or only from a given [d]ate ? [a/d] "  ad
			case $ad in
			[Aa]* ) 				
					echo "  // OK, Let's sync the whole S1 orbit data base"
					source ${HOMEDIR}/.bashrc
					OS=`uname -a | cut -d " " -f 1 `
					updateS1Orbits ${S1_ORBITS_DIR}
					break ;;
			[Dd]* ) 
					echo "  // OK, Let's sync the S1 orbit data base from a given date."
					read -p "Please provide the starting date as YYYYMMDD: "  STARTDATE
					# must be 8 characters long
					if [ ${#STARTDATE} != 8 ] ; then echo "Sorry, the date must be in the form of 8 digits as YYYYMMDD" ; echo "Try again later or use yourself the command: updateS1Orbits ${S1_ORBITS_DIR} from=YYYYMMDD " ; break ; fi
					# and only numbers
					re='^[0-9]+$'
					if ! [[ ${STARTDATE} =~ $re ]] ; then echo "Sorry, the date must be in the form of 8 digits as YYYYMMDD" >&2 ; echo "Try again later or use yourself the command: updateS1Orbits ${S1_ORBITS_DIR} from=YYYYMMDD " ; break  ; fi

					source ${HOMEDIR}/.bashrc	
					OS=`uname -a | cut -d " " -f 1 `				
					updateS1Orbits ${S1_ORBITS_DIR} from=${STARTDATE}
					
					break ;;
				* )  
					echo "Please answer all or date  [a/d]. ";;
			esac
		done							
		
		break
		;;
	[Nn]*)
		echo "  // OK, it will be done anyway when you will need it later. " 
		break
		;;
	* ) 
		echo "Please answer [y]es or [n]o.";;
	esac
done



##############################
# All done - reboot required #
##############################



if [ -f ${HOMEDIR}/.bashrc_${RUNDATE} ] 
	then 
		echo ""
		EchoInverted "  // /.bashrc has been sourced and hence is ready for this Terminal."
		echo
		EchoInverted "  // However, /.bashrc has been updated. Reboot to complete installation and hence have the /.bashrc sourced for every terminal that will further be open. "	
		# REBOOT TO SOURCE BASHRC
		while true; do
			read -p "Can I proceed to the reboot now? [y/n] "  yn
			case $yn in
			[Yy]* ) 
				echo "  // OK, I reboot. Please wait..."
				sudo reboot
				break
				;;
			[Nn]*)
				echo "  // OK, then do not forget to reboot later or source /.bashrc in any new terminal you would open. " 
				break
				;;
			* ) 
				echo "Please answer [y]es or [n]o.";;
			esac
		done
	else 
		EchoInverted "  // /.bashrc seems unchanged (no /.bashrc_${RUNDATE} exists). No need to reboot. "	
fi

echo 
echo "You may run Check_Installation.sh..."
echo 

echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "INSTALLATION/UPDATE COMPLETED - HOPE IT WORKED"
echo "++++++++++++++++++++++++++++++++++++++++++++++++"