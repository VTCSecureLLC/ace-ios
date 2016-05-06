#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..
if [ ! -e liblinphone-sdk ] ; then
exec make -j 8
fi
if [ -e libopenh264.a  ]; then
cp -f libopenh264.a liblinphone-sdk/apple-darwin/lib/libopenh264.a
fi
