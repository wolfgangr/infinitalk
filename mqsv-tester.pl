#!/usr/bin/perl
#
use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR);
use IPC::Msg;
# use Fcntl;

my $msg ;
$msg = IPC::Msg->new(IPC_PRIVATE, S_IRUSR | S_IWUSR);

# $msg->snd($msgtype, $msgdata);

$msg->snd(3, "foo bar tralala");

my $buf;
$msg->rcv($buf, 256);

my $ds = $msg->stat;

$msg->remove;


