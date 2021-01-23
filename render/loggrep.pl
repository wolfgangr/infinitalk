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

# print $q->header(-type => 'text/cs',
# 		-title => 'infini log file export',
# 		-encoding => 'utf8' 
# );
# print $q->header(-type => 'text/csv');
print $q->header(-type => 'text/plain'); 

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
# debug with continued laoding
sub debug {
  # my $in = shift;
  print
    "\n<pre><code>\n",
    Dumper(@_);
    "\</code></pre>\n",
  ;
}


# final die like debug
sub DEBUG {
    # my $in = shift;
    print CGI::header;
    print CGI::start_html('### DEBUG ###');
    debug ( @_  ) ;
    print CGI::end_html;
  ;
  exit; # if we prefer not to clobber the log file
  # die " ============ hit the wall ========= ";
}
