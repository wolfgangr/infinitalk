#!/usr/bin/perl
#
use Data::Dumper ;
use strict;
use warnings;
use Digest::CRC qw(crc) ;
# use Time::HiRes ;


my $device="../dev_infini_serial" ;

our %p17;
require ('./P17_def.pl');

my $grp = shift @ARGV or die "usage: \"$0 usecode\"";


# print Dumper(\%p17);

# my @keys = (keys %p17) ;

my @keys = sortedkeys (\%p17, $grp) ;

open my $INFINI, "+<" . $device or die "cannot open $device - reason: $!" ;
$/ = "\r" ;



foreach my $querytag ( @keys ) {
  my $query = $p17{$querytag};
  # print Dumper(\$query);
  # print $query->{'tag'};
  # die "#### DEBUG ####";
  printf "%s : %s ", $querytag, $query->{'tag'}   ;
  # my @fieldlist = @$query{'fields'} ;
  my $flptr = $query->{'fields'} ;

  my $usage= $query->{'use'} ;
  # print Dumper($usage);
  # printf "usage %s %d | %s %d" , (@$usage) ;

  print "\t\tusage:  ";
  while ( my ($k, $v) = each %$usage ) {
    print "\t $k $v  ";
  } 
  print "\n";

  my $qrys = sprintf  ("^P%03d%s",  (length ($querytag) +1), $querytag) ;
  printf "\tquery:    %s\n", $qrys ;

  # really connect
  printf $INFINI  "%s\r", $qrys;
  my $response=<$INFINI>;
  printf ("\tresponse: %s\n",  substr ($response , 0,-3  ) ) ;
  print Dumper ( checkstring ($response ));

  # print Dumper(@$flptr);
  foreach my $field ( @$flptr ) {
    printf "\tfield: %s, \n", $field ;
  }
  # die "#### DEBUG ####";
}

exit;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# sortedkeys ($p17, 'tag' ) 
sub sortedkeys {
  my ($p, $tag) = @_;
  # my %p = 
  return ( 
  	sort { $$p{$a}->{'use'}->{ $tag } <=> $$p{$b}->{'use'}->{ $tag } }
        grep {  defined ( $$p{$_}->{'use'}->{ $tag } ) }
        keys %$p ) ;
}


# checkstring ($response)
# returns (flag, length, \(data) )
sub checkstring {
  my $resp = shift @_;

  my $resp1 = substr ($resp , 0,-3  );
  my $crc = substr ($resp , -3,2  );

  ( my ($label, $len, $payload) = 
	  ($resp1 =~ /\^(\w)(\d{3})(.*)$/) )  
	  or return (0) ;

  return (0) if ( length($resp)-5-$len ) ;

  my $digest = crc($resp1, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1); 
  return (0) unless $digest == unpack ('n', $crc  )  ;

  my @data = split(',', $payload);
  return ($label, $len,  \@data  );

}


