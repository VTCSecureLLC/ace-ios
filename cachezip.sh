#!/bin/bash
set -xe

CURRENT_DIR=$(pwd)

SUB_MODS_HASH_DIR="$CURRENT_DIR/sdkcache"
SUB_MODS_HASH_FILE="$SUB_MODS_HASH_DIR/hash.txt"
SUB_MODS_ARCHIVE="$SUB_MODS_HASH_DIR/LiblinphoneSDK.zip"
echo "Creating path and sdk hash."
rm -rf $SUB_MODS_HASH_DIR
mkdir $SUB_MODS_HASH_DIR
git submodule foreach --recursive 'git log --pretty=format:'%H' -n 1' > $SUB_MODS_HASH_FILE
zip -r $SUB_MODS_ARCHIVE liblinphone-sdk