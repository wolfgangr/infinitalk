#!/usr/bin/perl

use Data::Dumper ;
use Time::HiRes ;
use Digest::CRC qw(crc) ;


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

print Dumper ( checkstring ($response ));

close $HID;

exit;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# checkstring ($response)
# returns (flag, length, \(data) )
sub checkstring {
  my $resp = shift @_;
  my $resp1 = substr ($response , 0,-3  );
  my $crc = substr ($response , -3,2  );
  # ^D0251496161801100008000000
  # \^(D)(\d{3})(.*)(\d{2})$
  ( my ($label, $len, $payload) = 
	  ($resp1 =~ /\^(\w)(\d{3})(.*)$/) )  
	  or return (0) ;

  # compare real length with announced length
  return (0) if ( length($resp)-5-$len ) ;
 
  # https://crccalc.com/ - we have CRC-16/XMODEM of $resp1

  # my $mycrc =  crc16($resp1) ;

  # my $ctx = Digest::CRC->new(width=>16, init=>0x0000, xorout=>0x0000, 
  #                        refout=>0, poly=>0x1021, refin=>0, cont=>1);

  $digest = crc($resp1, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1); 
  return (0) unless $digest == unpack ('n', $crc  )  ;

  # $ctx->add($resp1) ;
  # $digest = $ctx->digest;

  my @data = split(',', $payload);
  return ($label, $len,  \@data , 
	  #  sprintf("%04x", unpack ('n', $crc,  )), 
	  #  sprintf("%04x", $digest) 
  );

}
