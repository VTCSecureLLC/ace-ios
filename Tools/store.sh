#!/bin/bash
set -ex
./Tools/git_version.sh
./prepare.py -C || true
./prepare.py -d devices -G Ninja --enable-non-free-codecs --enable-gpl-third-parties -DENABLE_WEBRTC_AEC=ON -DENABLE_H263=YES -DENABLE_FFMPEG=YES -DENABLE_H263=YES -DENABLE_AMRWB=NO -DENABLE_AMRNB=NO -DENABLE_OPENH264=YES -DENABLE_G729=YES -DENABLE_MPEG4=NO -DENABLE_H263P=NO -DENABLE_SPEEX=YES -DENABLE_GSM=NO -DENABLE_VCARD=YES
make -j 8

CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-$(for keychain in $(security list-keychains | sed -e 's/\"//g') ; do security find-identity -p codesigning $keychain | grep Distribution | cut -d'"' -f2 ; done | uniq)}"

REVISION=$(git rev-parse --short HEAD)

FILENAME=/tmp/com.vtcsecure.ace.ios-${REVISION}-$(date +%Y%m%d%H%M%S)
ARCHIVE_PATH=${FILENAME}
EXPORT_PATH=${FILENAME}.ipa

KEYCHAIN="$(security list-keychains | head -1 | sed -e 's/"//g')"
security default-keychain -s $KEYCHAIN
security unlock-keychain $KEYCHAIN

xcodebuild -project linphone.xcodeproj -scheme linphone -sdk iphoneos -configuration Release build CODE_SIGNING_REQUIRED=YES CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" CODE_SIGN_ENTITLEMENTS=""

xcodebuild -scheme linphone archive -archivePath ${ARCHIVE_PATH}

#CODE_SIGN_IDENTITY="$(codesign -vv -d ${FILENAME}.xcarchive/Products/Applications/linphone.app 2>&1 | grep Authority= | head -1 | cut -d= -f2-)"

xcodebuild -exportArchive \
           -exportFormat ipa \
           -archivePath ${ARCHIVE_PATH}.xcarchive \
           -exportPath $EXPORT_PATH \
           -exportProvisioningProfile 'com.vtcsecure.ace.ios distribution'

if [ -n "$ITUNESCONNECT_USERNAME" ]; then
  /Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool --upload-app -f $EXPORT_PATH -t ios -u @env:ITUNESCONNECT_USERNAME -p @env:ITUNESCONNECT_PASSWORD
fi

