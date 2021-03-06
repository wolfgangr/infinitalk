#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT IPC_NOWAIT  );
# use IPC::SysV qw();
use IPC::Msg();
use Cwd qw( realpath );
# use Fcntl;

use Data::Dumper qw (Dumper) ;

my $ftok_my = ftok ( realpath ($0) ); 

# my $mq_my = IPC::Msg->new($ftok_my , S_IRUSR | S_IWUSR | IPC_CREAT );

my $mq_my  = IPC::Msg->new($ftok_my     ,  S_IWUSR | S_IRUSR |  IPC_CREAT  )
        or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_my  );

my %clientlist =();

my $cnt = 0;
while (1) {
  my $buf;
  $mq_my->rcv($buf, 256, 1, IPC_NOWAIT );

  if ($buf) {
    printf "message: %s, counter %i, \n",  $buf, $cnt ;
    # my ( $x_client_key , $text ) = split ( ':', $buf, 2);
    my ( $x_client_key , $text , $cl_cnt) = $buf =~ /^(.{8})\:(.*) No (\d+)$/;
    my $client_key = hex ( $x_client_key );
    # do we know the guy?
    printf (" string: %s - ", $x_client_key  ) ;
    my $mq_cli = $clientlist{$x_client_key} ;
    unless ( $mq_cli ) {
      # if not yet, try to get its response queue
      my $client_key = hex ( $x_client_key );
      printf (" , dec %d, hex 0x%08x    ", ($client_key) x2 ) ;
      $mq_cli = $clientlist{$x_client_key}  #   =
      		# = IPC::Msg->new(  $client_key  , S_IRUSR | S_IWUSR | IPC_CREAT ) ;
		= IPC::Msg->new(  $client_key  , 0) ;
      printf " opening queue for client 0x%08x %s \n", $client_key, 
    	  $mq_cli  ? 'succeeded' : 'failed' ;
      }

      if ( $mq_cli ) {
	 my $response = sprintf "hello, %s, server response at no %d to your request %d ", 
	 	$x_client_key , $cnt, $cl_cnt ;
	 $mq_cli->snd(1, $response) ;
      }
  }
  printf "\t%d\n", $cnt;
  $cnt++;
  sleep 1 
};

$mq_my->remove;

exit 1;

# ~~~~~~~~~~~~~~~~~~~
# return a ftok based on some key an our own script pathname
