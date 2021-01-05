#!/bin/bash

# may put this into cronfile
#  so better to be sure to feel at home...

SCRIPTDIR=`dirname "$0"`
cd $SCRIPTDIR

# and be known there...
. secret.pwd

# DB=chargery
# DB=infini
# table list and associated CF as 
# STRUCTURE=( ["infini"]="AVERAGE" ["status"]="LAST")



echo  "${!STRUCTURE[@]}"
echo  "${STRUCTURE[@]}"


for TN in "${!STRUCTURE[@]}" ;
  do
        TAG="$TN"
	CF="${STRUCTURE[$TN]}"
	TABLENAME=rrd_upload_${TAG}
	TEMPFILE=${TMPDIR}/${TABLENAME}.csv
	RRDFILE=${TAG}.rrd
	# ./rrd2csv.pl pack56.rrd AVERAGE -r 300 -x\; -M -t -f maria1-csv

	echo $RRDFILE ' -> ' $TEMPFILE
	# echo $TEMPFILE
	# echo ${TABLENAME}
	# exit

	./rrd2csv.pl $RRDFILE $CF -r 300 -x\; -M -t -f $TEMPFILE
	# exit

	# mysqlimport -h homeserver -u solarlog-writer -pfoo --local --force  
	#	--ignore-lines=1   --fields-terminated-by=';'   -d   chargery 'maria1.csv'

  	mysqlimport -h $HOST -u $USER -p$PASSWD  --local \
		--ignore --force \
		--ignore-lines=1 --fields-terminated-by=';' \
		$DB $TEMPFILE
  done

