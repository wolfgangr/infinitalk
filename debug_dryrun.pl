#!/usr/bin/perl
#
use Data::Dumper ;
use strict;
use warnings;

our %p17;
require ('./P17_def.pl');

my $grp = shift @ARGV or die "usage: \"$0 usecode\"";


# print Dumper(\%p17);

# my @keys = (keys %p17) ;

my @keys = sortedkeys (\%p17, $grp) ;

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

