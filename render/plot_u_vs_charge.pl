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


my ( $usage , $usage_long );
my $debug_default = 3;
my $rrd1 = '/home/wrosner/infini/parsel/infini.rrd';
# my $rrd2 = '/home/wrosner/infini/parsel/status.rrd';
my $cf =  'AVERAGE' ;

my $dt_format = '%F %T' ;
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
my $align = 1;
my $valid_rows = -1 ;
my $delim ='';
my $sep = '  ' ;
my $outfile = '';


my_die ( scalar Dumper (  $start , $end , $res ,  $rrd1 ,   $q )) if $debug ;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ cuting edge ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print Dumper ($rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      ) 

# collect parameters for database call
my @paramlist = ($rrd1, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

print  Dumper ( @paramlist ) if $debug >=3 ;

# ====== call the database ========
my ($rrd_start,$step,$names,$data)  = RRDs::fetch (@paramlist); 

my $namlen = $#$names;
my $datlen = $#$data;

my $dt = Time::Piece->new( $rrd_start);
# shall we keep timezoning?
# $dt->tzoffset = $q->param('tzoffset' ) if defined $q_all_params{ 'tzoffset' } ;
my $dt_hr = $dt->strftime($dt_format) ;
print  Dumper ( RRDs::error, $rrd_start,$step, $namlen, $datlen , $dt_hr ) if $debug >=3 ;

# my $dump = Dumper ( RRDs::error, $rrd_start,$step, $namlen, $datlen , $dt_hr );
# my_die ( scalar Dumper ( RRDs::error, $rrd_start,$step, $namlen, $datlen , $dt_hr ) );

# pre-process -V option ... valid rows - map the complement format
if ( $valid_rows < 0 ) { $valid_rows = $#$names + $valid_rows +1 ; }


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


	if ( defined $q_all_params{ grid } ) {
		$command .= "set grid\n";
	}


	$command .= "set style data lines\n";
	$command .= "set xlabel \"cumul Ah TODO \"\n";


	# $command .= "plot sin(x)";
	# $command .= "plot '-' axes x2y1";
	my $cusm = <<"EOCUSM";
a=0
cumulative_sum(x) = (a=a+x,a)
plot '-'  using (cumulative_sum(\$4)):(\$2)
EOCUSM
	
	# $command .= "plot '-'  using (\$2):(\$4) ";
	$command .= $cusm ;
	$command .="\n";
}


# my $timezone = main loop over data rows, we count by index to keep close to metal
for my $rowcnt (0 .. $#$data ) {
   my $datarow = $$data[ $rowcnt ];			# the real data
   my $rowtime = $rrd_start + $rowcnt * $step;		# time is calculated

   # skip for data row's with too many NaN s
   my $defcnt = 0 ;
   foreach ( @$datarow )  {  $defcnt++ if defined $_ }
   next unless ($defcnt >= $valid_rows) ;

   # time string format selection
   my $timestring;

   if ( defined $q_all_params{mysqltime} ) {
      my $dtr = Time::Piece->new($rowtime); 
      # mysql datetime format YYYY-MM-DD HH:MM:SS
      $timestring =  sprintf ( "%s %s", $dtr->ymd , $dt->hms ) ;
   } elsif ( defined $q_all_params{humantime} ) {   #   (  ) {  
      # human readable datetime e.g. 22.12.2020-05:00:00 , i.e. dd.mm.yyyy-hh:mm:ss
      my $dtr = Time::Piece->new($rowtime);
      $timestring =  sprintf ( "%s-%s", $dtr->dmy('.') , $dtr->hms );
   } else {
     $timestring = sprintf "%s" , $rowtime ;
   }

   my $dataline = my_join ( $delim, $sep, $timestring, @$datarow ) ;
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
sub my_join {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
}

# resemble "die", supply ($message $usage)
sub my_die {
	my ($msg, $usage) = @_ ;
	print $q->header(-type =>  'text/html',  -charset => 'utf8' );
	print "<html><pre>";
	print "\n$msg\n";
	print "============================================================" . "\n";
	print $usage ;
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



