#!/bin/sh

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")
WORKDIR=$SCRIPTDIR/../sql

# Merge all scripts for SqlServer
OUTFILE=$WORKDIR/SQLServer-All.sql
cat $WORKDIR/SQLServer/*.sql > $OUTFILE
# Replace all BOM inside with UTF16-LE newlines
sed -i 's/\(.\)\(\xff\xfe\)/\1\x0d\x00\x0a\x00/g' $OUTFILE
