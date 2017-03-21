#!/usr/bin/env bash

echo password | sudo -S gem install octokit

export IPA_PATH="$BUDDYBUILD_IPA_PATH"
export INFO_PLIST_PATH="$BUDDYBUILD_PRODUCT_DIR/Info.plist"
export BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$INFO_PLIST_PATH")
export BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$INFO_PLIST_PATH")
export BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleIdentifier" "$INFO_PLIST_PATH")
export VERSION_STRING="$BUILD_VERSION.$BUILD_NUMBER"
export NAME="&&&NAME&&&"

ruby ./build/upload.rb "$NAME" "$VERSION_STRING" "$IPA_PATH" "$BUNDLE_IDENTIFIER"
