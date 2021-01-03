#!/bin/bash

cd ~wrosner/infini/parsel
PROCESS='scheduler.pl'

STARTER="./$PROCESS"
PRESTARTER='./setstty-RS485.sh' 
CALLER='/usr/bin/perl'
LOGFILE='/var/log/wrosner/watchdog_infini.log'
UPDLOG='/var/log/wrosner/infini_scheduler.log'

# uncomment this 2 line for debug
# echo -n "chargery rrd watchdog entered " >> $LOGFILE
# date >> $LOGFILE


# exit - nothing to do if rrdtest reports success
./rrdtest.pl *.rrd   2>> $LOGFILE | tail -n1 >> $LOGFILE 
STATUS=${PIPESTATUS[0]}
if [ $STATUS -eq 0 ] ; then
	exit
fi



echo -n "infini rrd watchdog triggered at " >> $LOGFILE
date >> $LOGFILE

ps ax | grep "./$PROCESS" | grep '/usr/bin/perl' >> $LOGFILE

killall $PROCESS  >>  $LOGFILE 2>&1
sleep 1 
killall -9 $PROCESS  >> $LOGFILE 2>&1
sleep 1

$PRESTARTER  >> $LOGFILE 2>&1
./scheduler.pl  >> $UPDLOG 2>&1   &


