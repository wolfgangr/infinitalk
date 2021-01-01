#!/usr/bin/perl

use Data::Dumper ;
use Time::HiRes ;

my $device="../dev_infini_serial" ;

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


open my $HID, "+<" . $device or die "cannot open $device - reason: $!" ;
$/ = "\r" ;


printf $HID  "%s\r", $string;

my $response=<$HID>;
print ( substr ($response , 0,-3  ), "\n" ) ;

close $HID;

exit;


