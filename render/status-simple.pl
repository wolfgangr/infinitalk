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
	$sfh->{ ihash } = Storable::lock_retrieve( $sfh->{  path } );
	# update time
	$sfh->{ upd_t } = (stat( $sfh->{  path }   ))[9];
	$sfh->{ read } = 1 ;
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
