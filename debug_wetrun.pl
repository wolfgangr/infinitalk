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


foreach my $querytag (keys %p17) {
  my $query = $p17{$querytag};
  # print Dumper(\$query);
  # print $query->{'tag'};
  # die "#### DEBUG ####";
  printf "key: %s , label: %s \n", $querytag, $query->{'tag'}   ;
  # my @fieldlist = @$query{'fields'} ;
  my $flptr = $query->{'fields'} ;

  # print Dumper(@$flptr);
  foreach my $field ( @$flptr ) {
    printf "\tfield: %s\n", $field ;
  }
  # die "#### DEBUG ####";
}



