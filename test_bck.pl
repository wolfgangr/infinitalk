#!/usr/bin/perl

use Storable(lock_retrieve);
use Data::Dumper;

my $filename = shift @ARGV;
$hashref = lock_retrieve ( $filename );
print Dumper ($hashref );
