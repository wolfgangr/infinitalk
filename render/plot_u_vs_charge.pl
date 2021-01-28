#!/usr/bin/perl
#
# extract data from rrd and write csv data
# TODO transfer from cmdline tool to cgi
#
# HACK: this is converterd from CSV exporter to gnuplotter, doc does not apply!
# ... and in turn boilerplated form 
# https://github.com/wolfgangr/perl_rrd_cgi/blob/master/rrdXYplot.pl


use warnings;
use strict;
use CGI();
use Time::Piece();
use  RRDs;
use Cwd 'abs_path'   ;
use List::Util qw(first);

my ( $usage , $usage_long );
# my $usage = '';
# my $usage_long = '';

my $debug_default = 3;
my $rrd1 = '/home/wrosner/infini/parsel/infini.rrd';
# my $rrd2 = '/home/wrosner/infini/parsel/status.rrd';
my $cf =  'AVERAGE' ;

my $dt_format = '%FT%T' ;
# my $dt_format = "%m/%d/%yT%H:%M:%S";
my $tempfile_prefix="../tmp/plot/plot-";


my $q = CGI->new;
my %q_all_params = $q->Vars ;
our $debug  = (defined $q_all_params{debug}) ?  $q->param('debug')  : $debug_default ;
if ($debug) { use Data::Dumper::Simple ;}

my $start  = $q->param('start')  || 'e-1d';
my $end    = $q->param('end')  || 'n';
my $res = 5 ; # both rrd are configured that way

# replace cgi params by fixed settings
# my $rrdfile = $rrd1 ; # TODO
# my $align = 1;
# my $valid_rows = -1 ;
# my $delim ='';
# my $sep = '  ' ;
# my $outfile = '';


# my_die ( scalar Dumper (  $start , $end , $res ,  $rrd1 ,   $q )) if $debug ;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ cuting edge ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print Dumper ($rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      ) 

# collect parameters for database call
my @paramlist = ($rrd1, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a';  # if $align ;
push @paramlist, ('-r', $res ) ; # if $res ; 

print  Dumper ( @paramlist ) if $debug >=3 ;

# ====== call the database ========
my ($rrd_start,$step,$names,$data)  = RRDs::fetch (@paramlist); 

my $namlen = $#$names;
my $datlen = $#$data;

my $dt = Time::Piece->new( $rrd_start);
# shall we keep timezoning?
# $dt->tzoffset = $q->param('tzoffset' ) if defined $q_all_params{ 'tzoffset' } ;
my $dt_hr = $dt->strftime($dt_format) ;

my $i_U = first { $$names[$_] eq 'U_batt'  }  (0..$#$names);
my $i_I = first { $$names[$_] eq 'I_batt'  }  (0..$#$names);


my_die ( scalar  Dumper ( RRDs::error, $rrd_start,$step, $names, $datlen , $dt_hr, $i_U , $i_I  )) if $debug  ;
my_die ( "could not find  \$i_U or \$i_I field" ,  $i_U ,$i_I ) unless ((defined $i_U) and (defined $i_I) );


# my $i_U = first { $array[$_] eq 'whatever' } 0..$#array;


# ~~~~~~~~~~~~~~~~~~ prep plot cmd header ~~~~~~~~~~

# $gnuplot = "/usr/bin/gnuplot";
my $gnuplot = `which gnuplot`  or my_die ("gnuplot executable not found - installed?")   ;
chomp $gnuplot;
# $tempfile_prefix="/var/www/tmp/sqlplot/plot-";
# my $tempfile_prefix="./tmp/plot/plot-";

my $tempfile_body = $tempfile_prefix . time; 
my $temppng  = $tempfile_body . '.png';
my $tempdata = $tempfile_body . '.data';
my $templog  = $tempfile_body . '.log';



my $command;

my $testcmd= <<ENDOFCOMMAND;
set term png
set output "$temppng"
test
ENDOFCOMMAND


if ( defined $q_all_params{test} ) {
# if (1) {
	$command = $testcmd ;
} else {
	$command= "set term png";
	$command .= "\n";
	$command .="set output \"$temppng\"\n";
	$command .= "set timestamp \"\%d.\%m.\%Y \%H:\%M\"\n";
	$command .= "set ylabel \"U (batt) in V \"\n";
	$command .= "set title \"infini LTO energy cycle\" \n";
	$command .= "set grid\n";

	$command .= "set style data lines\n";
	$command .= "set xlabel \"cumul Ah \"\n";

	# $command .= "plot '-'  using (\$1):(\$2) ";
	$command .= "set palette model RGB \defined (0 'yellow' , 1 'orange', 2 'red', 3 'magenta' , 4 'blue', 5 'green')\n";
	$command .= "set zdata time\n";
	# $command .= "set key off\n";
	$command .= "unset key \n";
	# $command .= "set timefmt '$dt_format' \n";
	$command .= "plot '-'   using 1:2:3  title '' w l lc palette \n";
	# $command .="\n";
}

my $cumulAh = 0;
my $last_I=0; 
# my $timezone = main loop over data rows, we count by index to keep close to metal
for my $rowcnt (0 .. $#$data ) {
   my $datarow = $$data[ $rowcnt ];			# the real data
   my $rowtime = $rrd_start + $rowcnt * $step;		# time is calculated

   my $U_batt  = $$datarow[ $i_U]  ;
   my $I_batt  = $$datarow[ $i_I] ;
   $last_I = $I_batt+0 if (defined $I_batt );
   $cumulAh += $last_I *( $step /  3600)  ;

   next unless ((defined $U_batt) and (defined $I_batt) );

   # my $cumulAh += $I_batt * $step / 3600 ; # integrate overs tep interval and convert to hrs
   # next unless (defined $U_batt and defined $I_batt );
   # skip for data row's with too many NaN s
   # my $defcnt = 0 ;
   # foreach ( @$datarow )  {  $defcnt++ if defined $_ }
   # next unless ($defcnt >= 2) ;

   # time string format selection
   my $timestring;
   # my $dtr = Time::Piece->new($rowtime);
   # $timestring =  $dtr->strftime($dt_format );

   $timestring = sprintf "%s" , $rowtime ;
   # $dt_format 

   my $dataline = sprintf ('%f %f %s',  $cumulAh , $U_batt, $timestring );
   $command .= $dataline . "\n";
} 

# close OF if ( $outfile) ;

# goto RENDER;

# RENDER:
open ( GNUPLOT, "| $gnuplot > $templog 2>&1" ) or my_die ("cannot open gnuplot")   ;
print GNUPLOT $command    or my_die  ("cannot send data to gnuplot") ;
close GNUPLOT || gnuploterror($command, $templog);

print "Content-type: image/png\n\n";
print `cat -u $temppng`;   

exit;   # leave the stuff for debugging

unlink $temppng;        # don't check for an error any more
unlink $tempdata;
unlink $templog;


exit ;

#=========================================

# my_join : extended join with delim and seperators
# my_join ( delim, sep, @stuff )
sub my_join_DONOTUSE {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
}

# resemble "die", supply ($message $usage)
sub my_die {
	my ($msg, $usage) = @_ ;
	# my ($msg) = @_ ;
	print $q->header(-type =>  'text/html',  -charset => 'utf8' );
	print "<html><pre>";
	print "\n$msg\n";
	print "============================================================" . "\n";
	# print $usage ;
	print "</pre></html>";
	exit;

}


sub gnuploterror {

  my ($command, $logfile) = @_;

  print "Content-type: text/html\n\n";
  print "<html><head><title>Gnuplot Error </title></head><body>\n";
  print "<h1>Gnuplot Error:</h1>";

  print "<h3>gnuplot reported:</h3>\n"; 
  print "<pre>\n";
  print  `cat -u $logfile`;
  print "</pre>\n";

  print "<h1>gnuplot command was:</h1>\n";
  print "<pre>\n";
  print  $command;
  print "</pre>\n";

  print "</body></html>";

  # $dbh->disconnect;

  exit;
}



