#!/usr/bin/perl
#
use Data::Dumper ;
use strict;
use warnings;

# import('./P17_def.pm6');
# use P17_def ;
our %p17;
our @rrd_def;
require ('./P17_def.pl');

# my %P17 = $P17_def::p17;

print Dumper(\%p17);

print Dumper(\@rrd_def);
# print Data::Dumper->Dump( [ %p17 , %rrd_def ] );

