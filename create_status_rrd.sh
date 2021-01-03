#!/bin/bash
# skript to generate rrd files
# 
# inv_day: unixtime %s /  (24*60*60)
# 3³ * 2³
# 21 bits - hope this works....


/usr/bin/rrdtool create status.rrd --start NOW --step 5  \
DS:inv_day:GAUGE:10:18600:U  \
DS:pow_status:GAUGE:10:0:216 \
DS:warn_status:GAUGE:10:0:2097152 \
DS:work_mode:GAUGE:10:0:6 \
RRA:LAST:0.2:2:777600 \
RRA:LAST:0.2:60:210000
