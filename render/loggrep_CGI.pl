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
# call like
# 	./loggrep_CGI.pl?from=1611320488&until=1611320542&nodata
# url options:
# valued: from until debug sep_mj sep_mn
# simple: nodata nolines dt_epoc noheader nofooter simplefooter
#   noheader nohtmltag

use warnings;
use strict;
use CGI();
use Time::Piece();
# use Data::Dumper::Simple;  # conditinal on debug - performance killer

my $logfile = './infini-status.log' ;
my $dt_format = '%F %T' ;

our %p17;
require '../P17_def.pl';

# defaults ...
# my $nolines = 0;
# my $nodata = 0;



# array of P17 defs matching retrieved status array
my @labelizer_p17 = labelizer();


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

my $debug  = (defined $q_all_params{debug}) ?  $q->param('debug')  : 1;
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

my $do_htmltag = ! defined $q_all_params{ nohtmltag };
$do_htmltag = 1 if (defined $q_all_params{htmltab}) ;

my $html_title;
if (! defined $q_all_params{ noheader }) {
	$html_title = sprintf 'infini status change %s to  %s', 
		$dt_from->strftime( $dt_format) ,  $dt_until->strftime( $dt_format)  ;

	print $q->header(-type => 'text/html',	 -charset => 'utf8' );
} else {
	print $q->header(-type => 'text/plain',  -charset => 'utf8' );

	# 'nohtmltag' supresses html and pre tags as well
	$do_htmltag = 0 ;
}

# open html but keep at <pre> for nearly pretty monospace preamble printing
if ( $do_htmltag ) {
	print $q->start_html(-title => $html_title);
	print "<pre>\n";
}



#---------------

# print Dumper($q) if $debug;
print Dumper( %q_all_params ) if $debug;
print Dumper( %p17 ) if $debug;
print Dumper(@labelizer_p17 )  if $debug;

# print "from: $from  ->  " . $dt_from->strftime( $dt_format)  ->  $epc_from \n";
# print "until $until  ->  " . $dt_until->strftime( $dt_format)  ->  $epc_until \n";

unless (defined $q_all_params{ nopreamble }) {
	my $timedebugger = "%s: %s  ->  %s  ->  %d \n";
	printf $timedebugger , 'from ', $from , $dt_from->strftime( $dt_format) ,  $epc_from ;
	printf $timedebugger , 'until', $until, $dt_until->strftime( $dt_format) ,  $epc_until ;
}


# open <table> if required
if (defined $q_all_params{htmltab}) {
	print "</pre>\n";
	print '<table border ="1">' ."\n";
}


open ( my $LOG , '<', $logfile ) or die "cannot open $logfile : $!"; 

my $cnt_start=0;
my $cnt_lines=0;
my @laststate =();
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
	#------------------------
	my $dt_line_print ;
	if ( defined $q_all_params{dt_epoc}) {
		$dt_line_print = $dt_epoc ;
	} else {
		$dt_line_print = $dt_line->strftime( $dt_format) ;
	}

	if ( defined $q_all_params{nodata}) { 
		print "$dt_line_print\n"; 
		next  ; 
	}


	# print " line date is " . $dt_line->datetime .' -> '. $dt_epoc  ."\n";
	# comparations to go here ======================= TODO

	# my $newstate = sprintf "%02x,%04x,%06x", $wm , $ps_2bits, $ws_bits ;
	my @chunks = split ',', $fields[2];
	next unless ( (scalar @chunks) == 3) ;
	my ($wm, $ps_2bits, $ws_bits) = @chunks ;

	my $ps_2b_x = hex $ps_2bits;
	my @ps;
	for (0 .. 7) {
		unshift @ps, ( $ps_2b_x & 0x03 ) ;
		$ps_2b_x >>= 2;
	}

	my $ws_x = hex  $ws_bits ;
	my @ws;
	for (0 .. 21) {
		unshift @ws , ( $ws_x & 0x01 );
		$ws_x >>= 1;
	}

	unless ( defined $q_all_params{chg_verbose}) {

		# ----- prepare for printing -------
		my $mr_ps = join $sep_mn  , @ps;
		my $mr_ws = join $sep_mn  , @ws;
		my $mr_rv = join $sep_mj , $dt_line_print,  $wm, $mr_ws, $mr_ps   ; 

		# print "machine readable line : ";
		print	$mr_rv . "\n";
	} else  {
		# ------------ what status changed ---------------
		# my @newstate = ( [ $dt_epoc ], [  $wm ],  \@ps, \@ws ,) ;
		my @newstate = (  $dt_epoc ,   $wm ,  @ps, @ws ) ;
		my @changed =();
		my $ccnt =0;
		if (@laststate) {
			# @changed =  diff_ary2D( \@newstate, \@laststate)      ;
			@changed = map { $newstate[$_] - $laststate[$_]    } (0 .. $#newstate );
		}
	
	    if ( defined $q_all_params{chg_verbose}) {
		# we print unconditionally gproup leader since we think some change will be
		print $dt_line_print , "\n";
		for my $i ( grep { $changed[$_] } (1 .. $#changed) ) {
			my $lbl = $labelizer_p17[ $i ];
			my $enm = $lbl->{ 'enum' };
			printf "\treg %s ( %s : %s ) changed %s -> %s \n", 
				$lbl->{ 'parent' }, $lbl->{ 'p_tag' }, $lbl->{ 'tag' },
				$$enm[ $laststate[ $i ] ] , 
				$$enm[ $newstate[  $i ] ] ;

		}
	
		print Dumper ( @newstate, @changed, @laststate) if $debug ;
		@laststate = @newstate;
	    } elsif (defined $q_all_params{htmltab}) {
		print "<tr><td> ----------- Debug ----------</td></tr>\n";
	    	# html vertical tab
    	    }
	}

}	 # ============= end of main <> loop ==============
close $LOG ;

# close html table
if (defined $q_all_params{htmltab}) {
        print "</table>\n";
        print "<pre>";
}

# render in footer in pre / plain
unless ( defined $q_all_params{nofooter}) {
	if ( defined $q_all_params{simplefooter}) {
		print $cnt_start .' '. $cnt_lines ;
	} else {
		printf " -- DONE -- matching lines: start=%d , count=%d\n", 
			$cnt_start, $cnt_lines  ;
	}
}

# close html syntax
if ($do_htmltag) {
	print "\n</pre>";
	print $q->end_html();
}

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# element wise subtract 2 dim arrays
# dimesionality must match
sub diff_ary2D {
	my ($A, $B) = @_;
	my @C =() ;
	for my $i (0 .. $#$A) {
		my @c = ();
		for my $k (0 .. $#{$$A[$i]}   ) {
			push @c, ( $$A[$i][$k] - $$B[$i][$k]) ;  
		}
		push @C, \@c ;
	}
	return @C;
}



# here is the other end of the pipeline:
# https://github.com/wolfgangr/infinitalk/blob/710f2a6f3ae19491d0b2a0345e191ca6502794bd/scheduler.pl#L357
# # warn status 21 bits - littleendian - hope this works....
#    my @ws_ary =   @{$res{'WS'}[2]};
#
#       # power status: last 6 fields of PS and field 1, 5 of EMINFO in littleendian
#      my @ps_ary = ( @{$res{'PS'}[2]}[-6 .. -1], @{$res{'EMINFO'}[2]}[0,5] ); 
#      # work mode: int 0 ... 6
#     my $wm = $res{'MOD'}[2][0] ;

sub labelizer {
	# our %p17
	my @rv;
	push @rv, { tag => 'time'  };
	push @rv, p17_reg_field_tagged ( 'MOD'   , 0 );
	for (16..21) { push @rv, p17_reg_field_tagged ( 'PS' , $_ ); }
	push @rv, p17_reg_field_tagged ( 'EMINFO' , 0 );
	push @rv, p17_reg_field_tagged ( 'EMINFO' , 5 );
	for (0..21)  { push @rv, p17_reg_field_tagged ( 'WS' , $_ ); } 
	return @rv;
}

# %p17 etracted tagger = p17_reg_field_tagged ( $registerflag, $field_index )
sub p17_reg_field_tagged {
	my ($rtag, $i) = @_;
	my $reg = $p17{$rtag} ;
	return {
		parent => $rtag,
		p_tag => $reg->{tag},
		tag => $reg->{fields}[$i] ,
		# fields
		enum => $reg->{enums}[$i] ,
	}

}
