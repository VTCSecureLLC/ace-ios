#!/bin/bash
set -xe

CURRENT_DIR=$(pwd)

SUB_MODS_HASH_DIR="$CURRENT_DIR/submods-hash"
SUB_MODS_HASH_FILE="$SUB_MODS_HASH_DIR/hash.txt"
SUB_MODS_ARCHIVE="$SUB_MODS_HASH_DIR/submodules.zip" 
if [ ! -d "$SUB_MODS_HASH_DIR" ]; then
	echo "Creating path and submod hash."
	mkdir $SUB_MODS_HASH_DIR
	git submodule > $SUB_MODS_HASH_FILE	
fi

CACHED_MODS=$(cat $SUB_MODS_HASH_FILE)
NEW_MODS=$(git submodule)

if [ "$CACHED_MODS" = "$NEW_MODS" ]; then
	echo "same submods"
	echo "dont build, but extract stuff"
		rm -rf submodules
		zip -s 0 submods-hash/submodules.zip --out unsplit-submodules.zip
		unzip unsplit-submodules.zip 
else

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

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


