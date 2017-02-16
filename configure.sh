#!/usr/bin/env bash

if ! [[ "$PWD" == *abello-web ]]; then
    echo "Please execute script from the root of the abello-web repository"
    exit
fi

echo "\nThis script configures the files needed to submit IPAs through Buddybuild to our Github Pages site."
echo "I need a few things first...\n"

echo "App Name :"
read name

name="$name" | tr '[:upper:]' '[:lower:]'

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
git commit -m "Added $name app"
git push origin master

rm "./buddybuild_postbuild.sh"
cp "./defaults/default_buddybuild_postbuild.sh" "./buddybuild_postbuild.sh"

echo "Please place the apps images (named 512.png and 57.png) inside ./builds/$bundle_id/."
echo "\nDone! Cut the buddybuild_postbuild.sh script into the root directory of the repository you would like to start uploading to abello-web."
