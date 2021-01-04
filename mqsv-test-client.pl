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

my $mq_srv = IPC::Msg->new($ftok_server ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	 or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_server ); 
my $mq_my  = IPC::Msg->new($ftok_my     ,  S_IWUSR | S_IRUSR |  IPC_CREAT )
	or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_my  );

print "setup done \n";

my $cnt =1;
while (1) {
  my $msg = sprintf ("%08x:client test message No %s" , $ftok_my, $cnt );
  print "sending .... ", $msg ;
  $mq_srv->snd (3, $msg );
  print " ... done \n";


  # my $buf;
  # $mq_my->rcv($buf, 256);

  # print $buf , "\n";

  sleep 5;
  $cnt++;


}


