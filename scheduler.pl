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
use Data::Dumper ;
use strict;
use warnings;
use Digest::CRC qw(crc) ;
# use Time::HiRes ;
# use IO::Socket::UNIX;
use POSIX qw( );

our $infini_device="../dev_infini_serial" ;
our $tempdir = "./tmp";
our $infini_cmd_send_pipe = "$tempdir/cmd_send.fifo";
our $infini_cmd_read_pipe = "$tempdir/cmd_read.fifo";

our @collations = qw (conf0 conf1 conf2 conf3  stat em);



our %p17;
our @rrd_def;
require ('./P17_def.pl');

unlink ( $infini_cmd_send_pipe, $infini_cmd_read_pipe);
POSIX::mkfifo("$infini_cmd_send_pipe", 0666) or die "canot create fifo $infini_cmd_send_pipe : $!";
POSIX::mkfifo("$infini_cmd_read_pipe", 0666) or die "canot create fifo $infini_cmd_read_pipe : $!";
# print "fifos created ...\n";

our $INFINI = POSIX::open( $infini_device ) or die "canot open $infini_device : $!";

our $SEND_PIPE = POSIX::open($infini_cmd_send_pipe,  
	&POSIX::O_RDONLY | &POSIX::O_NONBLOCK ) 
	or die "cannot open socket $infini_cmd_send_pipe : $!";
# print "send pipe open\n";

# open(our $READ_PIPE, '>>', $infini_cmd_read_pipe ) or die "cannot open socket $infini_cmd_send_pipe: $!";

our $READ_PIPE = POSIX::open($infini_cmd_read_pipe,  
	&POSIX::O_NONBLOCK  ) 
	or die "cannot open socket $infini_cmd_read_pipe : $!";
# print "read pipe open\n";


# die "############### DEBUG #############";

POSIX::close $SEND_PIPE; 
POSIX::close $READ_PIPE;
POSIX::close $INFINI;

exit;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# subs....

# $response = call_infini_raw ($request)
sub call_infini_raw {
  my $qrys = shift @_;
  printf $INFINI  "%s\r", $qrys;
  my $rv=<$INFINI>;
  return $rv;
}

# ($flag, $len, $valptr) = call_infini_cooked ( $content, [$command] )
sub call_infini_cooked {
  my $qry = compose_qry (@_);
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
