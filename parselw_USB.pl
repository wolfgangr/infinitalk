#!/usr/bin/perl

use Data::Dumper ;
use Time::HiRes ;
use USB::LibUSB;


my $device="/dev/hidraw0" ;

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


# open HID, ">" . $device or die "cannot open $device - reason: $!" ;

# HID->autoflush(1);

my $ctx = USB::LibUSB->init();
#  idVendor=0665, idProduct=5161
my $handle = $ctx->open_device_with_vid_pid( 0x0665, 0x5161 );

$handle->set_auto_detach_kernel_driver(1);
$handle->claim_interface(0);


printf   "%s|\n", $string;
# printf HID  "%s\r", $string;
parsel_print ( $handle ,  $string ) ;


close HID;

exit;

#~~~~~~~~~~~~~~~~~~~~
#
# usb chunked_print (handle, string)
# don'oveerrun 2400 baud processor
#
sub parsel_print {
  my ($hdl, $str) =  @_;
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
	  # print HID  $chunk;
	  # syswrite HID , $chunk;
          $hdl->control_transfer_write(0x21, 0x9, 0x200, 0, $chunk);
	  $timestamp = Time::HiRes::time() ;
  }
  print "\n" ;
  # die "======= DEBUG =========";
}

