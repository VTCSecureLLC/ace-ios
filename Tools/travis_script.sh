#!/bin/bash
./Tools/prepare_crashlytics.sh
if [ -f fabric.properties ] ; then
  source fabric.properties
  ./Fabric.framework/run $apiKey $apiSecret
fi
