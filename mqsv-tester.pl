#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT  );
use IPC::Msg;
# use Fcntl;

use Data::Dumper qw (Dumper) ;


my $path = `pwd` . '/' . '$0' ;
printf "%s\n", $path ;  
# $path = "/home/wrosner/infini/parsel/qsv-tester.pl" ;
$path = "/home/wrosner/infini/parsel/tmp/test.mq" ;
my $ftok_foo = ftok( $path  );
my $ftok_bar = ftok( $path   );

printf "ftoks von foo: 0x%x , bar: 0x%x in path %s \n", $ftok_foo, $ftok_bar, $path ;


my $msg ;
$msg = IPC::Msg->new($ftok_foo , S_IRUSR | S_IWUSR |  IPC_CREAT );

# $msg->snd($msgtype, $msgdata);

$msg->snd(3, "foo bar tralala");

print Dumper ( \$msg );

my $stat = $msg->stat();

print Dumper ( $stat );

printf "identifier: %s\n", $msg->id ;

my $buf;
$msg->rcv($buf, 256);

print $buf , "\n";

my $ds = $msg->stat;

while (1) {};

$msg->remove;


