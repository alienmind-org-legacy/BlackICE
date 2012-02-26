#!/bin/bash

#
# build_cm7.sh
#
# This script is intended to be invoked from ../build.sh and requires various
# script variables to already be initialized. It is not intended to be invoked
# as a standalone script.
#

cd ${CM7_DIR}

if [ "$CROSS_COMPILE" = "" ]; then
  export CROSS_COMPILE=${CM7_DIR}/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
fi
if [ "$TARGET_TOOLS_PREFIX" = "" ]; then
  export TARGET_TOOLS_PREFIX=${CM7_DIR}/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
fi
if [ "$ARCH" = "" ]; then
  export ARCH=arm
fi

if [ "$CCACHE_TOOL_DIR" = "" ] ; then
  CCACHE_TOOL_DIR=${CM7_DIR}/prebuilt/linux-x86/ccache
  export PATH=$PATH:${CCACHE_TOOL_DIR}
fi

if [ "$CCACHE_DIR" = "" ] ; then
  CCACHE_DIR=${HOME}/.ccache
fi

##echo ""
##echo "CROSS_COMPILE       = '${CROSS_COMPILE}"
##echo "TARGET_TOOLS_PREFIX = '${TARGET_TOOLS_PREFIX}'"
##echo "ARCH                = '${ARCH}'"
##echo "CCACHE_TOOL         = '${CCACHE_TOOL_DIR}'"
##echo "CCACHE_DIR          = '${CCACHE_DIR}'"
##echo "PATH                = '${PATH}'"

${CCACHE_TOOL_DIR}/ccache -M 10G


if [ "$CM79_MAKE" = "full" ]; then
  banner "make clobber"
  make clobber >> $LOG || ExitError "Running 'make clobber'"

  banner "build/envsetup.sh && brunch ${PHONE}"
  (source build/envsetup.sh && brunch ${PHONE}) >> $LOG || ExitError "Running 'build/envsetup.sh && brunch ${PHONE}'"

else
  if [ "$CM79_MAKE" = "bacon" ]; then
    banner "build/envsetup.sh && breakfast ${PHONE}"
    source build/envsetup.sh >> $LOG || ExitError "Running 'build/envsetup.sh'"
    breakfast ${PHONE} >> $LOG || ExitError "Running 'breakfast ${PHONE}'"

    # Making the bacon is the main build.
    NUM_CPUS=`grep -c processor /proc/cpuinfo`
    banner "make bacon -j ${NUM_CPUS}"
    make bacon -j ${NUM_CPUS} >> $LOG || ExitError "Running 'make bacon'"
  fi
fi

#
# NOTE: Our variable names use CM_ instead of CM7_. This makes the master build.sh
#       file to be simpler, because both this file and build_cm9.sh do the same thing.
#

#
# Rename the ROM to a date tagged name and clean up any old files that might be lying around.
#
#CM_OLD_ROM=${CM_ROM_DIR}/update-cm-7*DesireHD-KANG-signed.zip
CM_OLD_ROM=${CM_ROM_DIR}/update-cm-*-signed.zip

# New ROM is what we rename it to.
# We also need the base name, mainly if building for BlackICE
CM_NEW_ROM_BASE=${USER}-cm7-${TIMESTAMP}.zip
CM_NEW_ROM=${CM_ROM_DIR}/${CM_NEW_ROM_BASE}

rm -f ${CM_ROM_DIR}/${USER}-cm7*.zip
rm -f ${CM_ROM_DIR}/${USER}-cm7*.zip.md5sum
rm -f ${CM_ROM_DIR}/cyanogen_${PHONE}-ota-eng*.zip

# Delete the md5sum file that the 'make' just created because it will contain
# the default Cyanogen name. We will recreate the md5sum next using the new ROM.
rm -f $CM_OLD_ROM.md5sum


mv $CM_OLD_ROM $CM_NEW_ROM

CM_MD5SUM=`md5sum -b $CM_NEW_ROM`
echo "${CM_MD5SUM}" > ${CM_NEW_ROM}.md5sum


if [ ! -e $CM_NEW_ROM ] ; then
  ExitError "Creating ${CM_NEW_ROM}"
fi

if [ ! -e ${CM_NEW_ROM}.md5sum ] ; then
  ExitError "Creating ${CM_NEW_ROM}.md5sum"
fi

return 0


