#!/bin/bash

#
# build_cm7.sh
#
# This script is intended to be invoked from ../build.sh and requires various
# script variables to already be initialized. It is not intended to be invoked
# as a standalone script.
#

cd $ANDROID_DIR

if [ "$CM7_MAKE" = "full" ]; then
  banner "make clobber"
  make clobber

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running 'make clobber' = ${RESULT}"
    echo ""
    return 1
  fi

  banner "build/envsetup.sh && brunch ${PHONE}"
  source build/envsetup.sh && brunch ${PHONE}

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running 'build/envsetup.sh && brunch ${PHONE} = ${RESULT}"
    echo ""
    return 1
  fi

else
  if [ "$CM7_MAKE" = "bacon" ]; then
    banner "build/envsetup.sh && breakfast ${PHONE}"
    source build/envsetup.sh && breakfast ${PHONE}

    RESULT="$?"
    if [ "$RESULT" != "0" ] ; then
      echo ""
      echo "  ERROR running 'build/envsetup.sh && breakfast ${PHONE}' = ${RESULT}"
      echo ""
      return 1
    fi

    # Making the bacon is the main build.
    NUM_CPUS=`grep -c processor /proc/cpuinfo`
    banner "make bacon -j ${NUM_CPUS}"
    make bacon -j ${NUM_CPUS}

    RESULT="$?"
    if [ "$RESULT" != "0" ] ; then
      echo ""
      echo "  ERROR running 'make bacon' = ${RESULT}"
      echo ""
      return 1
    fi
  fi
fi

#
# Rename the ROM to a date tagged name and clean up any old files that might be lying around.
#

# CM7_OLD_ROM is what the Cyanogen makefile produces
CM7_OLD_ROM=${CM7_ROM_DIR}/update-cm-7*DesireHD-KANG-signed.zip

# New ROM is what we rename it to.
# We also need the base name, mainly if building for BlackICE
CM7_NEW_ROM_BASE=${USER}-cm7-${TIMESTAMP}.zip
CM7_NEW_ROM=${CM7_ROM_DIR}/${CM7_NEW_ROM_BASE}

rm -f ${CM7_ROM_DIR}/${USER}-cm7*.zip
rm -f ${CM7_ROM_DIR}/${USER}-cm7*.zip.md5sum
rm -f ${CM7_ROM_DIR}/cyanogen_${PHONE}-ota-eng*.zip

mv $CM7_OLD_ROM $CM7_NEW_ROM
mv $CM7_OLD_ROM.md5sum ${CM7_NEW_ROM}.md5sum

if [ ! -e $CM7_NEW_ROM ] ; then
  echo ""
  echo "  ERROR creating ${CM7_NEW_ROM}"
  echo ""
  return 1
fi

if [ ! -e ${CM7_NEW_ROM}.md5sum ] ; then
  echo ""
  echo "  ERROR creating ${CM7_NEW_ROM}.md5sum"
  echo ""
  return 1
fi

return 0


