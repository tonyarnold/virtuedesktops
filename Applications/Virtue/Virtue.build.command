#!/bin/sh

# This script expects to be run from within the Virtue.app project folder and assumes it can find
# its dependencies layed out like checked in CVS. 
#

cd "`echo $0 | sed 's/[^/]*$//'`"

# Build decomm bundle
cd ../../Frameworks/DockCommunicator
xcodebuild -configuration "Release" clean build || exit 1;

# Build dockExtension bundle 
cd ../../Frameworks/DockExtension
xcodebuild -configuration "Release" clean build || exit 1; 

# Build Zen Framework
cd ../../Frameworks/Zen
xcodebuild -configuration "Release" clean build || exit 1; 

# Build Peony Framework 
cd ../../Frameworks/Peony
xcodebuild -configuration "Release" clean build || exit 1; 

# Build Virtue Framework 
cd ../../Frameworks/Virtue
xcodebuild -configuration "Release" clean build || exit 1; 

# Build Virtue Application 
cd ../../Applications/Virtue
xcodebuild -target Virtue -configuration "Release" clean build || exit 1; 
