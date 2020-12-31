# DEVICE="-F $1"
# DEVICE="-F /dev/ttyChargery"
DEVICE="-F ../dev_infini_serial"
stty $DEVICE -a
echo "------ apply changes -----"
stty $DEVICE raw 
stty $DEVICE 2400
# sleep 1
# stty $DEVICE 19200 raw
stty $DEVICE time 50 
stty $DEVICE -echo -echoe -echok -echoctl -echoke
echo "------ done -------"
stty $DEVICE -a
# sleep 1
echo "----- simple output -----"
stty $DEVICE
