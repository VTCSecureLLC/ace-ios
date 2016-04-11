#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

mkdir -p sdkcache/
git submodule | cut -d'(' -f1 | sort > sdkcache/current.txt
which md5sum || brew install md5sha1sum
SUBMODULE_HASH=$(md5sum sdkcache/current.txt | awk '{print $1}')
mv sdkcache/current.txt liblinphone-sdk_${SUBMODULE_HASH}_submodules.txt
which aws || brew install awscli
BUCKET=${BUCKET:-vtcsecurellc-travis}
CACHE=${BUCKET}-cache
if ! aws s3 sync s3://$CACHE/ace-ios/sdkcache/ sdkcache/ ; then
  echo "Could not sync s3://$CACHE/ace-ios/sdkcache/ to sdkcache/"
fi

if [ -f sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip ] ; then
  unzip sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip
  exit 0
else
  echo "There is no existing cached SDK build for this set of submodules."
fi

echo "REBUILDING SDK FOR ${SUBMODULE_HASH}"

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
if $DIR/compile.sh >> $LOGFILE 2>&1
then
  MAKE_RESULT=$?
  zip -r sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip liblinphone-sdk
  if ! aws s3 sync sdkcache/ s3://$CACHE/ace-ios/sdkcache/ ; then
    echo "Encountered a problem syncing sdkcache/ folder to s3://$CACHE/ace-ios/sdkcache/"
  fi
else
  MAKE_RESULT=$?
fi

tail -1000 $LOGFILE
kill $MUTED_PID

echo exit $MAKE_RESULT
exit $MAKE_RESULT
