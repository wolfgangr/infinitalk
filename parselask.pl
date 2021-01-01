#!/usr/bin/perl

use Data::Dumper ;
use Time::HiRes ;

# my $device="/dev/hidraw0" ;

my $device="../dev_infini_serial" ;

# $| = 1; # don't buffer output

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


open HID, "+<" . $device or die "cannot open $device - reason: $!" ;
$/ = "\r" ;

# HID->autoflush(1);

# printf   "%s|\n", $string;
printf HID  "%s\r", $string;
# parsel_print ($string) ;

my $response=<HID>;
print ( substr ($response , 0,-3  ), "\n" ) ;

close HID;

exit;

#~~~~~~~~~~~~~~~~~~~~
#
# usb chunked_print (handle, string)
# don'oveerrun 2400 baud processor
#
sub parsel_print {
  my $str = shift @_;
  # $str .= "\r";
  # while ($my chunk = substr($str, 
  my @chunks = unpack("(A4)*", $str);
  push @chunks, "\r";
  print Dumper (@chunks);
  my $timestamp = Time::HiRes::time();
  foreach my $chunk (@chunks) {
	  # my $nexdue = Time::HiRes::time() + 0.04 ; # wait one 
	  # Time::HiRes::usleep (max(0, $timestamp +0.05));
	  
	  my $timediff = 0.05 + ($timestamp - Time::HiRes::time())  ;
	  printf " >%f< ", $timediff ;
	  if ($timediff > 0) { print "#" ; Time::HiRes::sleep($timediff ) } ;
	  # sleep(1) ;
	  # $timestamp = Time::HiRes::time() ;
	  print $chunk, '|'; 
	  print HID  $chunk;
	  # syswrite HID , $chunk;

	  $timestamp = Time::HiRes::time() ;
  }
  print "\n" ;
  # die "======= DEBUG =========";
}

