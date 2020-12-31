#!/usr/bin/perl
#

# my $device="/dev/hidraw0" ;
my $device="../dev_infini_serial";

open HID, $device or die "cannot open $device - reason: $!" ;

$/ = "\r"  ; # set line deli,iter to CR

while (<HID>) {

	print ( substr ($_ , 0,-2  ), "\n" ) ;

}

