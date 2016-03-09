#!/bin/bash
set -ex

./prepare.py -d devices -G Ninja --enable-non-free-codecs --enable-gpl-third-parties -DENABLE_WEBRTC_AEC=ON -DENABLE_H263=YES -DENABLE_FFMPEG=YES -DENABLE_H263=YES -DENABLE_AMRWB=NO -DENABLE_AMRNB=NO -DENABLE_OPENH264=YES -DENABLE_G729=NO -DENABLE_MPEG4=NO -DENABLE_H263P=NO

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
make >> $LOGFILE 2>&1

MAKE_RESULT=$?

tail -1000 $LOGFILE
kill $MUTED_PID

echo exit $MAKE_RESULT
exit $MAKE_RESULT
