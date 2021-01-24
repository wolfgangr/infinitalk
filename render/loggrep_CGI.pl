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
# use Data::Dumper::Simple;  # conditinal on debug - performance killer

my $logfile = './infini-status.log' ;
my $dt_format = '%F %T' ;


# defaults ...
# my $nolines = 0;
# my $nodata = 0;

#-- end of config ---------

my $q=CGI->new;
# print $q->header(-type => 'text/plain' ,
# 	-charset => 'utf8' );

# the one for all CGI param hash
my %q_all_params = $q->Vars ;


my $from   = $q->param('from' )   || 0;
my $until  = $q->param('until')   || time()  ;

my $sep_mj = $q->param('sep_mj')  || ';';
my $sep_mn = $q->param('sep_mn')  || ',';
# my $nolines= $q->param('nolines') ||  0;
# my $nodata = $q->param('nodata')  ||  0;

my $debug  = $q->param('debug')   || 1;
if ($debug) { use Data::Dumper::Simple ;}


# eval time params - 
my $dt_from  = Time::Piece->new( $from  );
my $dt_until = Time::Piece->new( $until );
my $epc_from  = $dt_from->epoch ;
my $epc_until = $dt_until->epoch ;



# ------------- start output
#
# print $q->header(-type => 'text/plain' ,
#         -charset => 'utf8' );


my $html_title = sprintf 'infini status change %s to  %s', 
	$dt_from->strftime( $dt_format) ,  $dt_until->strftime( $dt_format)  ;

print $q->header(-type => 'text/html' ,
         -charset => 'utf8' );
print $q->start_html(-title => $html_title);
print "<pre>\n";

#---------------

# print Dumper($q) if $debug;
print Dumper( %q_all_params ) if $debug;

# print "from: $from  ->  " . $dt_from->strftime( $dt_format)  ->  $epc_from \n";
# print "until $until  ->  " . $dt_until->strftime( $dt_format)  ->  $epc_until \n";
my $timedebugger = "%s: %s  ->  %s  ->  %d \n";
printf $timedebugger , 'from ', $from , $dt_from->strftime( $dt_format) ,  $epc_from ;
printf $timedebugger , 'until', $until, $dt_until->strftime( $dt_format) ,  $epc_until ;




open ( my $LOG , '<', $logfile ) or die "cannot open $logfile : $!"; 

my $cnt_start=0;
my $cnt_lines=0;
while (<$LOG>) {
	# 2021-01-21 15:08:53 - status chaged old->new:##,####,######:05,4541,000003
	my @fields = /^([\d\-]{10} [\d\:]{8})[^:]*:([\d\#\,]{14}):([\d\,]{14})$/ ;

	next unless ( (scalar @fields) == 3) ;
	my $dt_line = Time::Piece->strptime(    $fields[0] , $dt_format   ) ;

	# select time interval
	unless($cnt_lines) {	
		$cnt_start++;
		next if ( (my $dt_epoc = $dt_line->epoch ) < $epc_from ) ;
	}
	last if ( (my $dt_epoc = $dt_line->epoch ) > $epc_until ) ;
	$cnt_lines++;
	
	next if ( defined $q_all_params{nolines} ) ;

	if ( defined $q_all_params{dt_epoc}) {
		print $dt_epoc ;
	} else {
		print $dt_line->strftime( $dt_format) ;
	}

	if ( defined $q_all_params{nodata}) { print "\n"; next  ; }


	# print " line date is " . $dt_line->datetime .' -> '. $dt_epoc  ."\n";
	# comparations to go here ======================= TODO

	# my $newstate = sprintf "%02x,%04x,%06x", $wm , $ps_2bits, $ws_bits ;
	my @chunks = split ',', $fields[2];
	next unless ( (scalar @chunks) == 3) ;
	my ($wm, $ps_2bits, $ws_bits) = @chunks ;

	# print Dumper ( @fields, @chunks) ;
	# print Dumper ($wm, $ps_2bits, $ws_bits );

	my $ps_2b_x = hex $ps_2bits;
	# printf ($ps_2b_x
	my @ps;
	for (0 .. 7) {
		unshift @ps, ( $ps_2b_x & 0x03 ) ;
		$ps_2b_x >>= 2;
	}
	# print Dumper (@ps);

	my $ws_x = hex  $ws_bits ;
	my @ws;
	for (0 .. 21) {
		unshift @ws , ( $ws_x & 0x01 );
		$ws_x >>= 1;
	}
	# print Dumper (@ws);

	my $mr_ps = join $sep_mn  , @ps;
	my $mr_ws = join $sep_mn  , @ws;
	my $mr_rv = join $sep_mj , '',  $wm, $mr_ws, $mr_ps   ; 

	# print "machine readable line : ";
        print	$mr_rv . "\n";
	# print Dumper ( $dt_line );
	# print $dt_line->datetime;
	# last;
	#===============================
}


printf " -- DONE -- matching lines: start=%d , count=%d\n", $cnt_start, $cnt_lines  ;
print $cnt_start .' '. $cnt_lines ;

close $LOG ;

# DEBUG ($q, $from , $until ) ;
# print "~~~~~~~~~~~~~<br><hr>END\n";
print "\n</pre>";
print $q->end_html();


exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

