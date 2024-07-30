#! Gnuplot mastershell for plotting stuff
# DO NOT CHANGE BELOW AS IT IS CALLED AND EDITED BY PlotTS.sh
#set size square
set grid
set xdata time 
set timefmt "%Y%m%d"
set format x "%Y\n%b"
# XRANGE
#set xtics 0.5 font "Helvetica,20" rotate by 45 right 
#set xtics font "Helvetica,20" rotate by 45 right

#set yrange [*:*] 
#set yrange [*:*] reverse


#set yrange [*:*] reverse
#set yrange [-0.12:0.04]
set terminal postscript eps enhanced color font 'Helvetica,10'
set term post landscape "Helvetica" 9

# some styles
set style line 1 lc rgb "blue" lt 1 lw 2 pt 7 ps 1.2   # --- blue
set style line 2 lc rgb "red" lt 1 lw 2 pt 5 ps 1.2   # --- red
set style line 3 lc rgb "green" lt 1 lw 2 pt 4 ps 0.8   # --- green
set style line 4 lc rgb "blue" lt 1 lw 1   # --- blue
set style line 5 lc rgb "red" lt 1 lw 2   # --- red
set style line 6 lc rgb "green" lt 1 lw 1   # --- green

### Plot Time series 
set xlabel 'Date'
set ylabel 'DISPLACEMENT (m)'

set title "TITLE"
set key left bottom
#set key right top
#set key off
set title noenhanced

# ERUPTIONS (red)
############
set style rect fc lt -1 fs solid 0.15 noborder
# change below with updated info from tables
#ERUPTIONS_TABLE
 
# EQ SWARMS (blue)
############
#set style rect fc rgb "#0000FF" fs solid 0.15 noborder
# change below with updated info from tables
#EQSWARMS_TABLE
 
# ASYMETRIC GEOMETRIES
######################
#set style rect fc lt -0.2 fs solid 0.15 noborder
# change below with updated info from tables
#ASYMACQ_TABLE
 
# SATELLITES COVER
##################
#SATCOVER_TABLE


# POLARISATION CHANGE
#####################
#POLCHANGE_TABLE

# EQ 
#####
#EQ_TABLE

# Other events - whaterver you want 
####################################
#OTHER_TABLE

# FIT
#####
f(x) = a+ b*x 
a = 1
b = 1e-8
fit f(x) 'PATH_TO_EW_EPS.txt' using 1:3 via a,b
annualrateEW(b) = ( b * 3153600000. )
# ANNUALRATEEW

g(x) = c+ d*x 
c = 1
d = 1e-8
fit g(x) 'PATH_TO_NS_EPS.txt' using 1:3 via c,d
annualrateNS(d) = ( d * 3153600000. )
# ANNUALRATENS

h(x) = e+ f*x 
e = 1
f = 1e-8
fit h(x) 'PATH_TO_UD_EPS.txt' using 1:3 via e,f
annualrateUD(f) = ( f * 3153600000. )
# ANNUALRATEUD



timestamp = strftime("%Y-%m-%d %H:%M:%S", time(0))
timestamp = "Created by AMSTer at INSTITUTE on: " . timestamp
set label timestamp at screen 0.01,0.01 left font "Helvetica,8" textcolor rgbcolor "#2a2a2a"

set output "PATH_TO_EPS.eps" 

# Adjust the top and bottom margins
# set tmargin at screen 0.9
set bmargin at screen 0.12

CMD_LINE
