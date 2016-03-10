#!/bin/bash
set -xe
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
