#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT IPC_NOWAIT );
use IPC::Msg();
use Cwd qw( realpath );
use Time::HiRes qw( usleep ) ;
use Digest::CRC qw(crc) ;

# -- process command line args
my ($cmd, $cnt);

if ($#ARGV == 0) {
 $cnt  = shift @ARGV;
 $cmd = 'P' ;
} elsif ($#ARGV == 1) {
  ($cmd , $cnt) = @ARGV;
} else {
	die "usage: $0 [cmd = S|P] [content] ";
}

# -- mq configuration

my $poll_intvl = 2e5 ; # polling interval in microseconds

my $ftokid = 1;
my $server = './scheduler.pl';
my $ftok_server = ftok ( realpath ($server) );
my $ftok_my = ftok ( realpath ($0) );

# printf "\$0: %s, realpath: %s \n", $0, realpath ($0);


my $mq_srv = IPC::Msg->new($ftok_server ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	 or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_server ); 
my $mq_my  = IPC::Msg->new($ftok_my     ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	or die sprintf ( "cant create client mq using token >0x%08x< ", $ftok_my  );

# print "setup done \n";

do {
  # rolling ms
  my $ts = (int (Time::HiRes::time * 1000)) & 0xffffffff ;
  my $msg = sprintf ("%08x:%08x:%s:%s" , $ftok_my, $ts, $cmd , $cnt );
  print "sending .... ", $msg ;
  $mq_srv->snd (1, $msg );
  print " ... done \n";

  # sleep 1;

  my $buf;

  # quickly poll mq
  my $i =0;
  do { usleep $poll_intvl ; $i++ } 
  	until ($mq_my->rcv($buf, 1024, 1 , IPC_NOWAIT  )) ;
  
  printf "polls: %d - result: %s \n ", $i, $buf   ;

  # crc debugging
  if (1) {
    my ($c_ts, $s_ts, $flag, $head , $x_crc , $payload) = split ':', $buf ;
    my $barersp = sprintf "%s%s", $head , $payload;
    my $digest = crc($barersp, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1);
    my $s_dgst = simple_crc($barersp);
    my $infini_hack = infini_crc_hack($barersp);
    printf "bare response:    %s    - digest: 0x%04x - infini CRC: 0x%s - infini-hack-crc: 0x%04x \n",
   	 $barersp , $digest, $x_crc , $infini_hack ;
  }

} until (1);  # yes, this was a loop tester before

exit 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# replace reserved characters in CRC
#
sub infini_crc_hack {
  my $in = shift;
  my $dg = crc($in, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1);
  return infini_crc_byte_hacker ($dg & 0xff) 
    + 0x100 * (infini_crc_byte_hacker ( int ($dg / 0x100 ))) ;
}

sub infini_crc_byte_hacker {
  $b = shift;
  return $b unless ( $b == 0x0d or $b == 0x28 or $b == 0x0a );
  return $b+1 ;
 
}




sub simple_crc {
  my $pl = shift ;
  my $rv = 0;
  # my $char '';
  # while ($schar, $pl) = split( undef, $pl, 2) {
  for my $i ( 0 .. length ($pl)-1 ) {
    $rv += ord ( substr $pl, $i, 1);
  }
  return $rv & 0xffff ;
}
