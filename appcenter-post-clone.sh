#!/usr/bin/env bash

cd $APPCENTER_SOURCE_DIRECTORY/..

# Clone the Celestia repo (modified)
git clone https://github.com/levinli303/Celestia --branch releases/1.3 --depth=1
cd Celestia
git submodule update --init
cd ..

# Clone the CelestiaCore repo
git clone https://github.com/levinli303/CelestiaCore --branch releases/1.3 --depth=1
cd CelestiaCore
git submodule update --init

# Install gettext, needed for translation
brew install gettext
