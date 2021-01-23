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

my $logfile = './infini-status.log' ;

my $q=CGI->new;


DEBUG ($q) ;


exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# debug with continued laoding
sub debug {
  my $in = shift;
  print
    "\n<pre><code>\n",
    $in,
    "\</code></pre>\n",
  ;
}


# final die like debug
sub DEBUG {
    my $in = shift;
    print CG::header;
    print CGI::start_html('### DEBUG ###');
    debug ( $in) ;
    print CGI::end_html;
  ;
  exit; # is it bad habit to exit from a sum??
}
