#!/bin/sh

# This script expects to be run from within the Virtue.app project folder and assumes it can find
# its dependencies layed out like checked in CVS. 
#

cd "`echo $0 | sed 's/[^/]*$//'`"

# Build decomm bundle
cd ../../frameworks/decomm
xcodebuild -buildstyle "Deployment Private Framework" clean build || exit 1;

# Build dockExtension bundle 
cd ../../frameworks/dockExtension
xcodebuild -buildstyle "Deployment" clean build || exit 1; 

# Build Zen Framework
cd ../../frameworks/Zen
xcodebuild -buildstyle "Deployment Private Framework" clean build || exit 1; 

# Build Peony Framework 
cd ../../frameworks/Peony
xcodebuild -buildstyle "Deployment Private Framework" clean build || exit 1; 

# Build Virtue Framework 
cd ../../frameworks/Virtue
xcodebuild -buildstyle "Deployment Private Framework" clean build || exit 1; 

# Build Virtue Application 
cd ../../application/Virtue
xcodebuild -target Virtue -buildstyle "Deployment Private Framework" clean build || exit 1; 
