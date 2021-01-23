#!/usr/bin/perl
use strict;
use warnings;
use CGI () ; #  qw/:standard/;
use Data::Dumper::Simple ;
use Time::Piece;
use utf8 ;

my $dtformat = '%F - %T' ;
my $title = "Infini status";
my $status_files = `ls -1 ~wrosner/infini/parsel/tmp/*.bck` ;

#~~~~~~~~ end of config ~~~~~

my $tp_now = Time::Piece->new() ;
$title .= ' - ' . $tp_now->strftime($dtformat) ;

my @stat_fls =  sort split "\n", $status_files;

my %status = map { /\/(\w+)\..+$/   ; ($1 , $_ ) } @stat_fls ;


# ~~~~~~~~~~~~ generate HTML ~~~~~~~~~

# my $q = CGI->new;

print CGI::header();
print CGI::start_html(-title => $title);
print CGI::h3($title);

print join "<br>\n", @stat_fls ;
print "<br>\n" ;

print CGI::h2('Debug:');
print "<pre>";

print Dumper( %status , @stat_fls);

print "</pre>";

print CGI::end_html();
