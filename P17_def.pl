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
#
# include as follows:
#  our %p17;
#  require ('./P17_def.pl');



our %p17 = ();


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

} ;


$p17{'GS'} = {
        tag=>'General status',
	use=>{ stat=>1 },
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
} ;


$p17{'MOD'} = {
        tag=>'Working mode ',
	use=>{ stat=>3 },
        fields=>['mode' ]
} ;

$p17{'T'} = {
        tag=>'inverter time',
	use=>{ stat=>-1, conf0=>-1 },
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
	use=>{ stat=>7, em=>1 },
	fields=>[ '', 'default Feed-In power', 'actual PV-Power', 
		'actual Feed-In power', 'actual reserved Hybrid power', '' ] ,
	units=>[ '', ('W') x 4 , '' ],
	factors=>[ undef, (1) x 4,  ] ,
	# units=>[ '', ('kW') x 4 , '' ],
	# factors=>[ undef, (0.001) x 4,  ] ,

};

$p17{'HECS'} = {
	tag=>'Energy control status',
	use=>{ conf1=>1, em=>2 },
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


