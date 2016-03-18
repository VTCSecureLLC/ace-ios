#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

./prepare.py -C || true
./prepare.py -d devices -G Ninja --enable-non-free-codecs --enable-gpl-third-parties -DENABLE_WEBRTC_AEC=ON -DENABLE_H263=YES -DENABLE_FFMPEG=YES -DENABLE_H263=YES -DENABLE_AMRWB=NO -DENABLE_AMRNB=NO -DENABLE_OPENH264=YES -DENABLE_G729=YES -DENABLE_MPEG4=NO -DENABLE_H263P=NO -DENABLE_SPEEX=YES
