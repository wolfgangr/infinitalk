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
use Digest::CRC qw(crc) ;
# use DateTime();
use DateTime::Format::Strptime();
our $my_infini_strp = DateTime::Format::Strptime->new( pattern  => '%Y%m%d%H%M');


# use Time::HiRes ;
# use IO::Socket::UNIX;
use POSIX qw( );
use RRDs();
use Storable qw( lock_store );

#---- config -------------

our $Debug = 5;

our $infini_device="../dev_infini_serial" ;
our $tempdir = "./tmp";
our $infini_cmd_send_pipe = "$tempdir/cmd_send.fifo";
our $infini_cmd_read_pipe = "$tempdir/cmd_read.fifo";

our $status_bck = "$tempdir/status.bck";


our @collations = qw (conf0 conf1 conf2 conf3  stat em);
our @extra_stats = qw (T MOD WS); # commands to retrieved for status not included in @rrd_def 

our $rrddir= '.';
our $infini_rrd = "$rrddir/infini.rrd";
our $status_rrd = "$rrddir/status.rrd";

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

# die "### debug ---- setup-----  #####";

# ---- prepare file handlers ------

unlink ( $infini_cmd_send_pipe, $infini_cmd_read_pipe);
POSIX::mkfifo("$infini_cmd_send_pipe", 0666) or die "canot create fifo $infini_cmd_send_pipe : $!";
POSIX::mkfifo("$infini_cmd_read_pipe", 0666) or die "canot create fifo $infini_cmd_read_pipe : $!";
debug_print (5, "fifos created ...\n");

# our $INFINI;
# our $INF_INV ;
# $INF_INV =  POSIX::open( $infini_device )   or die "canot open $infini_device : $!";
# debug_print (5,  "connected to infini\n");
# debug_dumper (5, $INF_INV );
# die "### debug #####";

open ( my $INFINI,  "+<", $infini_device ) or die "canot open $infini_device : $!";
$/ = "\r" ; # change line terminator

our $SEND_PIPE = POSIX::open($infini_cmd_send_pipe,  
	&POSIX::O_RDONLY | &POSIX::O_NONBLOCK ) 
	or die "cannot open socket $infini_cmd_send_pipe : $!";
debug_print (5,  "send pipe open\n") ;

# open(our $READ_PIPE, '>>', $infini_cmd_read_pipe ) or die "cannot open socket $infini_cmd_send_pipe: $!";

our $READ_PIPE = POSIX::open($infini_cmd_read_pipe,  
	&POSIX::O_NONBLOCK  ) 
	or die "cannot open socket $infini_cmd_read_pipe : $!";
debug_print (5,  "read pipe open\n");

# ========= main scheduler loop =============

# setup rrd iterator, start with T

while (1) {
  # while (command in pipeline)
  #   process command
  # }
  
  unless (stat_iterator() ) {
	debug_print (1, "shitt happened processing stat_iterator\n");
	last; 
  }
  
  unless (coll_iterator() ) {
        debug_print (1, "shitt happened processing coll_iterator\n");
        last;
  }
 
  # last if (happens(shit));
  # die "############### DEBUG #############";
} # ===== end of main scheduler loop



SHITTHAPPENED:
debug_print (1, "shitt happened, main loop cancelled \n");

POSIX::close $SEND_PIPE; 
POSIX::close $READ_PIPE;
POSIX::close $INFINI;

debug_print (1, "cleanup done \n");

exit;

#~~~ iterator ~~~~~~~~~~~~~
# tag list @rrd_cmd_list
# collection struct:
sub stat_iterator {
  # my $s_counter ;
  # state $time ;
  state  $s_counter = 0;
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
    my $i_rrdt = $i_dt->strftime('%s') /86400;

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
    RRDs::update($status_rrd,  '--template', 
	    'inv_day:work_mode:pow_status:warn_status',  $valstr2 );
    debug_rrd (3,5, RRDs::error );


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
  state %res = ();

  debug_printf (5, "coll_iterator %d : %d \t", $cl_counter, $cmd_counter);

  # get orientation
  my $current_cl_tag = $collations[$cl_counter] ;
  my @current_cmd_list = @{$collation_cmds{ $current_cl_tag }};
  # my $current_cmd_tag = $collation_cmds{ $current_cl_tag }[$cmd_counter] ;
  my $current_cmd_tag = $current_cmd_list[$cmd_counter] ;


  debug_printf (5, " processing collation =%s, command=%s\n", $current_cl_tag, $current_cmd_tag );

  my $resp = [ call_infini_cooked ( $current_cmd_tag ) ] ;
  $res{ $current_cmd_tag }=$resp ;

  if ( $cmd_counter++ >= $#current_cmd_list ) {
    # last command of collation is done
    debug_dumper ( 5, \%res ) ;
    my $bckfile = sprintf "%s/%s.bck", $tempdir , $current_cl_tag ;
    lock_store \%res, $bckfile; 

  die " ========== DEBUG in coll_iterator ====== ";
    # next collation, may be o a rolling basis
  }

  return 0 if ( $cl_counter++ >= 30) ;

  return 1;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# subs....

# my_POSIX_print ($filedsc, $string )
sub my_POSIX_print {
  my ($FD, $str ) =  @_; 
  my $rv =  POSIX::write( $FD, $str, length($str) );
  die "error writing to $FD : $!" unless defined ($rv);
  return $rv;
}

sub my_POSIX_printf {
  my $FD = shift @_;
  return my_POSIX_print ( $FD, sprintf (@_));
}

# my_POSIX_readline ($FH);
sub my_POSIX_readall {
  my $FD = shift @_;
  my ($rv, $chunk);
  while ( POSIX::read( $FD, $chunk, 15 )) { $rv .= $chunk ; }
  return $rv ; 
}

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

  my $digest = crc($resp1, 16, 0x0000, 0x0000, 0 , 0x1021, 0, 1); 
  return (0) unless $digest == unpack ('n', $crc  )  ;

  my @data = split(',', $payload);
  return ($label, $len,  \@data  );
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



