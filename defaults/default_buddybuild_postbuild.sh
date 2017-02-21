#!/usr/bin/env bash

ACCESS_TOKEN="d057bbc3f02b5c5284b97b826cacb6d99f1617ad"
BRANCH_TO_UPLOAD="master"
NAME=&&&NAME&&&
EXPECTED_BUNDLE_ID=&&&BUNDLE_ID&&&
REPO_NAME="abellono/abellono.github.io"
BUILD_REPO_NAME="abellono/builds"

function create_github_release {
    TAG_NAME="roomservicetest-$VERSION"
    NAME="Roomservice $VERSION"
    BODY="Buddybuild: Automatic release of version Roomesrvice version $VERSION. Visit https://abellono.github.io/apps/roomservice to download this release."

    API_JSON=$(printf '{"tag_name": "%s","target_commitish": "%s","name": "%s","body": "%s","draft": false,"prerelease": false}' "$TAG_NAME" master "$NAME" "$BODY")
    response=$(curl --data "$API_JSON" "https://api.github.com/repos/$BUILD_REPO_NAME/releases?access_token=$ACCESS_TOKEN")

    id=$(echo "$response" | jsonpath '$.id' | tr -d '[]')
}

function upload_ipa_to_release {

    FILE_NAME=$(basename "$BUDDYBUILD_IPA_PATH")
    GH_ASSET="https://uploads.github.com/repos/$BUILD_REPO_NAME/releases/$id/assets"

    GH_ASSET_NAME="$GH_ASSET?name=$FILE_NAME"
    response=$(curl -H "Authorization: token d057bbc3f02b5c5284b97b826cacb6d99f1617ad" \
                    -H "Content-Type: application/octet-stream" \
     	            -H "Accept: application/vnd.github.v3+json" \
                    --data-binary "@$BUDDYBUILD_IPA_PATH" "$GH_ASSET_NAME")

    browser_download_url=$(echo "$response" | jsonpath '$.browser_download_url' | tr -d '"[]')

    GH_ASSET_NAME="$GH_ASSET?name=57.png"
    response=$(curl -H "Authorization: token d057bbc3f02b5c5284b97b826cacb6d99f1617ad" \
                    -H "Content-Type: image/png" \
     	            -H "Accept: application/vnd.github.v3+json" \
                    --data-binary "@./pictures/$BUNDLE_IDENTIFIER/57.png" "$GH_ASSET_NAME")

    small_image_download_url=$(echo "$response" | jsonpath '$.browser_download_url' | tr -d '"[]')

    GH_ASSET_NAME="$GH_ASSET?name=512.png"
    response=$(curl -H "Authorization: token d057bbc3f02b5c5284b97b826cacb6d99f1617ad" \
                    -H "Content-Type: image/png" \
     	            -H "Accept: application/vnd.github.v3+json" \
                    --data-binary "@./pictures/$BUNDLE_IDENTIFIER/512.png" "$GH_ASSET_NAME")

    large_image_download_url=$(echo "$response" | jsonpath '$.browser_download_url' | tr -d '"[]')
}

function upload_manifest_to_release {

    PATH="./manifest.plist"
    FILE_NAME=$(basename "$PATH")
    GH_ASSET="https://uploads.github.com/repos/$BUILD_REPO_NAME/releases/$id/assets"
    GH_ASSET="$GH_ASSET?name=$FILE_NAME"

    response=$(curl -H "Authorization: token d057bbc3f02b5c5284b97b826cacb6d99f1617ad" \
                    -H "Content-Type: application/xml" \
     	            -H "Accept: application/vnd.github.v3+json" \
                    --data-binary "@$PATH" "$GH_ASSET")

    manifest_download_url=$(echo "$response" | jsonpath '$.browser_download_url' | tr -d '"[]')
}

# Make sure we are in the right directory
cd "$BUDDYBUILD_WORKSPACE" || exit

if [ "$BUDDYBUILD_BRANCH" == "$BRANCH_TO_UPLOAD" ]; then

    echo password | sudo -S gem install jsonpath

    echo "Uploading $BUDDYBUILD_BRANCH."

    INFO_PLIST_PATH="$BUDDYBUILD_PRODUCT_DIR/Info.plist"
    BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$INFO_PLIST_PATH")
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$INFO_PLIST_PATH")
    BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleIdentifier" "$INFO_PLIST_PATH")
    VERSION="$BUILD_VERSION.$BUILD_NUMBER"

    if ! [ "$EXPECTED_BUNDLE_ID" == "$BUNDLE_IDENTIFIER" ]; then
        echo "Bundle identifier $EXPECTED_BUNDLE_ID did not match the build's bundle identifier $BUNDLE_IDENTIFIER."
        exit
    fi

    UPLOAD_FOLDER_DIR="upload-to-github"
    BASE_REPO_PATH="$BUDDYBUILD_WORKSPACE"/"$UPLOAD_FOLDER_DIR"
    DEFAULTS_FOLDER="$BASE_REPO_PATH/defaults"

    git clone -b master --depth 1 "git@github.com:$REPO_NAME.git" "$UPLOAD_FOLDER_DIR"
    cd "$UPLOAD_FOLDER_DIR" || exit

    if ! [ -f "_apps/$NAME.md" ]; then
        echo "Please use configure.sh in the $REPO_NAME repository to set the app up before building it."
        exit
    fi

    # Creates github release and defines the release id as the id environment variable
    create_github_release || exit

    # Upload the IPA to the github release
    upload_ipa_to_release || exit

    # Copy the template manifest file into the current folder with another name
    cp "./defaults/manifest_default.plist" ./manifest.plist

    # Replace default values in plist
    LINK_REPLACE_STRING=@@@@LINK@@@@
    BUNDLE_VERSION_REPLACE_STRING=@@@@VERSION@@@@
    BUNDLE_IDENTIFIER_REPLACE_STRING=@@@@BUNDLE_IDENTIFIER@@@@
    NAME_REPLACE_STRING=@@@@NAME@@@@
    SMALL_PICTURE_REPLACE_STRING=@@@@SMALL_PIC@@@@
    LARGE_PICTURE_REPLACE_STRING=@@@@LARGE_PIC@@@@

    sed -i '' -e "s|$LINK_REPLACE_STRING|$browser_download_url|g" ./manifest.plist
    sed -i '' -e "s/$BUNDLE_VERSION_REPLACE_STRING/$BUILD_VERSION/g" ./manifest.plist
    sed -i '' -e "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" ./manifest.plist
    sed -i '' -e "s/$NAME_REPLACE_STRING/$NAME/g" ./manifest.plist
    sed -i '' -e "s/$SMALL_PICTURE_REPLACE_STRING/$small_image_download_url/g" ./manifest.plist
    sed -i '' -e "s/$LARGE_PICTURE_REPLACE_STRING/$large_image_download_url/g" ./manifest.plist

    upload_manifest_to_release || exit
    rm ./manifest.plist

    # Create the data folder if it does not exist
    [ -d "./_data" ] || mkdir "./_data"

    APP_BUILD_DATA_FILE="./_data/$NAME-$BUILD_VERSION.$BUILD_NUMBER-$BUDDYBUILD_BUILD_ID.json"
    cp "./defaults/default_app_build_data.json" "$APP_BUILD_DATA_FILE"

    BUILD_NUMBER_REPLACE_STRING=@@@@BUILD@@@@
    MANIFEST_REPLACE_STRING=@@@@MANIFEST@@@@

    sed -i '' -e "s/$NAME_REPLACE_STRING/$NAME/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUNDLE_VERSION_REPLACE_STRING/$BUILD_VERSION/g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s|$MANIFEST_REPLACE_STRING|$manifest_download_url|g" "$APP_BUILD_DATA_FILE"
    sed -i '' -e "s/$BUILD_NUMBER_REPLACE_STRING/$BUILD_NUMBER/g" "$APP_BUILD_DATA_FILE"

    git add ./*
    git commit -m "Buddybuild: Uploaded IPA for $BUNDLE_IDENTIFIER -> $BUILD_VERSION.$BUILD_NUMBER"
    git push origin master

else
    echo "Not configured to upload to abellono.github.io on $BUDDYBUILD_BRANCH. Currently only uploading on $BRANCH_TO_UPLOAD"
fi
