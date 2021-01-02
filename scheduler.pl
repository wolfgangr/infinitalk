#!/usr/bin/perl
#
# round robin roundabout for serial infini communication
# - binds to infini serial device
# - (may be optinal in the future: perform power hacks)
# - process comand pipeline
# - query status -> rrd databases
# - extract static information for web display and such stuff
#
#
use strict;
use warnings;
use 5.010;

use Data::Dumper ;
use Digest::CRC qw(crc) ;
# use Time::HiRes ;
# use IO::Socket::UNIX;
use POSIX qw( );

#---- config -------------

our $Debug = 5;

our $infini_device="../dev_infini_serial" ;
our $tempdir = "./tmp";
our $infini_cmd_send_pipe = "$tempdir/cmd_send.fifo";
our $infini_cmd_read_pipe = "$tempdir/cmd_read.fifo";

our @collations = qw (conf0 conf1 conf2 conf3  stat em);


# ------ protocol definition ----- 

our %p17;
our @rrd_def;
require ('./P17_def.pl');

# I want
# - hashed index of  @rrd_def by rrd label
# - hashed index of  @rrd_def by P17 command, pointing to array of pointers

our %rrd_def_by_label;
our %rrd_def_by_cmd;

foreach my $dl (@rrd_def) {
	# I hope we have a pointer to a list....
	$rrd_def_by_label{ $$dl[0] } = $dl ; # this one works in a single run
	$rrd_def_by_cmd{ $$dl[1] } = [] ;    # collect list of P17 commands in use
}

foreach  my $dl (@rrd_def) {
	$rrd_def_by_cmd{ $$dl[1] }[ $$dl[2] -1  ] = $dl ;
}

our @rrd_cmd_list = sort keys %rrd_def_by_cmd;

debug_dumper(5, \%rrd_def_by_label , \%rrd_def_by_cmd, \@rrd_cmd_list );


# ---- prepare file handlers ------

unlink ( $infini_cmd_send_pipe, $infini_cmd_read_pipe);
POSIX::mkfifo("$infini_cmd_send_pipe", 0666) or die "canot create fifo $infini_cmd_send_pipe : $!";
POSIX::mkfifo("$infini_cmd_read_pipe", 0666) or die "canot create fifo $infini_cmd_read_pipe : $!";
debug_print (5, "fifos created ...\n");

# our $INFINI;
# our $INF_INV ;
# $INF_INV =  POSIX::open( $infini_device )   or die "canot open $infini_device : $!";
# debug_print (5,  "connected to infini\n");
# debug_dumper (5, $INF_INV );
# die "### debug #####";

open ( my $INFINI,  "+<", $infini_device ) or die "canot open $infini_device : $!";
$/ = "\r" ; # change line terminator

our $SEND_PIPE = POSIX::open($infini_cmd_send_pipe,  
	&POSIX::O_RDONLY | &POSIX::O_NONBLOCK ) 
	or die "cannot open socket $infini_cmd_send_pipe : $!";
debug_print (5,  "send pipe open\n") ;

# open(our $READ_PIPE, '>>', $infini_cmd_read_pipe ) or die "cannot open socket $infini_cmd_send_pipe: $!";

our $READ_PIPE = POSIX::open($infini_cmd_read_pipe,  
	&POSIX::O_NONBLOCK  ) 
	or die "cannot open socket $infini_cmd_read_pipe : $!";
debug_print (5,  "read pipe open\n");

# ========= main scheduler loop =============

# setup rrd iterator, start with T

while (1) {
  # while (command in pipeline)
  #   process command
  # }
  
  unless (stat_iterator() ) {
	debug_print (1, "shitt happened processing stat_iterator\n");
	last; 
  }
  
  unless (coll_iterator() ) {
        debug_print (1, "shitt happened processing coll_iterator\n");
        last;
  }
 
  # last if (happens(shit));
  # die "############### DEBUG #############";
} # ===== end of main scheduler loop



SHITTHAPPENED:
debug_print (1, "shitt happened, main loop cancelled \n");

POSIX::close $SEND_PIPE; 
POSIX::close $READ_PIPE;
POSIX::close $INFINI;

debug_print (1, "cleanup done \n");

exit;

#~~~ iterator ~~~~~~~~~~~~~
# tag list @rrd_cmd_list
# collection struct:
sub stat_iterator {
  # my $s_counter ;
  # state $time ;
  state  $s_counter = 0;
  state %res=();
  debug_print (5, "stat_iterator $s_counter\n");

  unless ( $s_counter) {  
    my $time = [ call_infini_cooked ('T') ] ;  
    # %res = { T=>$time } ;
    %res=();
    $res{'T'}=$time;
  }
  
  my $tag =$rrd_cmd_list[$s_counter]; 
  my $resp = [ call_infini_cooked ( $tag ) ] ;
  $res{$tag}=$resp ;

  debug_dumper ( 6, \%res ) ;


  # return 0 if ( $s_counter++ >= 4) ;
  # $s_counter++ >= 4 and $s_counter=0;
  if ( $s_counter++ >= $#rrd_cmd_list) {
    debug_dumper ( 5, \%res , \@rrd_def) ;
    die "#### debug in  # stat_iterator ####";
  }

  return 1;
}

# collation list : @collations
# collection struct
sub coll_iterator {
  # my $c_counter ;
  state $c_counter = 0;
  debug_print (5, "coll_iterator $c_counter\n");
  return 0 if ( $c_counter++ >= 10) ;

  return 1;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# subs....

# my_POSIX_print ($filedsc, $string )
sub my_POSIX_print {
  my ($FD, $str ) =  @_; 
  my $rv =  POSIX::write( $FD, $str, length($str) );
  die "error writing to $FD : $!" unless defined ($rv);
  return $rv;
}

sub my_POSIX_printf {
  my $FD = shift @_;
  return my_POSIX_print ( $FD, sprintf (@_));
}

# my_POSIX_readline ($FH);
sub my_POSIX_readall {
  my $FD = shift @_;
  my ($rv, $chunk);
  while ( POSIX::read( $FD, $chunk, 15 )) { $rv .= $chunk ; }
  return $rv ; 
}

# $response = call_infini_raw ($request)
sub call_infini_raw {
  my $qrys = shift @_;
  printf $INFINI ( "%s\r", $qrys) ;
  # my_POSIX_printf ($INFINI, "%s\r", $qrys) ;
  # my ($rv, $buf);
  # POSIX::write( $INFINI, $qrys, len($qrys) );
  # while ( POSIX::read
  my $rv=<$INFINI>;
  # my $rv=my_POSIX_readall($INFINI);
  return $rv;
}

# ($flag, $len, $valptr) = call_infini_cooked ( $content, [$command] )
sub call_infini_cooked {
  my $qry = compose_qry (@_);

  debug_printf (5, "content %s - query %s \n", $_[0] , $qry ); 

  my $rsp = call_infini_raw($qry);
  return (checkstring( $rsp ));
}

# $query = compose_qry ( $content, [$command] )
sub compose_qry {
  my ($cnt, $cmd) = @_;
  ($cmd) or $cmd = 'P';
  my $qry = (sprintf  "^%1s%03d%s", $cmd, (length ($cnt) +1), $cnt) ;
  return $qry;
}

# ($flag, $len, $valptr) = checkstring ($response );
sub checkstring {
  my $resp = shift @_;

  my $resp1 = substr ($resp , 0,-3  );
  my $crc = substr ($resp , -3,2  );

  ( my ($label, $len, $payload) = 
	  ($resp1 =~ /\^(\w)(\d{3})(.*)$/) )  
	  or return (0) ;

  return (0) if ( length($resp)-5-$len ) ;

  my $digest = crc($resp1, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1); 
  return (0) unless $digest == unpack ('n', $crc  )  ;

  my @data = split(',', $payload);
  return ($label, $len,  \@data  );
}


# debug_print($level, $content)
sub debug_print {
  my $level = shift @_;
  print STDERR @_ if ( $level <= $Debug) ;
}

sub debug_printf {
  my $level = shift @_;
  printf STDERR  @_ if ( $level <= $Debug) ;
}

sub debug_dumper {
  my $level = shift @_;
  print STDERR (Data::Dumper->Dump( \@_ )) if ( $level <= $Debug) ;
}
