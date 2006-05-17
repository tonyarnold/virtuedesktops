#!/bin/sh

if test -z "$CONFIGURATION_BUILD_DIR"; then
  # Script was called by the user
  cd $(dirname $0)/Applications/VirtueDesktops
  exec xcodebuild -target VirtueDesktops -configuration "Release" $1
else
  # Script was called by Xcode

  # Check if we're building with a shared build directory - if we are, don't do this craziness
  if [[ `expr "$BUILD_ROOT" : "$SRCROOT"` -ne "0" ]]
  then
    VIRTUE_DIR=$(dirname $(dirname $PROJECT_DIR))

    symlink () {
      if ! test $2 -ef $1; then
        echo
        echo SymLink $1 $2
        mkdir -p $(dirname $2)
        rm -rf $2
        ln -s $1 $2 || exit 1
      fi
    }

    for i in $FRAMEWORKS;
      do
        if test $i = Sparkle; then
          dir=Shared
        else
          dir=Frameworks
        fi
        src=$VIRTUE_DIR/$dir/$i/build/$CONFIGURATION/$i.framework
        tgt=build/$CONFIGURATION/$i.framework
        symlink $src $tgt
      done

      for i in $LIBRARIES
      do
        src=$VIRTUE_DIR/Frameworks/$i/build/$CONFIGURATION/lib$i.a
        tgt=build/$CONFIGURATION/lib$i.a
        symlink $src $tgt
      done

      for i in $BUNDLES
      do
        src=$VIRTUE_DIR/Frameworks/$i/build/$CONFIGURATION/$i.bundle
        tgt=build/$CONFIGURATION/$i.bundle
        symlink $src $tgt
      done
    fi
fi