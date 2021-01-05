#!/usr/bin/perl
#
# round robin roundabout for serial infini communication
# - binds to infini serial device
# - (may be optinal in the future: perform power hacks)
# - process comand pipeline
# - query status -> rrd databases
# - extract static information for web display and such stuff
#
#
use strict;
use warnings;
use 5.010;

use Data::Dumper qw(Dumper) ;
use Digest::CRC () ;
# use DateTime();
use DateTime::Format::Strptime();
our $my_infini_strp = DateTime::Format::Strptime->new( pattern  => '%Y%m%d%H%M');


use Time::HiRes qw( usleep );
# use IO::Socket::UNIX;
# use POSIX qw( );
use RRDs();
use Storable qw( lock_store );

use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR ftok IPC_CREAT IPC_NOWAIT  );
use IPC::Msg();
use Cwd qw( realpath );



#---- config -------------

our $Debug = 4;

our $infini_device="../dev_infini_serial" ;
our $tempdir = "./tmp";



our $status_bck = "$tempdir/status.bck";


our @collations = qw (conf0 conf1 conf2 conf3  stat em);
our @extra_stats = qw (T MOD WS); # commands to retrieved for status not included in @rrd_def 

our $rrddir= '.';
our $infini_rrd = "$rrddir/infini.rrd";
our $status_rrd = "$rrddir/status.rrd";

our $RETRY_on_infini_err = 3 ;
our $Usleep_between_cmd = 1e5 ; 
our $Repeat_mq_cmds = 5 ; # mq priority, may cause DOS vulnerability


# ------ protocol definition ----- 

our %p17;
our @rrd_def;
require ('./P17_def.pl');

# I want
# - hashed index of  @rrd_def by rrd label
# - hashed index of  @rrd_def by P17 command, pointing to array of pointers

our %rrd_def_by_label;
our %rrd_def_by_cmd;
our %rrd_factor_map;

foreach my $dl (@rrd_def) {
	# I hope we have a pointer to a list....
	$rrd_def_by_label{ $$dl[0] } = $dl ; # this one works in a single run
	$rrd_def_by_cmd{ $$dl[1] } = [] ;    # collect list of P17 commands in use

	my $fac = $p17{$$dl[1]}->{'factors'}[$$dl[2]-1]  ;
	$fac = 1 unless defined ( $fac) ;
	$rrd_factor_map{ $$dl[0] } = $fac ;
}

foreach  my $dl (@rrd_def) {
	$rrd_def_by_cmd{ $$dl[1] }[ $$dl[2] -1  ] = $dl ;
}

our @rrd_cmd_list = ( @extra_stats , ( sort keys %rrd_def_by_cmd ) ) ;
# our @rrd_cmd_list =  sort keys %rrd_def_by_cmd;

our $rrd_stat_tpl = join(':', map { $$_[0] } @rrd_def) ;


debug_dumper(5, \%rrd_def_by_label , \%rrd_def_by_cmd, \@rrd_cmd_list, \@rrd_def , \%rrd_factor_map );
debug_print (5, "rrd_stat_tpl = \n\t$rrd_stat_tpl \n");

#---------------
 
# index for processing of collations:
# hash of arrays
our %collation_cmds =() ;
foreach my $cl (@collations) {
  $collation_cmds{$cl} = [ sortedkeys  (\%p17, $cl) ] ;
}

debug_dumper(5, \@collations, \%collation_cmds) ;

# set up sysV message queue

# create token by script location
my $ftok_my = ftok ( realpath ($0) );

# assign message queue for requests to us
our $mq_my  = IPC::Msg->new($ftok_my     ,  S_IWUSR | S_IRUSR |  IPC_CREAT  )
        or die sprintf ( "cant create server mq using token >0x%08x< ", $ftok_my  );

# where we store the qeue handlers of clients
# hope there are not so many that we run out of memory....
our %mq_clientlist =();   

# ----------------------------

open ( my $INFINI,  "+<", $infini_device ) or die "canot open $infini_device : $!";
$/ = "\r" ; # change line terminator

# ========= main scheduler loop =============

# setup rrd iterator, start with T

while (1) {
  # while (command in pipeline)
  #   process command
  # }
  
  unless (stat_iterator() ) {
	debug_print (1, "shitt happened processing stat_iterator\n");
	# last; 
  }
  # sleep 1;
  usleep $Usleep_between_cmd ;

  for my $i (1 .. $Repeat_mq_cmds) {
          last  unless (mq_processor()) ;
  }

  usleep $Usleep_between_cmd ;


  unless (coll_iterator() ) {
        debug_print (1, "shitt happened processing coll_iterator\n");
	# last;
  }
 

  usleep $Usleep_between_cmd ;

  for my $i (1 .. $Repeat_mq_cmds) {
  	  last  unless (mq_processor()) ;
  }

  usleep $Usleep_between_cmd ;

  # last if (happens(shit));
  # die "############### DEBUG #############";
} # ===== end of main scheduler loop



SHITTHAPPENED:
debug_print (1, "shitt happened, main loop cancelled \n");

close $INFINI;

debug_print (1, "cleanup done \n");

exit;

#~~~ iterators ~~~~~~~~~~~~~
# check for client command request and try to answer them at our best possibility
sub mq_processor {
  # return undef ;
  my $buf;
  $mq_my->rcv($buf, 256, 1, IPC_NOWAIT );
  unless ($buf) {
	  return 0 ; # suppose empty queue
  } else {
    debug_printf (4, "message: %s,", $buf) ;
    # 0xclid:0xtimestamp:cmd:cnt
    my ($x_client_key, $c_ts, $cmd, $cnt) = $buf  =~
        /^([0-9a-fA-F]{8})\:([0-9a-fA-F]{8})\:([^\:]*)\:([^\:]*)$/ ;
    if ($cnt) {
       debug_printf (4, "  clid=%s,  c_ts=%s,  cmd=%s,  cnt=%s \n", 
	       $x_client_key, $c_ts, $cmd, $cnt );
       # check in list of known clients
       my $mq_cli = $mq_clientlist{$x_client_key} ;
       unless ( $mq_cli ) {
          my $client_key = hex ( $x_client_key ); # num from hex
          debug_printf (4, " , dec %d, hex 0x%08x    ", ($client_key) x2 ) ;

	  # try to assign a client mq
          $mq_cli = $mq_clientlist{$x_client_key}  #   =
      		# = IPC::Msg->new(  $client_key  , S_IRUSR | S_IWUSR | IPC_CREAT ) ;
		= IPC::Msg->new(  $client_key  , 0) ;

          debug_printf(4, " opening queue for client 0x%08x %s \n", $client_key, 
	    	  $mq_cli  ? 'succeeded' : 'failed' ) ;
       }

       # if we either have or can create a client answer queue
       if ( $mq_cli ) {
	  # retrieve response from gadget
	  my $qry = compose_qry ($cnt , $cmd);
	  debug_printf (4, "\t\tcontent %s , cmd %s -> query %s \n", $cnt , $cmd , $qry );
          my $resp = call_infini_raw($qry);
	  my $s_ts = (int (Time::HiRes::time * 1000)) & 0xffffffff ;

	  debug_printf (4, "\t\tresponse %s , at ts: 0x%08x \n", $resp , $s_ts);

          my $resp1 = substr ($resp , 0,-3  );
          my $crc = substr ($resp , -3,2  );
	  
	  # bit0 = format error, bit1 = length mismatch, bit3 = crc mismatch
	  my $flag = 0; 
          my ($label, $len, $payload) =  ( $resp1 =~ /\^(\w)(\d{3})(.*)$/ )  ;
	  unless (defined ($payload) )	{  $flag |= 1 ;	  }

	  $flag |= 2 if ( length($resp)-5-$len ) ;

	  my $digest = my_crc ($resp1);
	  my $num_crc = unpack ('n', $crc  );
	  $flag |= 4 unless $digest == $num_crc;

	  # response format:
	  # 0xyour_ts:0xmy_ts:infiny-qry:flag:trail:crc:payload
	  my $mq_answer = sprintf ("%s:%08x:%02x:^%s%03d:%04x:%s",
	 	$c_ts, $s_ts, $flag, $label, $len , $num_crc , $payload  ); 
	  # my $mq_answer = join ( ':', ( $c_ts, $s_ts, $flag, ('^' . $label. $len) , $crc, $payload ) ) ;
          debug_printf (4, "\tanswer: %s\n", $mq_answer); 

          # and return the answer to the client
	  $mq_cli->snd (1, $mq_answer); 	  
       }


    } else {
       debug_printf (2, " - unparseable mq request %s\n", $buf);
       return 0;
    }
  }
  return 1;
}

# ------------------------------- stat_iterator ------------------------
# tag list @rrd_cmd_list
# collection struct:
sub stat_iterator {
  # my $s_counter ;
  # state $time ;
  state $s_counter = 0;
  state $retries =0;
  state %res=();
  debug_print (5, "stat_iterator $s_counter\n");

  unless ( $s_counter) {  
    # my $time = [ call_infini_cooked ('T') ] ;  
    # %res = { T=>$time } ;
    %res=();
    # $res{'T'}=$time;
  }
  
  my $tag =$rrd_cmd_list[$s_counter]; 
  my $resp = [ call_infini_cooked ( $tag ) ] ;


  debug_dumper ( 5,  $resp , scalar @$resp ) ;

  # die "===== debug =====" ;

  # implement some error tolerance
  if (  (scalar @$resp) == 3  ) { $retries = 0; } else {
	sleep $retries; # slow down to let things settle a bit
	if ( $retries++ >=  $RETRY_on_infini_err ) {
		# start from new
		debug_printf (2, "retry overrun after %d trials in %s  \n",  
			$retries , $tag );
		$retries = 0; 
		$s_counter = 0;
		# %res=();
		# if ( $cl_counter++ >= $#collations ) {  $cl_counter = 0 ; }
		return(0);
	}
        debug_printf (3, "retry no %d in %s  \n" , $retries , $tag  ),
	return(0);
  }

  # fine, continue ...
  $res{$tag}=$resp ;

  debug_dumper ( 6, \%res ) ;


  # return 0 if ( $s_counter++ >= 4) ;
  # $s_counter++ >= 4 and $s_counter=0;
  if ( $s_counter++ >= $#rrd_cmd_list) {
    $s_counter = 0;



    debug_dumper ( 6, \%res , \@rrd_def) ;
    # keep a structured copy for reuse
    #
    lock_store \%res, $status_bck; 

    debug_print (5, "template: $rrd_stat_tpl \n");
    my @vals = map { 
    	my ($label, $cmd, $idx) = @$_ ;
	($res{$cmd}[2][$idx-1] * $rrd_factor_map{$label});
    } @rrd_def ;


    debug_dumper ( 6, \@vals );
    my $valstr = join(':', 'N', @vals );
    debug_print (4, "values: $valstr  \n");
    RRDs::update($infini_rrd, '--template', $rrd_stat_tpl, $valstr);
    debug_rrd (3,5, RRDs::error );

    # status_rrd:
    # inv_day: unixtime %s /  (24*60*60) i.e. fractional days since epoc
    my $i_time = $res{'T'}[2][0] ;
    my $i_dt = $my_infini_strp->parse_datetime( $i_time );
    my $i_rrdt ;
    if (defined $i_dt) {  
	$i_rrdt  =  $i_dt->strftime('%s') /86400;
    } else {
	$i_rrdt  = 0;
	debug_printf(2, "cannot process timestring %s \n", $i_time );
    }

    # warn status 21 bits - littleendian - hope this works....
    my @ws_ary =   @{$res{'WS'}[2]};
    my $ws_bits= 0;
    while (scalar @ws_ary ) {
            $ws_bits <<= 1;
            $ws_bits |= ( pop @ws_ary & 0x01 ) ;
    }

    # bitmapize ( @{$res{'WS'}[2]} ) ; 
    # debug_dumper ( 6,  $res{'WS'}[2] , $ws_bits  );

    # power status: last 6 fields of PS and field 1, 5 of EMINFO in littleendian
    my @ps_ary = ( @{$res{'PS'}[2]}[-6 .. -1], @{$res{'EMINFO'}[2]}[0,5] ); 

    debug_dumper ( 6,  $res{'PS'}[2],  $res{'EMINFO'}[2] , \@ps_ary );

    # pack array values into integer by 2 bits each
    my $ps_2bits = 0;
    while (scalar @ps_ary ) {
	    $ps_2bits <<= 2;
	    $ps_2bits |= ( pop @ps_ary & 0x03 ) ;
    }

    # work mode: int 0 ... 6
    my $wm = $res{'MOD'}[2][0] ;
    # N inv_min work_mode , pow_status  warn_status 
    debug_printf (6, "datetime %s\ , power status 0x%04x , warn status bits: 0x%06x , work mode: %d\n" ,
	    $i_rrdt  , $ps_2bits, $ws_bits , $wm ); 

    my $valstr2 = join(':', ('N', $i_rrdt  , $ps_2bits, $ws_bits , $wm ));
    debug_printf (4, "values_2 %s\n", $valstr2 );
    RRDs::update($status_rrd,  '--template', 
	    'inv_day:work_mode:pow_status:warn_status',  $valstr2 );
    debug_rrd (3,5, RRDs::error );

    # %res=();
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # die "#### debug in  # stat_iterator ####";
  } 

  return 1;
}

# collation list : @collations
# collection struct
sub coll_iterator {
  # wir iterieren über collations und commands, die Werte pro command gehen dann in einem aufwasch
  # 	@collations ... liste der   tags für   \%collation_cmds) 
  # template: https://github.com/wolfgangr/infinitalk/blob/master/debug_wetrun.pl
  #
  state $cl_counter = 0;
  state $cmd_counter = 0;
  state $retries = 0;
  state %res = ();

  debug_printf (5, "coll_iterator %d : %d \t", $cl_counter, $cmd_counter);

  unless ( $cmd_counter ) {  %res = (); }

  # get orientation
  my $current_cl_tag = $collations[$cl_counter] ;
  my @current_cmd_list = @{$collation_cmds{ $current_cl_tag }};
  # my $current_cmd_tag = $collation_cmds{ $current_cl_tag }[$cmd_counter] ;
  my $current_cmd_tag = $current_cmd_list[$cmd_counter] ;


  debug_printf (5, " processing collation =%s, command=%s\n", $current_cl_tag, $current_cmd_tag );

  my $resp = [ call_infini_cooked ( $current_cmd_tag ) ] ;

  # implement some error tolerance
  if ( (scalar @$resp ) == 3) { $retries = 0; } else {
	sleep $retries; # slow down to let things settle a bit
	if ( $retries++ >=  $RETRY_on_infini_err ) {
		# give up on current collation, keep saved file in place, skip to next
		debug_printf (2, "retry overrun after %d trials in %s - %s \n",  
			$retries , $current_cl_tag , $current_cmd_tag );
		$retries = 0; 
		$cmd_counter = 0;
		%res = ();
		if ( $cl_counter++ >= $#collations ) {  $cl_counter = 0 ; }
		return(0);
	}
        debug_printf (3, "retry no %d in %s - %s \n" ,
		$retries , $current_cl_tag , $current_cmd_tag   ),
	return(0);
  }

  # fine, go ahead
  $res{ $current_cmd_tag }=$resp ;

  if ( $cmd_counter++ >= $#current_cmd_list ) {
    # last command of collation is done
    debug_dumper ( 6, \%res ) ;
    my $bckfile = sprintf "%s/%s.bck", $tempdir , $current_cl_tag ;
    lock_store \%res, $bckfile; 

    # next collation, may be o a rolling basis
    $cmd_counter = 0;
    # %res = ();
    if ( $cl_counter++ >= $#collations ) {
	$cl_counter = 0 ;
	# die " ========== DEBUG in coll_iterator ====== ";
    }
  }

  # return 0 if ( $cl_counter++ >= 30) ;

  return 1;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# subs....

# $response = call_infini_raw ($request)
sub call_infini_raw {
  my $qrys = shift @_;
  printf $INFINI ( "%s\r", $qrys) ;
  # my_POSIX_printf ($INFINI, "%s\r", $qrys) ;
  # my ($rv, $buf);
  # POSIX::write( $INFINI, $qrys, len($qrys) );
  # while ( POSIX::read
  my $rv=<$INFINI>;
  # my $rv=my_POSIX_readall($INFINI);
  return $rv;
}

# ($flag, $len, $valptr) = call_infini_cooked ( $content, [$command] )
sub call_infini_cooked {
  my $qry = compose_qry (@_);

  debug_printf (5, "content %s - query %s \n", $_[0] , $qry ); 

  my $rsp = call_infini_raw($qry);
  return (checkstring( $rsp ));
}

# $query = compose_qry ( $content, [$command] )
sub compose_qry {
  my ($cnt, $cmd) = @_;
  ($cmd) or $cmd = 'P';
  my $qry = (sprintf  "^%1s%03d%s", $cmd, (length ($cnt) +1), $cnt) ;
  return $qry;
}

# ($flag, $len, $valptr) = checkstring ($response );
sub checkstring {
  my $resp = shift @_;

  my $resp1 = substr ($resp , 0,-3  );
  my $crc = substr ($resp , -3,2  );

  ( my ($label, $len, $payload) = 
	  ($resp1 =~ /\^(\w)(\d{3})(.*)$/) )  
	  or return (0) ;

  return (0) if ( length($resp)-5-$len ) ;

  # my $digest = Digest::CRC::crc($resp1, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1); 
  my $digest = my_crc ($resp1);
  return (0) unless $digest == unpack ('n', $crc  )  ;

  my @data = split(',', $payload);
  return ($label, $len,  \@data  );
}

# wrapper 
sub my_crc {
  my $arg = shift;
  return Digest::CRC::crc($arg, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1);
}

# $bitmap = bitmapize (@flags)
sub bitmapize {
  my $rv = 0;
  while (scalar @_) {
    $rv <<= 1 ; 
    $rv |= (shift @_) ? 1 : 0;

  } # while ($#@_ >= 0);
  return $rv;
}

# sortedkeys ($p17, 'tag' ) 
sub sortedkeys {
  my ($p, $tag) = @_;
  return ( 
  	sort { $$p{$a}->{'use'}->{ $tag } <=> $$p{$b}->{'use'}->{ $tag } }
        grep {  defined ( $$p{$_}->{'use'}->{ $tag } ) }
        keys %$p ) ;
}

# debug_print($level, $content)
sub debug_print {
  my $level = shift @_;
  print STDERR @_ if ( $level <= $Debug) ;
}

sub debug_printf {
  my $level = shift @_;
  printf STDERR  @_ if ( $level <= $Debug) ;
}

sub debug_dumper {
  my $level = shift @_;
  print STDERR (Data::Dumper->Dump( \@_ )) if ( $level <= $Debug) ;
}


# debug_rrd ($level1, $level2, $ERR ) 
#  level1 : at least to report anything, but ....
#  level2 ... report even double update times
sub debug_rrd {
  my ($level1, $level2, $ERR) = @_ ;
  return unless ($ERR);
  return if ($Debug < $level1);
  my $filter = '(illegal attempt to update using time )'
  	. '(\d{10,})'
	. '( when last update time is )'
	. '(\d{10,})'
	. ' (\(minimum one second step\))'  
  ;
  return if ( ($ERR =~ /$filter/) and ( $Debug < $level2)) ; 
  debug_printf ($level2, "ERROR while updating : %s\n", $ERR);
}



