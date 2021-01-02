#!/bin/bash
# skript to generate rrd files
# 
# min in current year, to check for time drift, dst effects ....
# 3³ * 2³
# 21 bits - hope this works....


/usr/bin/rrdtool create status.rrd --start NOW --step 5  \
DS:inv_min:GAUGE:10:0:527100  \
DS:pow_status:GAUGE:10:0:216 \
DS:warn_status:GAUGE:10:0:2097152 \
DS:work_mode:GAUGE:10:0:6 \
RRA:LAST:0.2:2:777600 \
RRA:LAST:0.2:60:210000
