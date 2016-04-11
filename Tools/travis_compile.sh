#!/bin/bash
set -xe


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..
CURRENT_DIR=$(pwd)

SUB_MODS_HASH_DIR="$CURRENT_DIR/sdkcache"
SUB_MODS_HASH_FILE="$SUB_MODS_HASH_DIR/hash.txt"
SUB_MODS_ARCHIVE="$SUB_MODS_HASH_DIR/LiblinphoneSDK.zip"

CACHED_MODS=$(cat $SUB_MODS_HASH_FILE |md5)
NEW_MODS=$(git submodule status --recursive | md5 )

if [ $CACHED_MODS = $NEW_MODS ]; then
	echo "dont build, but extract stuff"
    unzip $SUB_MODS_ARCHIVE
    exit 0
else

echo "warning SDK need to be updated!!!"
LOGFILE=/tmp/build_script.out

echo "Building"

touch $LOGFILE

(
  COUNTER=0
  while [  $COUNTER -lt 30 ]; do
    echo The counter is $COUNTER
    let COUNTER=COUNTER+1
    sleep 60
    echo "Muted, but still building. Last 100 lines:"
    tail -100 $LOGFILE
  done
  echo "Timing out after 30 minutes."
) &
MUTED_PID=$!

echo "Running make for dependencies"
$DIR/compile.sh >> $LOGFILE 2>&1

MAKE_RESULT=$?

tail -1000 $LOGFILE
kill $MUTED_PID

echo exit $MAKE_RESULT
exit $MAKE_RESULT

fi


