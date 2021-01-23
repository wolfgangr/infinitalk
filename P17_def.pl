# infini protocol P17 translated to a perl hash to guide all processing
# Infini10KW&15KWprotocol.pdf
# 
# designed as central management point for command semantic
# - stick to perl syntax rules!
# - run debug_def.pl after updates to check for syntax and heavy logical errors
# - run debug_dryrun.pl after updates to check data structure and compare field lists with printed protocol
# - run debug_wetrun.pl to map real data from the inverter to the descriptions
#
# data structure:
# - top level hash tag field: command name as to be sent to the infini
# - tag=>'whatever' label to be assigned to the whole command
# - fields=>[ ... ] perl list fo data field labels 
# (todo) - units=>[ ... ] optional list of physical units, 
# (todo) - factors=>[ .... ] optional list of scaling factors 
# - use=>{ group=>seq } assignment of field to logical ordering, may be repeated
#  enums => [ [ qw (foo bar ) ] , undef x Y , [ 'tralala' , 'pipapo' ] ] 

# output use collations:
# conf0 ... conf4 - grouped config info similiar to SolarPower pages
# stat - current status
# em - energy management relevant stuff
# es - short version thereof


#
# include as follows:
#  our %p17;
#  require ('./P17_def.pl');

use utf8;

our %p17 = ();

# common enums
# my $enum_enabled = [ qw ( disabled enabled ) ] ;


$p17{'PI'} = {
	tag=>'protocol ID',
	use=>{ conf0=>0 }, 
	fields=>[ qw(protocol) ]
} ;

$p17{'ID'} = {
        tag=>'series number',
	use=>{ conf0=>1 },
        fields=>[ qw(ID) ]
} ;

$p17{'VFW'} = {
        tag=>'main CPU',
	use=>{ conf0=>2 },
        fields=>[ qw(version) ]
} ;

$p17{'VFW2'} = {
        tag=>'secondary CPU'  ,
	use=>{ conf0=>3 },
        fields=>[ qw(version) ]
} ;


$p17{'MD'} = {
        tag=>'device model',
	use=>{ conf0=>4 },
        fields=>[ 'Machine number' ,  'Output rated VA', 'Output power factor', 
	'AC input phase number', 'AC output phase number', 'Norminal AC output voltage', 
	'Norminal AC input voltage', 'Battery piece number', 
	'Battery standard voltage per unit' ],
	units=>[ '', VA, ('')x3, V, V, '', V ] ,
	factors=>[ undef, 1,1,1,1, 0.1, 0.1 , 1, 0.1  ] ,
} ;

$p17{'DM'} = {
	tag=>'machine model', 
	use=>{ conf0=>4.5 },
	fields=>[ 'code' ],
};


$p17{'PIRI'} = {
        tag=>'rated information',
        use=>{ conf0=>5 },
        fields=>[ 
	'AC input rated voltage', 'AC input rated frequency', 'AC input rated current', 
	'AC output rated voltage', 'AC output rated current', 
	'MPPT rated current per string', 'Battery rated voltage', 
	'MPPT track number', 
	'Machine type', 'Topology', 
	'Enable/Disable parallel for output', 
	'Enable/Disable for real-time control'	],
	units=>[ qw ( V Hz A V A A V) ], 
	factors=>[ (0.1) x 7, 1  ], 
	enums => [ (undef) x 8 , 
	           [ qw ( grid off-girid ), (undef) x 8, qw ( hybrid ) ],
		   [ qw (trafoless trafo ) ] ,
	   	   [ qw ( disbl enbl ) ] x2 				],	   

} ;

$p17{'MAR'} = {
	tag=>'machine adjustable range', 
	use=>{ conf0=>6 },
	fields=>[
'upper limit of AC input highest voltage for feed power', 'lower limit of AC input highest voltage for feed power',
'upper limit of AC input lowest voltage for feed power', 'lower limit of AC input lowest voltage for feed power',
'upper limit of AC input highest frequency for feed power', 'lower limit of AC input highest frequency for feed power',
'upper limit of AC input lowest frequency for feed power', 'lower limit of AC input lowest frequency for feed power',
'upper limit of wait time for feed power', 'lower limit of wait time for feed power',
'upper limit of solar maximum input voltage', 'lower limit of solar maximum input voltage',
'upper limit of solar minimum input voltage', 'lower limit of solar minimum input voltage',
'upper limit of solar maximum MPPT voltage', 'lower limit of solar maximum MPPT voltage',
'upper limit of solar minimum MPPT voltage', 'lower limit of solar minimum MPPT voltage',
'upper limit of battery charged voltage', 'lower limit of battery charged voltage',
'upper limit of battery Max. charged current', 'lower limit of battery Max. charged current',
'upper limit of maximum feeding power', 'lower limit of maximum feeding power',
		], 
	units=>[   ('V') x4, ('Hz') x4, ('s') x2, ('V') x10, qw( A A W W ) ], 
	factors=>[ (0.1) x4, (0.01) x4, (1) x 2,  (0.1) x12,         1,1 ], 
};

# inserted 2021-01-23 - does this break anything??
#
$p17{'FLAG'} = {
	tag=>'enable flags status',
	use=>{ conf1=>5 },
	fields=> [
		'Mute buzzer beep',
		'Mute buz beep in standby',
		'Mute buz beep only on bat disch',
		'Generator as AC input',
		'Wide AC input range',
		'N/G relay close in bat mod',
		'De-rat. pwr f Grid volt.',
		'De-rat. pwr f Grid freq.',
		'BMS Battery Connect',
	   	],
	enums => [  [ qw (  disbl enbl  ) ] x 9 ] ,
};

$p17{'GS'} = {
        tag=>'General status',
	use=>{ stat=>1 , es=>2 },
        fields=>[
	'Solar input voltage Solar1', 'Solar input voltage Solar2', 
	'Solar input current Solar1', 'Solar input current Solar2', 
	'Battery voltage', 'Battery capacity', 'Battery current', 
	'AC input voltage R', 'AC input voltage S', 'AC input voltage T', 
	'AC input frequency', 
	'', '', '', 
	'AC output voltage R', 'AC output voltage S', 'AC output voltage T', 
	'AC output frequency',
        '', '', '',	
	'Inner temperature', 'Component max temp', 'External battery temp', 
	'Setting change bit' ] , 
	units=>[ qw ( V V A A V % A V V V Hz A A A V V V Hz), ('')x3,  qw( °C °C °C) ,'' ] , 
	factors=>[ (0.1)x5, 1, (0.1)x4, 0.01, (0.1)x6, 0.01, (undef)x3, (1)x3   ] ,
} ;


$p17{'PS'} = {
        tag=>'Power status',
	use=>{ stat=>2 },
        fields=>[
	'Solar input power 1', 'Solar input power 2', 
	'', '', '', '', '',
	'AC output active power R', 'AC output active power S', 'AC output active power T', 
	'AC output total active power', 
	'AC output apperent power R', 'AC output apperent power S', 'AC output apperent power T',
	'AC output total apperent power', 
	'AC output power percentage', 'AC output connect status',
	'Solar input 1 work status', 'Solar input 2 work status',
	'Battery power direction', 'DC/AC power direction', 'Line power direction'       
	], 
	units=>[ ('W') x 11, ('VA') x 4, ('%') ], 
	factors=>[ 1,1, (undef) x5,  (1) x 9 ],
	enums => [ (undef) x 16 ,
		[ qw ( discon conct     ) ] ,
		[ qw ( idle work        ) ] x 2 ,
		[ qw ( idle chrg disc   ) ] ,
		[ qw ( idle AC-DC DC-AC ) ] ,
		[ qw ( idle inp outp    ) ] 		] ,
} ;


$p17{'MOD'} = {
        tag=>'Working mode ',
	use=>{ stat=>3 },
        fields=>['mode' ],
	enums => [ [ qw (pw_on standby bypass batt fault hybrid chrg ) ] ] ,
} ;

$p17{'T'} = {
        tag=>'inverter time',
	use=>{ stat=>-1, conf0=>-1 , es=>-1 },
        fields=>['timestring' ]
} ;


$p17{'WS'} = {
        tag=>'warning status', 
	use=>{ stat=>4 },
	fields=>[ 
		'Solar input 1 loss', 'Solar input 2 loss',
		'Solar input 1 voltage too high', 'Solar input 2 voltage too high',
		'Battery under', 'Battery low', 'Battery open',
		'Battery voltage too high', 'Battery low in hybrid mode',
		'Grid voltage high loss', 'Grid voltage low loss',
		'Grid frequency high loss','Grid frequency low loss',
		'AC input long-time average voltage over', 'AC input voltage loss',
		'AC input frequency loss', 'AC input island', 'AC input phase dislocation',
		'Over temperature', 'Over load',
		'EPO active', 'AC input wave loss',
       	], 
} ;

$p17{'CFS'} = {
        tag=>'current fault status',
        use=>{ stat=>5 },
	fields=>[  'latest fault code',   'latest fault ID in flash' ], 
} ;

$p17{'GLTHV'} = {
        tag=>'AC input long-lime highest average voltage',
        use=>{ stat=>6 },
        fields=>[ 'AC input long-lime highest average voltage' ],
	units=>[ 'V' ],
	factors=>[ 0.1 ] ,
}, 	

# curtesy riogrande
# https://www.photovoltaikforum.com/thread/115416-infinisolar-3k-10k-logging-und-feedin-control/?postID=2160068#post2160068

$p17{'EMINFO'} = {
	tag=>'Energy Management info'  ,
	use=>{ stat=>7, em=>1, es=>3, },
	fields=>[ '', 'default Feed-In power', 'actual PV-Power', 
		'actual Feed-In power', 'actual reserved Hybrid power', '' ] ,
	units=>[ '', ('W') x 4 , '' ],
	factors=>[ undef, (1) x 4,  ] ,
	# units=>[ '', ('kW') x 4 , '' ],
	# factors=>[ undef, (0.001) x 4,  ] ,

};

$p17{'HECS'} = {
	tag=>'Energy control status',
	use=>{ conf1=>1, em=>2, es=>2 },
	fields=>['Solar energy distribution of priority', 
		'enbl charge battery', 
		'enbl AC charge battery', 
		'enbl feed power to utility', 
		'enbl bat dischg to loads when solar input normal', 
		'enbl bat dischg to loads when solar input loss', 
		'enbl bat dischg to utility when solar input normal', 
		'enbl bat dischg to utility when solar input loss',
		'enbl Q(U) derating funcation'
	], 
	units=>[ '', qw ( A B C D E F G H ) ],
	enums => [ [ qw ( Batt-Load-Grid Load-Batt-Grid Load-Grid-Batt ) ],
		   [ qw ( disbl enbl ) ] x 8 					],
};


$p17{'ACCT'} = {
        tag=>'AC charge time bucket',
        use=>{ conf1=>2, em=>3 },
        fields=>['Start time 1 enbl AC charger', 'End time 1 enbl AC charger', 
		'Start time 2 enbl AC charger', 'End time 2 enbl AC charger' ], 
	units=>[ ('HHMM') x 4 ] ,
};

$p17{'ACLT'} = {
        tag=>'AC supply load time bucket',
        use=>{ conf1=>3, em=>4 },
        fields=>['Start time enbl AC supply to load', 'End time enbl AC supply to load' ],
        units=>[ ('HHMM') x 2 ] ,
};   

$p17{'FPADJ'} = {
        tag=>'feeding grid power calibration',
        use=>{ conf1=>4, em=>5 },
	fields=>['total feeding grid direction', 'total feeding grid calibration power', 
		'R feeding grid direction', 'R feeding grid calibration power', 
		'S feeding grid direction', 'S feeding grid calibration power', 
		'T feeding grid direction', 'T feeding grid calibration power', ] ,
	units=>[ ( '' , 'W') x 4 ] ,
	factors=>[ ( undef , 1) x 4 ] ,
} ;

# I get CRC errors here - screw my whole script - throw this out
# ... back again, since infini crc hack solved
$p17{'GOV'} = {
        tag=>'AC input voltage acceptable range for feed power',
        use=>{ conf2=>1 } ,
	fields=>[ 'highest voltage', 'lowest voltage', 
		'highest back voltage', 'lowest back voltage' ],  
	units=>[   ( 'V' ) x 4 ] ,
	factors=>[ ( 0.1 ) x 4 ] ,
}; 

$p17{'GOF'} = {
        tag=>'AC input frequency acceptable range for feed power',
        use=>{ conf2=>2 } ,
        fields=>[ 'highest frequency', 'lowest frequency', 
		'highest back frequency', 'lowest back frequency' ] ,  
        units=>[   ( 'Hz' ) x 4 ] ,
        factors=>[ ( 0.01 ) x 4 ] ,
};

# das ist in der Doku durchgestrichen, kommt aber
$p17{'OPMP'} = {
		tag=>'maximum output power', 
		use=>{ conf2=>3 , em=>6 } ,
		fields=>[ 'maximum power' ],
		units=>[  'W' ] ,
		factors=>[ 1 ] ,
};

$p17{'GPMP'} = {
                tag=>'maximum power f feeding grid',
                use=>{ conf2=>4 , em=>7 } ,
                fields=>[ 'maximum power' ],
                units=>[  'W' ] ,
                factors=>[ 1 ] ,
};


$p17{'MPPTV'} = {
	tag=>'Solar input MPPT acceptable range', 
	use=>{ conf3=>1 },
	fields=>[ 'highest voltage', 'lowest voltage' ], 
	units=>[ ('V') x 2  ] ,
	factors=>[ ( 0.1 ) x2 ],
};

$p17{'SV'} = {
        tag=>'Solar input voltage acceptable range',
        use=>{ conf3=>2 },
        fields=>[ 'highest voltage', 'lowest voltage' ],
        units=>[ ('V') x 2  ] ,
        factors=>[ ( 0.1 ) x2 ],
};

$p17{'BATS'} = {
	tag=>'battery setting', 
	use=>{ conf2=>5 , em=>8 } ,
	fields=>[ 'Battery maximum charge current',
		'Battery constant charge voltage(C.V.)',
		'Battery floating charge voltage',
		'Battery stop charger current level in floating charging',
		'Keep charged time of battery catch stopped charging current level',
		'Battery voltage of recover to chg when batt stop chg in floating chg',
		'Battery under voltage',
		'Battery under back voltage',
		'Battery weak voltage in hybrid mode',
		'Battery weak back voltage in hybrid mode',
		'Battery type',		'', '', 
		'AC charger keep battery voltage function enable/diable',
		'AC charger keep battery voltage' ,
		'Battery temperature sensor compensation',
		'Max. AC charging current',
		'Battery discharge max current in hybrid mode' ] ,
	units=>[ qw ( A V V A min ), ('V') x5,  ( '' ) x4, qw ( V mV A A ) ] , 
	factors=>[ ( 0.1) x 4, (1),  ( 0.1) x5, (undef)x4,  ( 0.1) x3, 1 ], 
};

# End of p17 protocol
#-------------
# rrd file definition
# array of  label=>[ P17cmd, P17pos, min, max ]

@rrd_def= (
  [ U_batt,  GS   , 5, 0, 70 ],
  [ C_batt,  GS   , 6, 0, 120 ],  # percentage
  [ I_batt,  GS   , 7, -300, 300 ],

  [ U_ACinR, GS   , 8, 0, 300 ],
  [ U_ACinS, GS   , 9, 0, 300 ],
  [ U_ACinT, GS   , 10, 0, 300 ],
  [ U_ACoutR, GS  , 15, 0, 300 ],
  [ U_ACoutS, GS  , 16, 0, 300 ],
  [ U_ACoutT, GS  , 17, 0, 300 ],
  [ U_ACmax, GLTHV, 1, 0, 300 ],

  [ F_ACin, GS    , 11, 0, 60 ],
  [ F_ACout, GS   , 18, 0, 60 ],

  [ P_ACoutR,    PS, 8, 0, 5000 ],
  [ P_ACoutS,    PS, 9, 0, 5000 ],
  [ P_ACoutT,    PS, 10, 0, 5000 ],
  [ P_ACoutSum,  PS, 11, 0, 15000 ],
  [ P_ACoutPerc, PS, 16, 0, 110 ],

  [ P_EM_feed_def  , EMINFO , 2, 0, 15000 ],
  [ P_EM_PV_act    , EMINFO , 3, 0, 15000 ],
  [ P_EM_feed_act  , EMINFO , 4, 0, 15000 ],
  [ P_EM_hybrid_res, EMINFO , 5, 0, 15000 ],

  [ T_inner, GS, 22, -20, 100 ],
  [ T_comp,  GS, 23, -20, 100 ],

);


###~~~~~~~~~~~~~~
# to do:
# - stat data ...  GLTHV
# - event lists: fault states, HFSnn - history fault parameter
# - config .... still a lot ....
# - irrelevant: ET m EY M D H ...
# - MPPTV, SV, PV.. FET, FPPF AAPF, FPRA
# nice to have: DI, MAR (dfaults / max / min) as orientation .... 


## -----------------------

# $p17{'#'} = {
#         tag=>' ',
#         fields=>[ ]
# } ;



## keep this 1; below here! ~~~~~~~~ 
1;


