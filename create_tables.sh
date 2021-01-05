#/bin/bash

. secret.pwd
TMPFILE=$TMPDIR/create_tables-sql

./create_tables.pl > $TMPFILE 2> /dev/null
mysql -h $HOST -u $USER -p$PASSWD  -D $DB < $TMPFILE
