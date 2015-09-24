#!/bin/bash
set -x

echo "Running make"

touch /tmp/make.out

(
  COUNTER=0
  while [  $COUNTER -lt 30 ]; do
    echo The counter is $COUNTER
    let COUNTER=COUNTER+1
    sleep 60
    echo "Muted, but still building. Last 100 lines:"
    tail -100 /tmp/make.out
  done
  echo "Timing out after 30 minutes."
) &
MUTED_PID=$!

echo "Running make for dependencies"
make -j4 -s >> /tmp/make.out 2>&1

MAKE_RESULT=$?

tail -1000 /tmp/make.out
kill $MUTED_PID

echo exit $MAKE_RESULT
exit $MAKE_RESULT
