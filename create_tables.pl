#!/usr/bin/perl
# crude hack to create tables
# print debug to SDTERR
# working output to file
#
# https://perldoc.perl.org/perldsc#Declaration-of-a-HASH-OF-ARRAYS

# our $num_cells = 22;
our $tablename_prefix ="rrd_upload_" ;

# we only have decimal numeric fields
# hash of tables => hash of rows => array [ width , decimals ]
our %table_defs = ( 

	#  cells => {
	# U01 U02 ...  U22
	# } ,
  infini => {
  	seq => 1,
    #       [ seq, digits, decimals ]
	U_batt		=> [ 1, 5,2 ] ,
	C_batt 		=> [ 2, 3,0 ] ,
	I_batt 		=> [ 3, 5,2 ] ,
	U_ACinR 	=> [ 4, 4,1 ] ,
	U_ACinS 	=> [ 5, 4,1 ] ,
	U_ACinT 	=> [ 6, 4,1 ] ,
	U_ACoutR 	=> [ 7, 4,1 ] ,
	U_ACoutS 	=> [ 8, 4,1 ] ,
	U_ACoutT 	=> [ 9, 4,1 ] ,
	U_ACmax 	=> [ 10, 4,1 ] ,
	F_ACin 		=> [ 11, 4,2 ] ,
	F_ACout 	=> [ 12, 4,2 ] ,
	P_ACoutR 	=> [ 13, 5,0 ] ,
	P_ACoutS 	=> [ 14, 5,0 ] ,
	P_ACoutT 	=> [ 15, 5,0 ] ,
	P_ACoutSum 	=> [ 16, 5,0 ] ,
	P_ACoutPerc 	=> [ 17, 5,0 ] ,
	P_EM_feed_def 	=> [ 18, 5,0 ] ,
	P_EM_PV_act 	=> [ 19, 5,0 ] ,
	P_EM_feed_act 	=> [ 20, 5,0 ] ,
	P_EM_hybrid_res => [ 21, 5,0 ] ,
	T_inner 	=> [ 22, 2,0] ,
	T_comp		=> [ 23, 2,0] ,
   }, 
   status => {
	seq => 2,
	inv_day 	=> [ 1, 10,5 ] ,
	work_mode 	=> [ 2, 1,0  ] ,
	pow_status 	=> [ 3, 5,0  ] ,
	warn_status	=> [ 4, 7,0  ] ,
    },
);

# ===== end of config

use Data::Dumper;

print STDERR Dumper( \%table_defs ) ;

my $outer_head = <<"EOF_OHEAD";
/*!40101 SET character_set_client = utf8 */;

EOF_OHEAD

my $tabdef_head = <<"EOF_TDHEAD";
DROP TABLE IF EXISTS `%s`;
CREATE TABLE `%s` (
  `time` datetime NOT NULL,
EOF_TDHEAD

my $tabdef_row = <<"EOF_TDROW" ;
  `%s` decimal(%d,%d) DEFAULT NULL,
EOF_TDROW
  
my $tabdef_tail = <<"EOF_TDTAIL";
  `update_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  PRIMARY KEY (`time`)
) ENGINE=MyISAM DEFAULT CHARSET=ascii ;

EOF_TDTAIL

#=============== pull the stuff apart

print STDERR "========== start parsing data tree \n ==========";

# prelude
print $outer_head;

# cycle over tables
foreach my $table ( 
	sort { $table_defs{ $a }->{'seq' }<=> $table_defs{ $b }->{'seq' } }  
	keys %table_defs ) {

  # print STDERR "building  table  $table \n"; 
  my $tbd = $table_defs{$table};
  my $tablename = $tablename_prefix . $table ;
  print STDERR " building  table  $tablename ,  sequence = $tbd->{'seq' }   \n";
  # print STDERR Dumper $tbd ;

  # do the real thing - fill with table name
  printf $tabdef_head, $tablename, $tablename ;

  # cycle over rows
  foreach my $trow ( 
	  sort {    $$tbd{ $a }[0]  <=>  $$tbd{ $b }[0]    }
	  keys %$tbd ) {
    next if $trow eq 'seq' ;
    my $trd = %$tbd{$trow} ;
    # print STDERR Dumper $trd ;
    print STDERR " +----  building  row  $trow,  sequence = $$trd[0] param: $$trd[1] , $$trd[2]   \n";


    # do the real thing
    printf $tabdef_row,  $trow, $$trd[1] , $$trd[2]   ;
  }

  # finish the real thing
  print $tabdef_tail;

}
