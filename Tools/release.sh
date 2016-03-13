#!/bin/bash

# Globals
HOCKEYAPP_TEAM_IDS=${HOCKEYAPP_TEAM_IDS:-47813}
HOCKEYAPP_APP_ID=${HOCKEYAPP_APP_ID:-387e68d79a17889131eed3ecf97effd7}

# Only deploy master branch builds

if [ -z "$TRAVIS_BRANCH" ] ; then
  echo "TRAVIS_BRANCH not found. Deploy skipped"
  exit 0
fi

if [ "$TRAVIS_BRANCH" != "master" ] ; then
  echo "TRAVIS_BRANCH is not master. Deploy skipped"
  exit 0
fi

if [ "$TRAVIS_PULL_REQUEST" = "true"  ]; then
  echo "This is a Pull Request. Deploy skipped"
  exit 0
fi

# Prepare codesigning keys

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "Missing AWS_ACCESS_KEY_ID"
  unset BUCKET
fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "Missing AWS_SECRET_ACCESS_KEY"
  unset BUCKET
fi
if [ -n "${BUCKET}" ]; then
  which aws || brew install awscli
  aws s3 sync --quiet s3://${BUCKET}/apple/ sync/
  cd sync
  pwd
  chmod 755 apply.sh
  . ./apply.sh ios
  cd ..
fi
if [ -z "${CODE_SIGN_IDENTITY}" ]; then
  echo "Missing CODE_SIGN_IDENTITY"
fi
if [ -z "${PROVISIONING_PROFILE}" ]; then
  echo "Missing PROVISIONING_PROFILE"
fi

set -e

# Generate an archive for this project

XCARCHIVE_FILE=/tmp/ace-ios.xcarchive

xctool -project linphone.xcodeproj \
       -scheme linphone \
       -sdk iphoneos \
       -configuration Release \
       -derivedDataPath build/derived \
       archive \
       -archivePath $XCARCHIVE_FILE \
       CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
       PROVISIONING_PROFILE="$PROVISIONING_PROFILE"

echo "Generated archive"

# Prepare semantic versioning tag

SHA1=$(git rev-parse --short HEAD)

tag="$(bundle exec semver)-${TRAVIS_BUILD_NUMBER:-1}"-${SHA1}

echo "Version $tag"

# Prepare other variables

IFS=/ GITHUB_REPO=($TRAVIS_REPO_SLUG); IFS=" "

# Create a GitHub release if credentials are available

set +x
if [ -z "$GITHUB_TOKEN" ]; then
  echo GITHUB_TOKEN is not defined. Not creating a GitHub release.
else
  set -x

  curl -sL https://github.com/aktau/github-release/releases/download/v0.6.2/darwin-amd64-github-release.tar.bz2 | \
    bunzip2 -cd | \
    tar xf - --strip=3 -C /tmp/

  chmod 755 /tmp/github-release

  /tmp/github-release release \
    --user ${GITHUB_REPO[0]:-VTCSecureLLC} \
    --repo ${GITHUB_REPO[1]:-ace-ios} \
    --tag $tag \
    --name "Travis-CI Automated $tag" \
    --description "$(git log -1 --pretty=format:%B)" \
    --pre-release || true

fi

# Release via HockeyApp if credentials are available

set +x
if [ -z "$HOCKEYAPP_TOKEN" ]; then
  echo HOCKEYAPP_TOKEN is not defined. Not deploying via HockeyApp.
else
  set -x
  IPA_FILE=/tmp/ace-ios.ipa

  # Generate an ipa from the archive

  xcodebuild -exportArchive \
             -exportFormat ipa \
             -archivePath $XCARCHIVE_FILE \
             -exportPath $IPA_FILE \
             -exportProvisioningProfile 'com.vtcsecure.ace.ios development'

  echo Created IPA file

  # Create a dSYM zip file from the archive build

  DSYM_DIR=$(find build/derived -name '*.dSYM' | head -1)
  DSYM_ZIP_FILE=${IPA_FILE}.dsym.zip
  (cd $(dirname $DSYM_DIR) ; zip -r $DSYM_ZIP_FILE $(basename $DSYM_DIR) )

  echo "Uploading to HockeyApp"
  curl \
    -F "status=2" \
    -F "notify=0" \
    -F "commit_sha=${SHA1}" \
    -F "build_server_url=https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}" \
    -F "repository_url=http://github.com/${TRAVIS_REPO_SLUG}" \
    -F "release_type=2" \
    -F "notes=$(git log -1 --pretty=format:%B)" \
    -F "notes_type=1" \
    -F "mandatory=0" \
    -F "ipa=@$IPA_FILE" \
    -F "dsym=@$DSYM_ZIP_FILE" \
    -F "teams=${HOCKEYAPP_TEAM_IDS}" \
    -H "X-HockeyAppToken: ${HOCKEYAPP_TOKEN}" \
    https://rink.hockeyapp.net/api/2/apps/${HOCKEYAPP_APP_ID}/app_versions/upload \
  | python -m json.tool

  # Distribute via HockeyApp

  #bundle exec ipa distribute:hockeyapp \
  #           --token $HOCKEYAPP_TOKEN \
  #           --file $IPA_FILE \
  #           --dsym $DSYM_ZIP_FILE \
  #           --notes "$(git log -1 --pretty=format:%B)" \
  #           --notify \
  #           --commit-sha ${SHA1} \
  #           --build-server-url "https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}" \
  #           --repository-url "https://github.com/${TRAVIS_REPO_SLUG}"
fi
