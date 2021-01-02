# infinitalk
## handle communication with Voltronic infiniSolar 10 k type inverters
  
### Disclaimer:
This is early draft!  
Dont expect no good but real evil.  
Infini 10k are made to handle batteries large enough to blow away your basement and set your house under fire.  
Sure you want to control them by pre-pre-pre-mature software snippets?  

### snippets

    setstty-RS485.sh  
set serial line parameters
  
    parselread.pl  
simple replacement for the infamous `cat < /dev/foo`  
transfers the `<CR>`to `<LF>` and cuts the non printable CRC  
still handy for basic line setup debugging  
  
    parselwrite.pl  
it's brother at the other end, resembling `echo ^P005BAR > /dev/foo`  
transfers core commands like `ID` to P17 slang aka `^P003ID<cr>`  
  
    parselw_USB.pl  
modified version for use at the USB-hid-device.  
Tried to choke speed, but did not succed.  
Looks like there is much buffering under perl's and kernel's hood  
Still can only transfer commands no longer than `^P003XY<cr>`  
  
    parselask.pl  
single command to perform both read and write  
mainly for test puposes  
implements vailidity tests (header, length, CRC) and splits payload into array  
    
    P17_def.pl   
Translation of the P17 protocol specification to a perl hashed data structure  
to be `require()`d into any code aware of data semantic  
So we can maintain data field interpretation in a central point, without fiddling in the code  
added some syntax to group and order P17 commands  
  
    debug_def.pl  
List content of `P17_def.pl`  
Main purpose: early check for syntax and fundamental logical errors after edits  
  
    debug_dryrun.pl  
somewhat elaborated version  
lists all commands including their data field labels  
Handy for comparison with printed P17 sommand spec  
  
    debug_wetrun.pl  
now does a real connect and data retrieval to the inverter  
mapped with labels, scaling and unit, as far as provided in `P17_def.pl`  
nice to compare real data with field labels, to check for correct association  
have even misused it as pre-alpha console supplement for SolarPower config visualisation  

------

last update: 2021-01-01 - v0.03


