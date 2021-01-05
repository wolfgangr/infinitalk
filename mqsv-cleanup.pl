#!/usr/bin/perl
#
# delete all message queues except the one to the server
#

use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT IPC_NOWAIT );
use IPC::Msg();
use Cwd qw( realpath );
use Data::Dumper qw( Dumper );
# use Time::HiRes () ;


# my $ftokid = 1;
my $server = './scheduler.pl';
my $ftok_server = ftok ( realpath ($server) );
# my $ftok_my = ftok ( my_realpath ($0) );

printf "server: %s, realpath: %s, ftok =  0x%08x \n", 
	$server , realpath ($server), ($ftok_server)  ;

my @ipcs_q = split ( '\n' , `ipcs -q` ) ;

print Dumper (\@ipcs_q );

foreach my $line (@ipcs_q) {
  my ($key, $msqid, $owner, $perms, $used_b, $n_msgs) = ( $line =~ 
	/^0x([0-9a-fA-F]{8})\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/ );
  next unless defined $key;
  printf "key: %s, id: %s ", $key, $msqid ;
  if ( hex($key) == $ftok_server ) {
	  print " -> server - keep\n";
  } else {
	  print "-> ## killit ## ";
	  my $cmd= sprintf ("ipcrm msg %s", $msqid );
	  print "calling: $cmd - ";
	  print `$cmd` ;
  }
}
