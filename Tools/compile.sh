#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..
if [ ! -e liblinphone-sdk ] ; then
exec make -j 8
fi
cp -f libopenh264.a liblinphone-sdk/apple-darwin/lib/libopenh264.a