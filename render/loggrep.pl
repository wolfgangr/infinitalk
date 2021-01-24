#!/usr/bin/perl
#
# # grep log file by time and return 
# 	stripped fast K.I.S.S. variant
#
# params: from until [nodata | nolines]
# 	(from before until, rest can be permutated)
#
#
#  output sth like ... 
#     unixtime [ ; work mode ; power status ; warn status ]
# 1611380067;05;1,1,1,1,1,0,0,1;0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,1
# 1611418466;05;1,1,1,1,1,0,0,1;0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,1
# 345 4      <- first matching line, number of matching lines


use warnings;
use strict;
# use CGI();
use Time::Piece();
# use Data::Dumper::Simple;

my $logfile = './infini-status.log' ;
my $dt_format = '%F %T' ;

# my $q=CGI->new;
# print $q->header(-type => 'text/plain' ,
#	-charset => 'utf8' );

# my $from  = $q->param('from' ) || 0;
# my $until = $q->param('until') || time()  ;
# my $dt_from  = Time::Piece->new( $from  );
# my $dt_until = Time::Piece->new( $until );
# my $epc_from  = $dt_from->epoch ;
# my $epc_until = $dt_until->epoch ;

# defaults ...
my $nolines = 0;
my $nodata = 0;
my $sep_mj =':';
my $sep_mn =',';

# ... may be overwritten:
my ( $from, $until);
while ( my $arg = shift @ARGV) {
	if ( $arg =~ /^nolines$/  ) { $nolines = 1  ; next }
	if ( $arg =~ /^noidata$/  ) { $nodata  = 1  ; next }

	if ( $arg =~ /^semicolons_mj$/  ) { $sep_mj =';'  ; next }
	if ( $arg =~ /^commas_mj$/      ) { $sep_mj =','  ; next }
	if ( $arg =~ /^semicolons_mn$/  ) { $sep_mn =';'  ; next }
	if ( $arg =~ /^colons_mn$/      ) { $sep_mn =':'  ; next }

	if ( $arg+0 and !  $from  ) { $from    = $arg  ; next }
	if ( $arg+0 and !  $until ) { $until   = $arg  ; next }
	die " usage: $0 [from [until]] [nodata | nolines] - or K.I.S.S.:   rtfS";
}


# my $epc_from  = $from  = 0;
# my $epc_until = my $until = time()  ;
unless (defined $from)  { $from  = 0 } 
unless (defined $until) { $until = time() }



# print "from: $from  ->  $dt_from  ->  $epc_from \n";
# print "until $until  ->  $dt_until  ->  $epc_until \n";




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
		next if ( (my $dt_epoc = $dt_line->epoch ) < $from ) ;
	}
	last if ( (my $dt_epoc = $dt_line->epoch ) > $until ) ;
	$cnt_lines++;

	# fist chance to take the short way
	next if $nolines ;

	# oputput time in seconds
	print $dt_epoc;  

	# second chance to take the short way
	if ($nodata) { print "\n" ; next }

	# data processing 
	# thus is was generated:
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

	my $mr_ps = join $sep_mn , @ps;
	my $mr_ws = join $sep_mn , @ws;

	# print "machine readable line : ";
        printf "%.1s%.2s%.1s%s%.1s%s\n" , $sep_mj,$wm , $sep_mj,$mr_ps , $sep_mj,$mr_ws;
}
# printf " -- DONE -- matching lines: start=%d , count=%d\n", $cnt_start, $cnt_lines  ;
print $cnt_start .' '. $cnt_lines ;

close $LOG ;

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

