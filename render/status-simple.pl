#!/usr/bin/perl

# simple web render of infini status caches in tmp/*.bck

use strict;
use warnings;

use CGI () ; #  qw/:standard/;
use Data::Dumper::Simple ;
use Time::Piece;
use Storable();
use utf8 ;


my $dtformat = '%F - %T' ;
my $title = "Infini status";
my $status_files = `ls -1 ~wrosner/infini/parsel/tmp/*.bck` ;

# expansion of protocol 
our %p17 = ();
require '../P17_def.pl' ;

#~~~~~~~~ end of config ~~~~~

my $tp_now = Time::Piece->new() ;
$title .= ' - ' . $tp_now->strftime($dtformat) ;

# parse file name list
my @stat_fls =  sort split "\n", $status_files;
my %status = 
	map { 
		/\/(\w+)\..+$/   ; 
		my %h = ( tag => $1 , path => $_ ) ;
		($1 , \%h ) 
	} 
	@stat_fls;
	# split "\n", $status_files;

# read from disk
for my $sfh (values %status ) {
	next unless $sfh->{ exists } = -e $sfh->{  path }  ;
	# $sfh->{ kilroy } = 'was here' ;
	# content
	$sfh->{ hash } = Storable::lock_retrieve( $sfh->{  path } );
	# update time
	$sfh->{ upd_t } = (stat( $sfh->{  path }   ))[9];
	$sfh->{ read } = 1 ;
}

# merge the labelling into the hash
#	e.g.:
#   'GOV' => { 'use' => {  'conf2' => 1   },
#              'tag' => 'AC input voltage acceptable range for feed power'
#           'fields' => [ 'highest voltage',  'lowest voltage', .. , ..  ],
#           'units'  => [ 'V',   'V',    'V',   'V'    ],
#          'factors' => [ '0.1',  '0.1',  '0.1', '0.1'   ],  # optional
#    },


for my $sfh (values %status ) {
    	my %strh ; # where we collect a string info tree per state file
    	my $infini_reg = $sfh->{ hash }; # the raw stuff we got from file
    	for my $cmd (keys %{$infini_reg} ) {
		# my $data_aryp = $$infini_reg{ $cmd }[2];
		# my %cmd_strh = ( cmd => $cmd , 	p17 => $p17{ $cmd } , ) ;
		$strh{ $cmd } = $p17{ $cmd } ;
		$strh{ $cmd }->{data} = $$infini_reg{ $cmd }[2];
    	}
    	$sfh->{ strh } = \%strh ; 	
}

# ~~~~~~~~~~~~ generate HTML ~~~~~~~~~

# my $q = CGI->new;

print CGI::header();
print CGI::start_html(-title => $title);
print CGI::h3($title);

print join "<br>\n",  @stat_fls;
print "<br>\n" ;

print CGI::h2('Debug:');
print "<pre>";

print Dumper( @stat_fls, %status, %p17  );

print "</pre>";

print CGI::end_html();
