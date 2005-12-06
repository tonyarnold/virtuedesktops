#!/bin/sh

# This script expects to be run from within the Virtue.app project folder and assumes it can find
# its dependencies layed out like checked in CVS. 
#

cd "`echo $0 | sed 's/[^/]*$//'`"

# Build decomm bundle
cd ../../Frameworks/decomm
xcodebuild -configuration "Deployment Private Framework" clean build || exit 1;

# Build dockExtension bundle 
cd ../../Frameworks/dockExtension
xcodebuild -configuration "Deployment" clean build || exit 1; 

# Build Zen Framework
cd ../../Frameworks/Zen
xcodebuild -configuration "Deployment Private Framework" clean build || exit 1; 

# Build Peony Framework 
cd ../../Frameworks/Peony
xcodebuild -configuration "Deployment Private Framework" clean build || exit 1; 

# Build Virtue Framework 
cd ../../Frameworks/Virtue
xcodebuild -configuration "Deployment Private Framework" clean build || exit 1; 

# Build Virtue Application 
cd ../../Application/Virtue
xcodebuild -target Virtue -configuration "Deployment Private Framework" clean build || exit 1; 
