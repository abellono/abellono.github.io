#!/usr/bin/env bash

BRANCH_TO_UPLOAD="master"
NAME=&&&NAME&&&
EXPECTED_BUNDLE_ID=&&&BUNDLE_ID&&&

# Make sure we are in the right directory
cd "$BUDDYBUILD_WORKSPACE" || exit

if [ "$BUDDYBUILD_BRANCH" == "$BRANCH_TO_UPLOAD" ]; then

    echo "Uploading $BUDDYBUILD_BRANCH."

    INFO_PLIST_PATH="$BUDDYBUILD_PRODUCT_DIR/Info.plist"

    BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$INFO_PLIST_PATH")
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$INFO_PLIST_PATH")
    BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleIdentifier" "$INFO_PLIST_PATH")

    if ! [ "$EXPECTED_BUNDLE_ID" == "$BUNDLE_IDENTIFIER" ]; then
        echo "Bundle identifier $EXPECTED_BUNDLE_ID did not match the build's bundle identifier $BUNDLE_IDENTIFIER."
        exit
    fi

    UPLOAD_FOLDER_DIR="upload-to-github"
    BUILD_PRODUCTS_DIR="builds"
    BASE_REPO_PATH="$BUDDYBUILD_WORKSPACE"/"$UPLOAD_FOLDER_DIR"
    DEFAULTS_FOLDER="$BASE_REPO_PATH/defaults"

    # Create and change into upload folder that we will copy the IPA into
    git clone -b master --depth 1 git@github.com:abellono/abellono.github.io.git $UPLOAD_FOLDER_DIR
    cd $UPLOAD_FOLDER_DIR || exit

    if ! [ -f "_apps/$NAME.md" ]; then
        echo "Please use configure.sh in the abellono/abellono.github.io repository to set the app up before building it."
        exit
    fi

    # Create the build folder if it does not exist and cd into it
    [ -d $BUILD_PRODUCTS_DIR ] || mkdir $BUILD_PRODUCTS_DIR
    cd $BUILD_PRODUCTS_DIR || exit

    # Create the product folder - BUDDYBUILD_BUILD_ID is unique, so we won't overwrite
    CURRENT_BUILD_DEST_DIR="$BUNDLE_IDENTIFIER"/"$BUILD_VERSION"."$BUILD_NUMBER"/"$BUDDYBUILD_BUILD_ID"
    mkdir -p "$CURRENT_BUILD_DEST_DIR"/
    cd "$CURRENT_BUILD_DEST_DIR"/ || exit

    # Copy the IPA into the current folder
    cp "$BUDDYBUILD_IPA_PATH" "."

    # Copy the template manifest file into the current folder with another name
    cp "$DEFAULTS_FOLDER"/manifest_default.plist "./manifest.plist"

    # Replace default values in plist
    LINK_REPLACE_STRING=@@@@LINK@@@@
    BUNDLE_VERSION_REPLACE_STRING=@@@@VERSION@@@@
    BUNDLE_IDENTIFIER_REPLACE_STRING=@@@@BUNDLE_IDENTIFIER@@@@
    NAME_REPLACE_STRING=@@@@NAME@@@@

    IPA_NAME=$(basename "$BUDDYBUILD_IPA_PATH")
    IPA_LINK="https://github.com/abellono/abellono.github.io/blob/master/$BUILD_PRODUCTS_DIR/$CURRENT_BUILD_DEST_DIR/$IPA_NAME"

    sed -i '' -e "s|$LINK_REPLACE_STRING|$IPA_LINK|g" ./manifest.plist
    sed -i '' -e "s/$BUNDLE_VERSION_REPLACE_STRING/$BUILD_VERSION/g" ./manifest.plist
    sed -i '' -e "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" ./manifest.plist
    sed -i '' -e "s/$NAME_REPLACE_STRING/$NAME/g" ./manifest.plist

    cd "$BASE_REPO_PATH" || exit

    APP_BUILD_DATA_FILE="./_data/$NAME-$BUILD_VERSION.$BUILD_NUMBER-$BUDDYBUILD_BUILD_ID.json"
    cp "./defaults/default_app_build_data.json" "$APP_BUILD_DATA_FILE"

    BUILD_NUMBER_REPLACE_STRING=@@@@BUILD@@@@
    MANIFEST_REPLACE_STRING=@@@@MANIFEST@@@@
    MANIFEST_LOCATION="$BASE_REPO_PATH/$BUILD_PRODUCTS_DIR/$CURRENT_BUILD_DEST_DIR/manifest.plist"

    sed -i '' -e "s/$NAME_REPLACE_STRING/$NAME/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUNDLE_VERSION_REPLACE_STRING/$BUILD_VERSION/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s|$MANIFEST_REPLACE_STRING|$MANIFEST_LOCATION|g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUILD_NUMBER_REPLACE_STRING/$BUILD_NUMBER/g" "$APP_BUILD_DATA_FILE"

    git add ./*
    git commit -m "Buddybuild: Uploaded IPA for $BUNDLE_IDENTIFIER -> $BUILD_VERSION.$BUILD_NUMBER"
    git push origin master

else
    echo "Not configured to upload to abellono.github.io on $BUDDYBUILD_BRANCH. Currently only uploading on $BRANCH_TO_UPLOAD"
fi
