# infini protocol P17 translated to a perl hash to guide all processing
# Infini10KW&15KWprotocol.pdf
# in
#

# use Exporter qw(import);
# our @EXPORT = qw (p17);

our %p17 = ( 
# 	foo=>'bar'
);

# our %p17;
# $p17{'tralala'}='pipapo';



$p17{'PI'} = {
	tag=>'protocol ID',
	fields=>[ qw(protocol) ]
} ;

$p17{'ID'} = {
        tag=>'series number',
        fields=>[ qw(ID) ]
} ;

$p17{'VFW'} = {
        tag=>'main CPU',
        fields=>[ qw(version) ]
} ;

$p17{'VFW2'} = {
        tag=>'secondary CPU'  ,
        fields=>[ qw(version) ]
} ;


$p17{'MD'} = {
        tag=>'device model',
        fields=>[ 'Machine number' ,  'Output rated VA', 'Output power factor', 
	'AC input phase number', 'AC output phase number', 'Norminal AC output voltage', 
	'Norminal AC input voltage', 'Battery piece number', 
	'Battery standard voltage per unit' ]
} ;

$p17{'GS'} = {
        tag=>'General status',
        fields=>[
	'Solar input voltage Solar1', 'Solar input voltage Solar2', 
	'Solar input current Solar1', 'Solar input current Solar2', 
	'Battery voltage', 'Battery capacity', 'Battery current', 
	'AC input voltage R', 'AC input voltage S', 'AC input voltage T', 
	'AC input frequency', 
	'', '', '', 
	'AC output voltage R', 'AC output voltage S', 'AC output voltage T', 
	'AC output frequency', 
	'Inner temperature', 'Component max temp', 'External battery temp', 
	'Setting change bit' ]
} ;


$p17{'PS'} = {
        tag=>'Power status',
        fields=>[
	'Solar input power 1', 'Solar input power 2', 
	'', '', '', '',
	'AC output active power R', 'AC output active power S', 'AC output active power T', 
	'AC output total active power', 
	'AC output apperent power R', 'AC output apperent power S', 'AC output apperent power T',
	'AC output total apperent power', 
	'AC output power percentage', 'AC output connect status',
	'Solar input 1 work status', 'Solar input 2 work status',
	'Battery power direction', 'DC/AC power direction', 'Line power direction'       
	]
} ;


$p17{'MOD'} = {
        tag=>'Working mode ',
        fields=>['mode' ]
} ;

$p17{'T'} = {
        tag=>'inverter time',
        fields=>['timestring' ]
} ;


## -----------------------

$p17{'#'} = {
        tag=>' ',
        fields=>[ ]
} ;


## keep this 1; below here! ~~~~~~~~ 
1;


