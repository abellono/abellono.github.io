#!/usr/bin/env bash

if ! [[ "$PWD" == *abellono.github.io ]]; then
    echo "Please execute script from the root of the abellono.github.io repository"
    exit
fi

echo "\nThis script configures the files needed to submit IPAs through Buddybuild to our Github Pages site."
echo "I need a few things first...\n"

echo "App Name :"
read name

name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

if [ -f "_apps/$name.md" ]; then
    echo "\n$name already exists. Please go to _apps/$name.md to edit its webpage.\n"
    exit
fi

echo "\nWebpage Title :"
read title

echo "\nWebpage Sub-Title :"
read description

echo "\nBundle Identifier :"
read bundle_id

echo "\nGithub Access Token (make sure it can access abellono/abellono.github.io) :"
read key

mkdir -p "./builds/$bundle_id"

echo "\n"

NAME_REPLACE_STRING=@@@@NAME@@@@
BUNDLE_IDENTIFIER_REPLACE_STRING=@@@@BUNDLE_IDENTIFIER@@@@

cp "./defaults/default_app_page.md" "_apps/$name.md"

sed -i '' -e "s/$NAME_REPLACE_STRING/$name/g" "_apps/$name.md"
sed -i '' -e "s/@@@@PAGE_TITLE@@@@/$title/g" "_apps/$name.md"
sed -i '' -e "s/@@@@PAGE_DESCRIPTION@@@@/$description/g" "_apps/$name.md"
sed -i '' -e "s/$BUNDLE_IDENTIFIER_REPLACE_STRING/$bundle_id/g" "_apps/$name.md"

git add "_apps/$name.md"
git commit -m "Added $name app."
git push origin master

rm -r "./build"

cp "./defaults/buddybuild_postbuild.sh" "./buddybuild_postbuild.sh"
sed -i '' -e "s/&&&NAME&&&/$name/g" "./buddybuild_postbuild.sh"

cp "./defaults/upload.rb" "./build/upload.rb"
sed -i '' -e "s/&&&KEY&&&/$key/g" "./build/upload.rb"

cp "./defaults/manifest_default.rb" "./build/manifest_default.plist"

echo "Done! Move the build folder and buddybuild_postbuild.sh into the target repository."
echo "Please place the app's images (named 512.png and 57.png) inside the build folder."
