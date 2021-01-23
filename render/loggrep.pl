#!/usr/bin/perl
#
# # grep log file by time and return either 
# - line range , 
# - time list  
# - line times
# - raw lines
# - csv expanded lines
# - human readable lines
# assume sorted entries
#


use warnings;
use strict;
use CGI();
use Time::Piece();
use Data::Dumper::Simple;

my $logfile = './infini-status.log' ;

my $q=CGI->new;
print $q->header(-type => 'text/plain' ,
	-charset => 'utf8' );

my $from  = $q->param('from' );
my $until = $q->param('until');
my $dt_from  = Time::Piece->new( $from  );
my $dt_until = Time::Piece->new( $until );
my $epc_from  = $dt_from->epoch ;
my $epc_until = $dt_until->epoch ;

print "from: $from  ->  $dt_from  ->  $epc_from \n";
print "until $until  ->  $dt_until  ->  $epc_until \n";




open ( my $LOG , '<', $logfile ) or die "cannot open $logfile : $!"; 

while (<$LOG>) {
	# 2021-01-21 15:08:53 - status chaged old->new:##,####,######:05,4541,000003
	my @fields = /^([\d\-]{10} [\d\:]{8})[^:]*:([\d\#\,]{14}):([\d\,]{14})$/ ;

	next unless ( (scalar @fields) == 3) ;
	my $dt_line = Time::Piece->new( $fields[0]) ; 

	print Dumper ( @fields, $dt_line);
	last;
	#===============================
}
close $LOG ;

# DEBUG ($q, $from , $until ) ;
print "~~~~~~~~~~~~~<br><hr>END\n";




exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

