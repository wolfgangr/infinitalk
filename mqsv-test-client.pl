#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT IPC_NOWAIT );
use IPC::Msg();
use Cwd qw( realpath );
use Time::HiRes () ;


my $ftokid = 1;
my $server = './scheduler.pl';
my $ftok_server = ftok ( my_realpath ($server) );
my $ftok_my = ftok ( my_realpath ($0) );

printf "\$0: %s, realpath: %s \n", $0, realpath ($0);


my $mq_srv = IPC::Msg->new($ftok_server ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	 or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_server ); 
my $mq_my  = IPC::Msg->new($ftok_my     ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_my  );

print "setup done \n";

my $cnt =1;
while (1) {
  # rolling ms
  my $ts = (int (Time::HiRes::time * 1000)) % 0x100000000 ;
  my $msg = sprintf ("%08x:%08x::GS" , $ftok_my, $ts );
  print "sending .... ", $msg ;
  $mq_srv->snd (1, $msg );
  print " ... done \n";

  sleep 1;

  my $buf;
  $mq_my->rcv($buf, 256, 1 , IPC_NOWAIT  );

  print $buf , "\n" if $buf  ;

  sleep 4;
  $cnt++;


}

exit 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


sub my_realpath {
  my $p = shift ;
  my $pwd = `pwd`;
  chomp $pwd;
  return sprintf ( "%s/%s", $pwd, $p );

}
