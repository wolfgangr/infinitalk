#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT  );
use IPC::Msg();
use Cwd qw( realpath );
# use Fcntl;

use Data::Dumper qw (Dumper) ;

# my $pwd = `pwd`;
# chomp $pwd;
# $pwd ='';
# my $path = $pwd .  "/$0" ;
my $path = realpath ($0)  ;
# printf "%s\n", $path ;  
# $path = "/home/wrosner/infini/parsel/qsv-tester.pl" ;
# $path = "/home/wrosner/infini/parsel/tmp/test.mq" ;
my $ftok_foo = ftok ( realpath ($0),   'f' );
my $ftok_bar = ftok ( realpath ($0),  'b' );
my $ftok_def = ftok ( realpath ($0) ); 

printf "ftoks von foo: 0x%08x , bar: 0x%08x , default 0x%08x in path %s \n", $ftok_foo, $ftok_bar, $ftok_def, $path ;


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

exit 1;

# ~~~~~~~~~~~~~~~~~~~
# return a ftok based on some key an our own script pathname
sub my_ftok{ 
  my $id = shift || 1 ;
  my $pwd = `pwd`;
  chomp $pwd;

  return ftok(spritf ("%s/%s", $pwd, $0), $id )
}
