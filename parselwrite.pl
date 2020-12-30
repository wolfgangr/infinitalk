#!/usr/bin/perl

my $device="/dev/hidraw0" ;


my ($cmd, $cnt);

if ($#ARGV == 0) {
 $cnt  = shift @ARGV;
 $cmd = 'P' ;
} elsif ($#ARGV == 1) {
  ($cmd , $cnt) = @ARGV;
} else {
	die "usage: $0 [cmd = S|P] [content] ";
}

my $string = (sprintf  "^%1s%03d%s", $cmd, (length ($cnt) +1), $cnt) ;


open HID, ">" . $device or die "cannot open $device - reason: $!" ;


printf   "%s|\n", $string;
printf HID  "%s\r", $string;


close HID;


