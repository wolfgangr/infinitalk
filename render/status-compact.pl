#!/usr/bin/perl

# simple web render of infini status caches in tmp/*.bck
# ://kellerkind.rosner.lokal/pl_cgi/infini-render/status-compact.pl?select=em#stat

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

my $q = CGI->new;
# my $myself = $q->self_url;


my $tp_now = Time::Piece->new() ;
$title .= ' - ' . $tp_now->strftime($dtformat) ;

# parse file name list
# if (my @selected = $q->multi_param('select') ) {
# my @preselect  = $q->multi_param('select') ;
my @stat_fls =  sort split "\n", $status_files  ; # unless @stat_fls;

my %status = 
	map { 
		/\/(\w+)\..+$/   ; 
		my %h = ( tag => $1 , path => $_ ) ;
		($1 , \%h ) 
	} 
	@stat_fls;
	# split "\n", $status_files;

# check for preselection at url
my @all_file_tags = sort keys %status;

my %preselect;
for my $sd ($q->multi_param('select') ) {
	$preselect{ $sd } = $status{ $sd };
}
if (%preselect) { %status = %preselect } 


# read from disk
for my $sfh (values %status ) {
	next unless $sfh->{ exists } = -e $sfh->{  path }  ;
	# $sfh->{ kilroy } = 'was here' ;
	# content
	$sfh->{ status_data } = Storable::lock_retrieve( $sfh->{  path } );
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
    	my $infini_reg = $sfh->{ status_data }; # the raw stuff we got from file
    	for my $cmd (keys %{$infini_reg} ) {
		my $data_aryp = $$infini_reg{ $cmd }[2];
		# my %cmd_strh = ( cmd => $cmd , 	p17 => $p17{ $cmd } , ) ;
		$strh{ $cmd } = $p17{ $cmd } ;
		$strh{ $cmd }->{raw_vals } = $data_aryp ;
		my @scaled = map { 
			my $fc = $strh{ $cmd }->{ factors }->[ $_ ];
			my $raw = $data_aryp->[ $_ ] ;
			# $$data_aryp[ $_ ] * ( defined $fc ? $fc : 1 ) ;
			(defined $fc) ? ($raw * $fc) : $raw ;
			# $raw ;
		    } ( 0 .. $#$data_aryp ) ;

		$strh{ $cmd }->{scaled_vals } = \@scaled ;
    	}
    	$sfh->{ merged } = \%strh ; 	
}

# ~~~~~~~~~~~~ generate HTML ~~~~~~~~~

# my $q = CGI->new;
my $myself = $q->self_url;
my $myself_nqry = $q->url(-relative => 1 );

# create a navigation link jumper bar
my $navbar ="\n". '<p><table border="0" width="100%" bgcolor="#aaaaaa" ><tr>' ." \n";

# $navbar .= '<td align="center"bgcolor="#ffffff">';
# $navbar .= sprintf '&nbsp;<a href="%s">reload</a>&nbsp;', $myself ;
# $navbar .= '</td>';

$navbar .= sprintf'<form action="%s" method="get">', $myself_nqry ;

$navbar .= '<td align="center" bgcolor="#ffffff">';
$navbar .= sprintf '&nbsp;<a href="%s">show all</a>&nbsp;', $myself_nqry ;
$navbar .= '</td>';

$navbar .= '<td align="center" bgcolor="#ffffff">';
$navbar .= '<input type="submit" value="reload">' ;
$navbar .= '</td>';

for my $sf ( @all_file_tags  ) {
   if (defined $status{ $sf } ) {
	$navbar .= '<td align="center">';
	# $navbar .= sprintf '<input type="checkbox" name="select" value="%s" checked>', $sf;
	$navbar .= sprintf ' scroll <a href="%s#%s">%s</a>&nbsp;', $myself , $sf, 
		$sf ;
	$navbar .= sprintf '<input type="checkbox" name="select" value="%s" checked>', $sf;
	$navbar .= '</td>';
   } else {
	$navbar .= '<td align="center" bgcolor="#e0e0e0">';
	# $navbar .= sprintf '<input type="checkbox" name="select" value="%s">', $sf;
	$navbar .= sprintf ' load <a href="%s?select=%s">%s</a>&nbsp;', $myself_nqry  , $sf,
		$sf ;
	$navbar .= sprintf '<input type="checkbox" name="select" value="%s">', $sf;
	$navbar .= '</td>';
   }
}
$navbar .= '</form>';

$navbar .= "\n</tr></table>\n";

print CGI::header();
print CGI::start_html(-title => $title);
print CGI::h3($title);

# print "<br><hr>\n" ;
# print join "<br>\n",  @stat_fls;
# print "<br><hr><br>\n" ;
#------------------------------------------------

for my $sf ( sort keys %status  ) {
	my %statgrp = %{ $status{ $sf } } ;
	print "<br><br>\n" ;

	printf '<a name="%s">', $sf;
	print $navbar ;
	print "</a>\n" ;

	print CGI::h3( '# ' .   $sf );

	print "<tt> $statgrp{ path } </tt>" ;
	my $tp_stat = Time::Piece->new( $statgrp{ upd_t } );
	my $elapsed =  $tp_now->epoch - $tp_stat->epoch ;

	printf " - modified: %s - age: <b>%d</b> sec\n" , $tp_stat->strftime($dtformat) , $elapsed  ;

	print "<hr>\n" ;
	# print $navbar ; 	

	my %merged = %{ $statgrp{ merged } };
	for my $rt ( sort keys %merged  ) {
		# print $navbar ;
		my %reg = %{ $merged{ $rt } };
		print CGI::h4 ( sprintf "Register %s: '%s'",  $rt, $reg{ tag  }    );
		# my %reg = %{ $merged{ $reg } };

		# print '<table border="1">';
		print '<table bgcolor="#aaaaaa">';

		print '<tr bgcolor="#dddddd" >';
		for my $i (0 .. $#{$reg{fields}} ) {
			my $tif = '<td colspan ="2"  align="center" valign="bottom" >%s</td>';
			printf  $tif ,  $reg{fields}->[ $i ] ;
			# printf  $tif ,  $reg{scaled_vals}->[ $i ] ;
		}
		
		print "</tr>\n<tr>";

		for my $i (0 .. $#{$reg{fields}} ) {
			# my $tif = "<td>%s</t>";
			my $value = $reg{scaled_vals}->[ $i ]  ;
			printf  '<td align="right" bgcolor="#ffffff" ><b>&nbsp;%s&nbsp;</b> </td>' ,  
				(defined  $value ) ? $value : '####'  ;

			# $reg{scaled_vals}->[ $i ] ;	

			my $units = $reg{units}->[ $i ] || '' ;		
			if ( (defined $value) and  $reg{enums}->[ $i ] and (my $enum = $reg{enums}->[ $i ][$value ] ) )
				{ $units = $enum } # enum wins

			printf  '<td align="left" bgcolor="#e0e0e0" >&nbsp;%s&nbsp;</td>' , $units ;
				#$reg{units}->[ $i ] || '' ; # if defined $reg{units}->[ $i ] ;
				
			# printf  $tif ,  $reg{fields}->[ $i ] ;
		}
		print "</tr>";

		print "</table>";
		print "\n";
	}

	print "<br>\n";
}

#------------------------------------------------
goto ENDOFDEBUG;
print "<br><hr>\n" ;
print CGI::h3('Debug:');
print "<pre>";

print Dumper( @stat_fls, %status, %p17  );

print "</pre>";
ENDOFDEBUG:

print CGI::end_html();
