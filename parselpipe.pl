#!/usr/bin/perl
#

# usage: 
# cat some.log | parselpipe.pl | less

# my $device="/dev/hidraw0" ;
# my $device="../dev_infini_serial";

# open HID, '-' or die "cannot open $device - reason: $!" ;

$/ = "\r"  ; # set line deli,iter to CR

while (<>) {

	print ( substr ($_ , 0,-3  ), "\n" ) ;

}

