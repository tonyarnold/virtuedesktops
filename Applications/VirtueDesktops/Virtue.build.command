#!/bin/sh

# This script expects to be run from within the Virtue.app project folder and assumes it can find
# its dependencies layed out like checked in CVS. 
#
# Also, the build structure of Virtue expects that you use a shared build directory at present
# this can be set from the Xcode build preferences
#

cd "`echo $0 | sed 's/[^/]*$//'`"
cd ../../Applications/Virtue
xcodebuild -target Virtue -configuration "Release" clean build || exit 1; 
