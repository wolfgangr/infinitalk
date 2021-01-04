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



my $cnt = 0;
while (1) {
  my $buf;
  $mq_my->rcv($buf, 256, 1, IPC_NOWAIT );
  
  printf "message: %s, counter %i, \n",  $buf, $cnt  if $buf ;
  printf "\t%d\n", $cnt;
  $cnt++;
  sleep 1 
};

$mq_my->remove;

exit 1;

# ~~~~~~~~~~~~~~~~~~~
# return a ftok based on some key an our own script pathname
