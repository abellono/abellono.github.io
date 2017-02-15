#!/usr/bin/env bash

# Instructions :
# 1. Move to desired repository that uses buddybuild to build
# 2. Rename to `buddybuild_postbuild.sh`
# 3. Update the INFO_PLIST_PATH variable below and point it to the project's plist
# 4. By default, this only uploads builds that are on the master branch - change BRANCH_TO_UPLOAD if needed
# 5. App icons are expected to be located in the top level bundle identifier folder called 57.png and 512.png
#		For example : App is roomservice -> bundle id is no.abello.roomservicedriverenterprise
#		Place 57.png and 512.png at builds/no.abello.roomservicedriverenterprise/ on abello-web repository
#		Folder may not exist until first build has been uploaded, but it is ok to generate IPA first then place screenshots in correct folder
# 6. Change TITLE variable below to correct value

INFO_PLIST_PATH="./app/Supporting Files/roomservice-ios-driver-Info.plist"
BRANCH_TO_UPLOAD="master"
TITLE="Roomservice"

# Upload debugging symbols to Fabric
"$BUDDYBUILD_WORKSPACE"/Pods/Fabric/upload-symbols -a dc8341530c018e7f89c4dc26f8445bd2d89d0e30 -p ios "$BUDDYBUILD_PRODUCT_DIR"

# Make sure we are in the right directory
cd "$BUDDYBUILD_WORKSPACE" || exit

if [ "$BUDDYBUILD_BRANCH" == "$BRANCH_TO_UPLOAD" ]; then

	echo "Uploading $BUDDYBUILD_BRANCH."

	BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBuildVersion" "$INFO_PLIST_PATH")
	BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBuildNumber" "$INFO_PLIST_PATH")
	BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO_PLIST_PATH")

	UPLOAD_FOLDER_DIR="upload-to-github"
	BUILD_PRODUCTS_DIR="builds"

	BASE_REPO_PATH="$BUDDYBUILD_WORKSPACE"/"$UPLOAD_FOLDER_DIR"

	# Create and change into upload folder that we will copy the IPA into
	git clone -b master --depth 1 git@github.com:abellono/abello-web.git $UPLOAD_FOLDER_DIR
	cd $UPLOAD_FOLDER_DIR || exit

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
	cp "$BUDDYBUILD_WORKSPACE"/"$UPLOAD_FOLDER_DIR"/manifest-default.plist "./manifest.plist"

	# Replace default values in plist
	LINK_REPLACE_STRING=@@@@LINK@@@@
	BUNDLE_VERSION_REPLACE_STRING=@@@@VERSION@@@@
	BUNDLE_IDENTIFIER_REPLACE_STRING=@@@@BUNDLEIDENTIFIER@@@@
	TITLE_REPLACE_STRING=@@@@TITLE@@@@

	IPA_NAME=$(basename "$BUDDYBUILD_IPA_PATH")
	IPA_LINK=https://github.com/abellono/abello-web/blob/master/"$BUILD_PRODUCTS_DIR"/"$CURRENT_BUILD_DEST_DIR"/"$IPA_NAME"

	sed -ie "s/$LINK_REPLACE_STRING/$IPA_LINK/g" ./manifest.plist
	sed -ie "s/$BUNDLE_VERSION_REPLACE_STRING/$BUILD_VERSION/g" ./manifest.plist
	sed -ie "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" ./manifest.plist
	sed -ie "s/$TITLE_REPLACE_STRING/$TITLE/g" ./manifest.plist

	cd "$BASE_REPO_PATH" || exit

    # If this is the first build of this app, add it to the top level app data file
	if [ -z $(grep "$BUNDLE_IDENTIFIER" "_data/app_list.csv") ]; then
	   echo "$BUNDLE_IDENTIFIER" >> "_data/app_list.csv"
	fi

	mkdir "_data/$BUNDLE_IDENTIFIER/"

	APP_BUILD_DATA_FILE="_data/$BUNDLE_IDENTIFIER/$TITLE-$BUILD_VERSION.$BUILD_NUMBER-$BUDDYBUILD_BUILD_ID.json"
	cp "default_app_build_data.json" "$APP_BUILD_DATA_FILE"

	NAME_REPLACE_STRING=@@@@LINK@@@@
	BUNDLE_ID_REPLACE_STRING=@@@@BUNDLE_ID@@@@
	VERSION_REPLACE_STRING=@@@@VERSION@@@@
	BUILD_NUMBER_REPLACE_STRING=@@@@BUILD@@@@
	MANIFEST_REPLACE_STRING=@@@@MANIFEST@@@@

	MANIFEST_LOCATION="$BASE_REPO_PATH/$BUILD_PRODUCTS_DIR/$CURRENT_BUILD_DEST_DIR/manifest.plist"

	sed -ie "s/$NAME_REPLACE_STRING/$TITLE/g" "$APP_BUILD_DATA_FILE"
	sed -ie "s/$BUNDLE_ID_REPLACE_STRING/$BUNDLE_IDENTIFIER/g" "$APP_BUILD_DATA_FILE"
	sed -ie "s/$VERSION_REPLACE_STRING/$BUILD_VERSION/g" "$APP_BUILD_DATA_FILE"
	sed -ie "s/$MANIFEST_REPLACE_STRING/$MANIFEST_LOCATION/g" "$APP_BUILD_DATA_FILE"
	sed -ie "s/$BUILD_NUMBER_REPLACE_STRING/$BUILD_NUMBER/g" "$APP_BUILD_DATA_FILE"

	git add ./*
	git commit -m "Buddybuild: Uploaded IPA for $BUNDLE_IDENTIFIER -> $BUILD_VERSION.$BUILD_NUMBER"
	git push origin master
else
	echo "Not configured to upload to abello-web on $BUDDYBUILD_BRANCH. Currently only uploading on $BRANCH_TO_UPLOAD"
fi
