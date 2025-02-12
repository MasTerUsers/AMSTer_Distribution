#!/bin/bash 
# Little trick used to launch a script (eg script2) in a new terminal (call it terminal2 for clarity) 
# from a script (say script1) in a terminal(call it terminal1 for clarity) in Linux.
#
# (In Mac os, this is done e.g. by osascript)
#
# Attention : $SHELL refers to the shell executed when loggin in. Ensure it is bash. 
#             (You can check it by running at terminal echo $SHELL)
# 
# To launch a script2 in a new terminal2 from a script1 in terminal1 with the options, add  
# a line in your script1 like:
#    x-terminal-emulator -e /PathTo/LaunchTerminal.sh /PathTo/script2.sh [optional arguments here]
# When you run script1 in terminal1, it should open a new terminal2 and run there script2 with its options
#
# Dependencies : - x-terminal-emulator
#
# Note: In principle this could be replaced by adding a function in your script1
# 			LaunchTerminalFct()
# 			{
# 			"$@"
#			exec "$SHELL"
# 			}
# 		and calling in script1
# 			x-terminal-emulator -e /path/to/script2 LaunchTerminalFct [optional arguments here]
# 		Don't forget to put "$@" at the end of the script
# 
# New in Distro V 1.0:	- Based on developpement version 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
"$@"
exec "$SHELL"
