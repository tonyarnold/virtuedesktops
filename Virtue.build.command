#!/bin/sh

if test -z "$CONFIGURATION_BUILD_DIR"; then
  # called by the user
  cd $(dirname $0)/Applications/VirtueDesktops
  exec xcodebuild -target VirtueDesktops -configuration "Release" $1
  # cd "`echo $0 | sed 's/[^/]*$//'`"
  # cd ../../Applications/VirtueDesktops
  # exec xcodebuild -target VirtueDesktops -configuration "Release" clean build || exit 1;
else
  # called by Xcode
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