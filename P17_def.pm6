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
	fields=>qw(protocol)
} ;

$p17{'ID'} = {
        tag=>'series number',
        fields=>qw(ID)
} ;

$p17{'VFW'} = {
        tag=>'main CPU',
        fields=>qw(version)
} ;

$p17{'VFW2'} = {
        tag=>'secondary CPU',
        fields=>qw(version)
} ;

$p17{'VFW2'} = {
        tag=>'secondary CPU',
        fields=>qw(version)
} ;






# keep this 1; below here! –––––––––––––––––––––––––––––––––––––––––––-
1;
