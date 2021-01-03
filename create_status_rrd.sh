#!/bin/bash
# skript to generate rrd files
# 
# inv_day: unixtime %s /  (24*60*60) i.e. fractional days since epoc
# work mode: int 0 ... 6
# power status: last 6 fields of PS and field 1, 5 of EMINFO in littleendian
# warn status 21 bits - littleendian - hope this works....


/usr/bin/rrdtool create status.rrd --start NOW --step 5  \
DS:inv_day:GAUGE:10:18600:U  \
DS:work_mode:GAUGE:10:0:6 \
DS:pow_status:GAUGE:10:0:65536 \
DS:warn_status:GAUGE:10:0:2097152 \
RRA:LAST:0.2:2:777600 \
RRA:LAST:0.2:60:210000
