#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT  );
use IPC::Msg();
use Cwd qw( realpath );

my $ftokid = 1;
my $server = './mqsv-tester.pl';
my $ftok_server = ftok ( realpath ($server) );
my $ftok_my = ftok ( realpath ($0) );

my $mq_srv = IPC::Msg->new($ftok_server ,  S_IWUSR |  IPC_CREAT );
my $mq_my  = IPC::Msg->new($ftok_my     ,  S_IRUSR |  IPC_CREAT );

print "setup done \n";

my $cnt =1;
while (1) {
  my $msg = sprintf ("%08x:client test message No %s" , $ftok_my, $cnt );
  print "sending .... ", $msg ;
  $mq_srv->snd (3, `date`);
  print " ... done \n";


  my $buf;
  $mq_my->rcv($buf, 256);

  print $buf , "\n";

  sleep 5;
  $cnt++;


}


