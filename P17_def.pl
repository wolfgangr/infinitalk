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
	'Battery standard voltage per unit' ]
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


## -----------------------

$p17{'#'} = {
        tag=>' ',
        fields=>[ ]
} ;


## keep this 1; below here! ~~~~~~~~ 
1;


