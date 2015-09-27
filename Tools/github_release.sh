#!/bin/bash

# Only deploy master branch builds

if [ -z "$TRAVIS_BRANCH" ] ; then
  echo "TRAVIS_BRANCH not found. Deploy skipped"
  exit 0
fi

if [ "$TRAVIS_BRANCH" != "master" ] ; then
  echo "TRAVIS_BRANCH is not master. Deploy skipped"
  exit 0
fi

set -xe

# Generate an archive for this project

XCARCHIVE_FILE=/tmp/ace-ios.xcarchive

xctool -project linphone.xcodeproj \
       -scheme linphone \
       -sdk iphoneos \
       -configuration Debug \
       -derivedDataPath build/derived \
       archive \
       -archivePath $XCARCHIVE_FILE 1>/dev/null

# Prepare semantic versioning tag

SHA1=$(git rev-parse --short HEAD)

echo "$(bundle exec semver)-${TRAVIS_BUILD_NUMBER:-1}"-${SHA1} > LastCommit.txt
git log -1 --pretty=format:%B >> LastCommit.txt

tag="$(bundle exec semver)-${TRAVIS_BUILD_NUMBER:-1}"-${SHA1}

# Prepare other variables

IFS=/ GITHUB_REPO=($TRAVIS_REPO_SLUG)

# Create a GitHub release if credentials are available

set +x
if [ -n "$GITHUB_TOKEN" ]; then
  set -x

  curl -sL https://github.com/aktau/github-release/releases/download/v0.6.2/darwin-amd64-github-release.tar.bz2 | \
    bunzip2 -cd | \
    tar xf - --strip=3 -C /tmp/

  chmod 755 /tmp/github-release

  /tmp/github-release release \
    --user ${GITHUB_REPO[0]:-VTCSecureLLC} \
    --repo ${GITHUB_REPO[1]:-ace-mac} \
    --tag $tag \
    --name "Travis-CI Automated $tag" \
    --description "$(git log -1 --pretty=format:%B)" \
    --pre-release || true

fi

# Release via HockeyApp if credentials are available

set +x
if [ -n "$HOCKEYAPP_TOKEN" ]; then
  set -x
  IPA_FILE=/tmp/ace-ios.ipa

  # Generate an ipa from the archive

  xcodebuild -exportArchive \
             -exportFormat ipa \
             -archivePath $XCARCHIVE_FILE \
             -exportPath $IPA_FILE \
             -exportProvisioningProfile 'iOSTeam Provisioning Profile: com.vtcsecure.*'

  # Create a dSYM zip file from the archive build

  DSYM_DIR=$(find build/derived -name '*.dSYM' | head -1)
  DSYM_ZIP_FILE=${IPA_FILE}.dsym.zip
  (cd $(dirname $DSYM_DIR) ; zip -r $DSYM_ZIP_FILE $(basename $DSYM_DIR) )

  # Distribute via HockeyApp

  bundle exec ipa distribute:hockeyapp \
             --token $HOCKEYAPP_TOKEN \
             --file $IPA_FILE \
             --dsym $DSYM_ZIP_FILE \
             --notes LastCommit.txt \
             --notify \
             --commit-sha ${SHA1} \
             --build-server-url "https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}" \
             --repository-url "https://github.com/${TRAVIS_REPO_SLUG}"
fi
