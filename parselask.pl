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

print Dumper ( checkstring ($response ));

close $HID;

exit;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# checkstring ($response)
# returns (flag, length, \(data) )
sub checkstring {
  my $resp = shift @_;
  # my $coresubstr ($response , 0,-3  );
  # ^D0251496161801100008000000
  # \^(D)(\d{3})(.*)(\d{2})$
  ( my ($label, $len, $payload, $crc) = 
	  ($resp =~ /\^(D)(\d{3})(.*)(\d{2})/) )  
	  or return (0) ;
  my @data = split(',', $payload);
  return ($label, $len, \@data , $crc);

}
