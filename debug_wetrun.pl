#!/usr/bin/perl
#
use Data::Dumper ;
use strict;
use warnings;

# import('./P17_def.pm6');
# use P17_def ;
our %p17;
require ('./P17_def.pl');

# my %P17 = $P17_def::p17;

# print Dumper(\%p17);

# my @keys = (keys %p17) ;

my @keys = (
	sort { $p17{$a}->{'use'}->{'conf0'} <=> $p17{$b}->{'use'}->{'conf0'} } 
	map {  defined ( $p17{$_}->{'use'}->{'conf0'} ) ? ($_) : () }
	keys %p17) ;

foreach my $querytag ( @keys ) {
  my $query = $p17{$querytag};
  # print Dumper(\$query);
  # print $query->{'tag'};
  # die "#### DEBUG ####";
  printf "key: %s , label: %s \n", $querytag, $query->{'tag'}   ;
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

  # print Dumper(@$flptr);
  foreach my $field ( @$flptr ) {
    printf "\tfield: %s\n", $field ;
  }
  # die "#### DEBUG ####";
}



