#!/usr/bin/perl
#

my $device="/dev/hidraw0" ;

open HID, $device or die "cannot open $device - reason: $!" ;

$/ = "\r"  ; # set line deli,iter to CR

while (<HID>) {

	print $_ , "\n" ;

}

