#!/bin/bash

#
# build.sh
#

#
# This is the main script for building a KANGed ROM for either CyanogenMod (CM7)
# or BlackICE (BlackICE is built on top of CM7).
#  - You can build a CM7 KANG from the source code and optionally do a BlackICE
#    build on top of that.
#  - You can do just a BlackICE build (but it requires a previous built CM7 build
#    to work from).
#
# If you don't know how to get or setup the CM7 sources then here is one link that
# may help you get started
#   http://wiki.cyanogenmod.com/index.php?title=Compile_CyanogenMod_for_Ace
#
# Note that "ace" is referenced above, which is the codename for the Desire HD.
# Although this script *might* work for other phones it has only been tested for
# ACE builds.
#
# See ICEDroid/build_scripts/init.sh for command line argument information.
#

# Get the full path of the directory that the script is running in.
# This is expected to be the ICEDroid/tools directory.
BUILD_DIR=$(cd "$(dirname "$0")"; pwd)

# The include scripts are expected to be in ICEDroid/build_scripts
SCRIPT_DIR=${BUILD_DIR}/../build_scripts

# Process all the command line arguments before changing directory in case
# there are any relative paths.
source ${SCRIPT_DIR}/init.sh

RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR running 'build_scripts/init.sh' = ${RESULT}"
  echo ""
  exit 1
fi

if [ "$CHECK_ONLY" != "0" ]; then
  # Quit without building anything.
  exit 0
fi

# Delay so we have time to read the build information.
sleep 4


if [ "$CLEAN_TYPE" = "cm7" ] || [ "$CLEAN_TYPE" = "all" ]; then
  cd $ANDROID_DIR

  banner "Cleaning CM7 (make clobber)"
  make clobber

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR doing CM7 clean, 'make clobber' = ${RESULT}"
    echo ""
    exit 1
  fi
fi

if [ "$CLEAN_TYPE" = "bi" ] || [ "$CLEAN_TYPE" = "all" ]; then
  banner "Cleaning BlackICE"

  # We don't provide any parameters, but build_blackice.sh will do a clean because
  # the variable CLEAN_ONLY is 1.
  source ${SCRIPT_DIR}/build_blackice.sh

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR doing BlackICE clean, 'build_scripts/build_blackice.sh' = ${RESULT}"
    echo ""
    exit 1
  fi
fi

if [ "$CLEAN_ONLY" = "1" ]; then
  exit 0
fi


#
# We do all the syncing first so that any error due to syncing is detected before
# spending a long time building. Also in case there are any patches to apply we
# can do all of them before building.
#

# Do a CM7 'repo sync' if requested
if [ "$DO_CM7" = "1" ] && ([ "$SYNC_TYPE" = "cm7" ] || [ "$SYNC_TYPE" = "all" ]); then
  banner "CM7 repo sync -j16"
  cd ${ANDROID_DIR}
  repo sync -j16

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running CM7 'repo sync' = ${RESULT}"
    echo ""
    exit 1
  fi

fi

# Do a BlackICE 'git pull' if requested
if [ "$DO_BLACKICE" = "1" ] && ([ "$SYNC_TYPE" = "bi" ] || [ "$SYNC_TYPE" = "all" ]); then
  banner "BlackICE git pull"
  cd ${BLACKICE_DIR}

  git pull

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running BlackICE 'git pull' = ${RESULT}"
    echo ""
    exit 1
  fi

fi

#
# See if there are any GIT or DIFF patches to apply
#
if [ "$ALL_PATCH_LIST" != "" ]; then
  for PATCH_ITEM in $ALL_PATCH_LIST
  do
    PATCH_DIR=${PATCH_ITEM%%,*}
    PATCH_FILE=${PATCH_ITEM##*,}

    banner "Applying patch: ${PATCH_FILE}"
    if [ ! -d $PATCH_DIR ]; then
      echo ""
      echo " ERROR patch file destination directory does not exist, '${PATCH_DIR}"
      echo ""
      exit 1
    fi

    # Change into the directory that the patch file needs to patch into.
    cd ${PATCH_DIR}

    if [ "${PATCH_FILE:(-4)}" = ".git" ]; then
      # .git patches are just like a shell script. Execute the patch.
      $PATCH_FILE
    else
      # .patch patches are diff files
      patch --no-backup-if-mismatch -p0 < ${PATCH_FILE}
    fi

    RESULT="$?"
    if [ "$RESULT" != "0" ] ; then
      echo ""
      echo "  ERROR applying patch file '$PATCH_FILE' = ${RESULT}"
      echo ""
      exit 1
    fi

    cd - &>/dev/null

  done
fi

#
# Now do the build(s)
#
TIMESTAMP=`date +%Y%m%d_%H%M%S`

if [ "$DO_CM7" = "1" ]; then
  source ${SCRIPT_DIR}/build_cm7.sh

  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running 'build_scripts/build_cm7.sh' = ${RESULT}"
    echo ""
    exit 1
  fi

  # If we are also building for BlackICE then we need to copy the CM7 result
  # over to the BlackICE directory so we can build on top of it.
  if [ "$DO_BLACKICE" = "1" ]; then
    echo ""
    echo "cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE}"
    cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE}
    echo ""
  fi
fi


if [ "$DO_BLACKICE" = "1" ]; then
  if [ "$DO_CM7" = "1" ]; then
    # If we just build a CM7 KANG then we will use that for the base on which
    # to build BlackICE on top of. Otherwise we use whatever was specified
    # for CM7_BASE_NAME.
    CM7_BASE_NAME=$CM7_NEW_ROM_BASE
  fi

  source ${SCRIPT_DIR}/build_blackice.sh

  RESULT="$?"
  if [ "$RESULT" != "0" ]; then
    echo "  ERROR running 'build_scripts/build_blackice.sh' = ${RESULT}"
    exit 1
  fi
fi


#
# Decide whether or not to push the result to the phone
#
if [ "$PUSH_TO_PHONE" = "yes" ] ; then
  if [ "$DO_BLACKICE" = "0" ] ; then
    banner "adb push ${CM7_NEW_ROM} /sdcard/"
    adb push ${CM7_NEW_ROM} /sdcard/
  else
    banner "adb push ${OUT_ZIP} /sdcard/"
    adb push ${OUT_ZIP} /sdcard/
  fi

  RESULT="$?"
  if [ "$RESULT" != "0" ]; then
    echo "  ERROR pushing ROM to phone (is the phone attached?) = ${RESULT}"
    exit 1
  fi
fi

banner "Freshly cooked bacon is ready!"

if [ "$DO_CM7" = "1" ]; then
  echo "  CM7:"
  echo "    ROM = ${CM7_NEW_ROM}"
  echo "    MD5 = ${CM7_NEW_ROM}.md5sum"
  echo ""
fi
if [ "$DO_BLACKICE" = "1" ]; then
  echo "  BlackICE:"
  echo "    ROM = ${OUT_ZIP}"
  echo "    MD5 = ${OUT_ZIP}.md5sum"
  echo ""

  if [ "$SIGN_ZIP" = "1" ]; then
    echo "  BlackICE Signed:"
    echo "    ROM = ${OUT_SIGNED}"
    echo "    MD5 = ${OUT_SIGNED}.md5sum"
    echo ""
  fi

  if [ "$EXTRA_APPS" = "1" ] ; then
    echo "  BlackICE Extra APPs:"
    echo "    ROM = ${OUT_EXTRAAPPS_ZIP}"
    echo "    MD5 = ${OUT_EXTRAAPPS_ZIP}.md5sum"
    echo ""

    if [ "$SIGN_ZIP" = "1" ]; then
      echo "  BlackICE Extra APPs Signed:"
      echo "    ROM = ${OUT_EXTRAPPS_SIGNED}"
      echo "    MD5 = ${OUT_EXTRAPPS_SIGNED}.md5sum"
      echo ""
    fi
  fi
fi

