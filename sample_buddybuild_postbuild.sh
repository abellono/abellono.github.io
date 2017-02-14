#!/usr/bin/env bash

# Instructions :
# 1. Move to desired repository that uses buddybuild to build
# 2. Rename to `buddybuild_postbuild.sh`
# 3. Update the INFO_PLIST_PATH variable below and point it to the project's plist
# 4. By default, this only uploads builds that are on the master branch - change BRANCH_TO_UPLOAD if needed
# 5. App icons are expected to be located in the top level bundle identifier folder called 57.png and 512.png
#		For example : App is roomservice -> bundle id is no.abello.roomservicedriverenterprise
#		Place 57.png and 512.png builds/no.abello.roomservicedriverenterprise/
#		Folder may not exist until first build has been uploaded, but it is ok to generate IPA first then place screenshots in correct folder
# 6. Change TITLE variable below to correct value

INFO_PLIST_PATH="./app/Supporting Files/roomservice-ios-driver-Info.plist" 
BRANCH_TO_UPLOAD="master"
TITLE="Roomservice"

# Upload debugging symbols to Fabric
"$BUDDYBUILD_WORKSPACE"/Pods/Fabric/upload-symbols -a dc8341530c018e7f89c4dc26f8445bd2d89d0e30 -p ios "$BUDDYBUILD_PRODUCT_DIR"

# Make sure we are in the right directory
cd "$BUDDYBUILD_WORKSPACE" || exit

if [[ "$BUDDYBUILD_BRANCH" =~ "$BRANCH_TO_UPLOAD" ]]; then
	
	BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBuildVersion" "$INFO_PLIST_PATH")
	BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBuildNumber" "$INFO_PLIST_PATH")
	BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO_PLIST_PATH")

	UPLOAD_FOLDER_DIR="upload-to-github"
	BUILD_PRODUCTS_DIR="builds"

	# Create and change into upload folder that we will copy the IPA into
	git clone -b master --depth 1 git@github.com:abellono/abello-web.git $UPLOAD_FOLDER_DIR
	cd $UPLOAD_FOLDER_DIR || exit

	# Create the build folder if it does not exist and cd into it
	[ -d $BUILD_PRODUCTS_DIR ] || mkdir $BUILD_PRODUCTS_DIR
	cd $BUILD_PRODUCTS_DIR || exit

	# Create the product folder - BUDDYBUILD_BUILD_ID is unique, so we won't overwrite
	CURRENT_BUILD_DEST_DIR="$BUNDLE_IDENTIFIER"/"$BUILD_VERSION"."$BUILD_NUMBER"/"$BUDDYBUILD_BUILD_ID"
	mkdir -p "$CURRENT_BUILD_DEST_DIR"/
	cd $CURRENT_BUILD_DEST_DIR/ || exit

	# Copy the IPA into the current folder
	cp "$BUDDYBUILD_IPA_PATH" "."

	# Copy the template manifest file into the current folder with another name
	cp "$BUDDYBUILD_WORKSPACE"/"$UPLOAD_FOLDER_DIR"/manifest-default.plist "./manifest.plist"

	# Replace default values in 

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

	git add ./*
	git commit -m "Buddybuild: Uploaded IPA for $BUNDLE_IDENTIFIER -> $BUILD_VERSION.$BUILD_NUMBER"
	git push origin master
fi