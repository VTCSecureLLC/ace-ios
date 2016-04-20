#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

function spawn_fork {
local run_this=$1
$run_this &
}

spawn_fork "git submodule update --init Classes/KIF"
spawn_fork "bundle install"

mkdir -p sdkcache/
git submodule | cut -d'(' -f1 | awk '{print substr($0, 2, length($0))}'  | sort > current.txt
brew install md5sha1sum awscli
SUBMODULE_HASH=$(md5sum current.txt | awk '{print $1}')
#BUCKET=${BUCKET:-vtcsecurellc-travis}
#CACHE=${BUCKET}-cache

if ! aws s3 cp s3://$CACHE/ace-ios/sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip ; then
  echo "Could not sync s3://$CACHE/ace-ios/sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip to sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip"
fi

if [ -f sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip ] ; then
  unzip sdkcache/liblinphone-sdk_${SUBMODULE_HASH}.zip
  exit 0
else
 Tools/dependencies.sh
fi
wait

( sleep 1000 ; ps -eo state,ppid | awk '$1=="Z"{cmd="kill -9 "$2;system(cmd) }') &