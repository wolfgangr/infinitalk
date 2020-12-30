#!/usr/bin/perl


my $string = shift @ARGV;

my $device="/dev/hidraw0" ;

open HID, ">" . $device or die "cannot open $device - reason: $!" ;


printf   "^%s|\n", $string;
printf HID  "^%s\r", $string;


close HID;


