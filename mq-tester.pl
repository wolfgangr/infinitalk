#!/usr/bin/perl
#
# try to get posix message queue working
# see https://metacpan.org/pod/POSIX::RT::MQ
# and https://users.pja.edu.pl/~jms/qnx/help/watcom/clibref/mq_overview.html
#
#

use warnings ;
use strict ;

use Fcntl;
use POSIX::RT::MQ () ;

my $mqname = './infinitest';
my $attr = { mq_maxmsg  => 1024, mq_msgsize =>  256 };

printf " %d %d \n",    O_RDWR ,  O_CREAT ;

my $mq = POSIX::RT::MQ->open($mqname , O_RDWR|O_CREAT, 0600, $attr) 
     or die "cannot open $mqname: $!\n";

$mq->send('some_message', 0) or die "cannot send: $!\n";

my ($msg,  $prio)  = $mq->receive or die "cannot receive: $!\n";

