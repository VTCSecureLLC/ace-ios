#!/bin/bash

if [ ! -f fabric.properties ] ; then
  if [ -z "$TRAVIS_BRANCH" ] ; then
    echo "TRAVIS_BRANCH not found. Deploy skipped"
    exit 0
  fi

  if [ "$TRAVIS_BRANCH" != "master" ] ; then
    echo "TRAVIS_BRANCH is not master. Deploy skipped"
    exit 0
  fi

  ./Tools/prepare_crashlytics.sh
fi

source fabric.properties
./Crashlytics.framework/run $apiKey $apiSecret
echo "$(bundle exec semver)-${TRAVIS_BUILD_NUMBER:-1}"-$(git rev-parse --short HEAD) > LastCommit.txt
git log -1 --pretty=format:%B >> LastCommit.txt
./Crashlytics.framework/submit $apiKey $apiSecret -notesPath LastCommit.txt

set -x

if [ -n "$GITHUB_TOKEN" ]; then

curl -sL https://github.com/aktau/github-release/releases/download/v0.6.2/darwin-amd64-github-release.tar.bz2 | bunzip2 -cd | tar xf - --strip=3 -C /tmp/

chmod 755 /tmp/github-release

tag="$(bundle exec semver)-${TRAVIS_BUILD_NUMBER:-1}"-$(git rev-parse --short HEAD)

/tmp/github-release release \
    --user VTCSecureLLC \
    --repo ace-iphone \
    --tag $tag \
    --name "Travis-CI Automated $tag" \
    --description "$(git log -1 --pretty=format:%B)" \
    --pre-release

find . -name '*.ipa' -print | while read ipa; do

  ls -la "$ipa"

  echo "Uploading $ipa github release $tag"

  /tmp/github-release upload \
      --user VTCSecureLLC \
      --repo ace-iphone \
      --tag $tag \
      --name $(basename "$ipa") \
      --file "$ipa"

done

fi

