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
my $dt_format = '%F %T' ;

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
	my $dt_line = Time::Piece->strptime(    $fields[0] , $dt_format   ) ;
	print " line date is " . $dt_line->datetime .' -> '. $dt_line->epoch ."\n";
	# comparations to go here ======================= TODO

	# my $newstate = sprintf "%02x,%04x,%06x", $wm , $ps_2bits, $ws_bits ;
	my @chunks = split ',', $fields[2];
	next unless ( (scalar @chunks) == 3) ;
	my ($wm, $ps_2bits, $ws_bits) = @chunks ;

	print Dumper ( @fields, @chunks) ;
	print Dumper ($wm, $ps_2bits, $ws_bits );

	my $ps_2b_x = hex ($ps_2bits);
	# printf ($ps_2b_x
	my @ps;
	for (0 .. 7) {
		unshift @ps, ( $ps_2b_x & 0x3 ) ;
		$ps_2b_x >>= 2;
	}

	print Dumper (@ps );


	# print Dumper ( $dt_line );
	# print $dt_line->datetime;
	last;
	#===============================
}
close $LOG ;

# DEBUG ($q, $from , $until ) ;
print "~~~~~~~~~~~~~<br><hr>END\n";




exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

