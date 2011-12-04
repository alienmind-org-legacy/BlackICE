#!/bin/bash

#
# bacon.sh
# Brian Larsen
# April 2011
#
# Script file for building ACE (DesireHD) firmware from a CyanogenMod code base that is already checked out.
# The result is either a Cyanogen or a BlackICE ROM depending on the specified arguments.
#
# The original purpose of the bacon.sh script was to do a "make bacon" command to build a CM7 (Cyanogen)
# KANG. It has evolved over time and can now also optionally invoke the BlackICE build script. The
# bacon.sh script assumes you already have the CM sources and have done an initial build, i.e.
# ". build/envsetup.sh && brunch ace".
#
#
# Command line arguments:
#   cm = build a Cyanogen ROM (default). You may also use CM or CYANOGEN
#   bi = build a BlackICE ROM. You may also use BI or BLACKICE
#        Building BlackICE first builds a Cyanogen ROM, which is copied to
#        the BlackICE directory. Then we invoke the normal BlackIce build.sh script.
#   k <kernel> = specifies the kernel name to use when building for BlackICE.
#                Instead of 'k' you may also use K or KERNEL.
#
#   s  = do a 'repo sync' before building (default). You may also use S or SYNC
#   ns = do NOT do a 'repo sync' before building. You may also use NS or NOSYNC
#
#   p  = push result to phone after building (default). You may also use P or PUSH
#   np = push result to phone after building. You may also use NP or NOPUSH
#
# Examples:
#   bacon.sh BI KERNEL lordmodUEv8.6-CFS-b5 NOSYNC
#     - This builds a BlackICE ROM using the 'lordmodUEv8.6-CFS-b5.zip' kernel and it does NOT
#       do a repo sync. The result is pushed to the phone.
#
#   bacon.sh CM NOPUSH
#     - This builds a Cyanogen ROM. It does a repo sync before building and it does NOT push
#       the result to the phone.
#
#
# Here are the main variables that the script uses, which you may wish to change:
#   $USER         = System variable: expected to be the user's name. If for some reason this is not
#                   set in your environment it will be set to 'chezbel'. You can change this to
#                   whatever you use on your system by either exporting this variable or by editing
#                   the bacon.sh script.
#
#   $HOME         = System variable: expected to be your home path on Linux. If for some reason this
#                   is not set in your environment it defaults to '/home/${USER}'. You can change
#                   this to whatever you use on your system by either exporting this variable or by
#                   editing the bacon.sh script.
#
#
#   $PHONE        = User defined variable to set to the desired phone. If not defined it will
#                   default to 'ace'. You can change this to whatever you use on your system by
#                   either exporting this variable or by editing the bacon.sh script.
#                   Note: this has only been tested for 'ace' so far.
#
#   $ANDROID_DIR  = User defined variable to set the android directory to initiate the build from.
#                   If not defined it will default to '${HOME}/android/system'. You can change this
#                   to whatever you use on your system by either exporting this variable or by
#                   editing the bacon.sh script.
#
#   $BLACKICE_DIR = User defined variable to set the ICEDroid directory. This is only important if
#                   you are building a BlackICE ROM. In that case the Cyanogen ROM that is built
#                   will be copied to $BLACKICE_DIR/download/. If not defined it will default to
#                   '${HOME}/android/blackice/ICEDroid'. You can change this to whatever you use
#                   on your system by either exporting this variable or by editing the bacon.sh script.
#

# Setup some build defaults and then update them based on the command line params
DO_SYNC="Yes"
DO_PUSH="Yes"
ROM_TYPE="Cyanogen"
KERNEL=""   # No default kernel name (only used for BlackICE builds)

# We use SHOW_HELP to decide if we need to display the usage information
SHOW_HELP=0

while [ $# -gt 0 ]; do
  SHOW_HELP=1

  if [ "$1" = "ns" ] || [ "$1" = "NS" ] || [ "$1" = "NOSYNC" ]; then
    DO_SYNC="No"
    SHOW_HELP=0
  fi
  if [ "$1" = "s" ] || [ "$1" = "S" ] || [ "$1" = "SYNC" ]; then
    DO_SYNC="Yes"
    SHOW_HELP=0
  fi

  if [ "$1" = "np" ] || [ "$1" = "NP" ] || [ "$1" = "NOPUSH" ]; then
    DO_PUSH="No"
    SHOW_HELP=0
  fi
  if [ "$1" = "p" ] || [ "$1" = "P" ] || [ "$1" = "PUSH" ]; then
    DO_PUSH="Yes"
    SHOW_HELP=0
  fi

  if [ "$1" = "bi" ] || [ "$1" = "BI" ] || [ "$1" = "BLACKICE" ]; then
    ROM_TYPE="BlackICE"
    SHOW_HELP=0
  fi
  if [ "$1" = "cm" ] || [ "$1" = "CM" ] || [ "$1" = "CYANOGEN" ]; then
    ROM_TYPE="Cyanogen"
    SHOW_HELP=0
  fi

  if [ "$1" = "k" ] || [ "$1" = "K" ] || [ "$1" = "KERNEL" ]; then
    if [ $# -gt 1 ]; then
      KERNEL=$2
      SHOW_HELP=0
      shift 1
    fi
  fi

  if [ "$SHOW_HELP" != "0" ]; then
    break
  fi

  shift 1
done

if [ "$ROM_TYPE" = "BlackICE" ] && [ "$KERNEL" = "" ]; then
  # For BlackICE we must indicate which Kernel we are going to use in the build
  SHOW_HELP=1
fi



if [ "$SHOW_HELP" = "1" ]; then
  echo ""
  echo "  Usage is $0 [params]"
  echo "    s  = do a 'repo sync' before building (default). You may also use S or SYNC"
  echo "    ns = do NOT do a 'repo sync' before building. You may also use NS or NOSYNC"
  echo ""
  echo "    p  = push result to phone after building (default). You may also use P or PUSH"
  echo "    np = push result to phone after building. You may also use NP or NOPUSH"
  echo ""
  echo "    cm = build a Cyanogen ROM (default). You may also use CM or CYANOGEN"
  echo "    bi = build a BlackICE ROM. You may also use BI or BLACKICE"
  echo "         Building BlackICE first builds a Cyanogen ROM, which is copied to the"
  echo "         BlackICE directory. Then we invoke the normal BlackIce build.sh script."
  echo ""
  echo "    k <kernel> = name of kernel to use. Required for BlackICE, ignored for Cyanogen"
  echo "                 Example:  K lordmodUEv8.6-CFS-b5.zip"
  echo "                 Instead of 'k' you can also use K or KERNEL"
  echo ""
  exit 1
fi

# $USER should be defined in your environment to use your user name
if [ "$USER" = "" ] ; then
  USER=chezbel
fi

# $HOME should be defined in your environment to point to your home path
if [ "$HOME" = "" ] ; then
  HOME=/home/${USER}
fi

# $PHONE does not normally exist, you can export it or change it here if you want something besides "ace"
if [ "$PHONE" = "" ] ; then
  PHONE=ace
fi

# $ANDROID_DIR does not normally exist, you can export it or change it here if you want something other than "$HOME/android/system"
if [ "$ANDROID_DIR" = "" ] ; then
  ANDROID_DIR=${HOME}/android/system
fi

# $BLACKICE_DIR does not normally exist, you can export it or change it here if you want something other than "${HOME}/android/blackice/ICEDroid"
if [ "$BLACKICE_DIR" = "" ] ; then
  BLACKICE_DIR=${HOME}/android/blackice/ICEDroid
fi

# The ROM we build will go here. Don't change this because it is where the
# Cyanogen makefile puts the new ROM, it needs to match.
ROM_DIR=${ANDROID_DIR}/out/target/product/${PHONE}

export PATH=./:${HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ANDROID_DIR}/out/host/linux-x86/bin
cd ${ANDROID_DIR}

if [ "$ROM_TYPE" = "BlackICE" ]; then
  if [ ! -f ${BLACKICE_DIR}/download/${KERNEL} ]; then
    if [ -f ${BLACKICE_DIR}/download/${KERNEL}.zip ]; then
      KERNEL=${KERNEL}.zip
    else
      echo ""
      echo "  ERROR: BlackICE kernel does not exist: ${BLACKICE_DIR}/download/${KERNEL}"
      echo ""
      exit 1
    fi
  fi
fi

echo ""
echo "Build information"
echo "  User           = $USER"
echo "  Phone          = $PHONE"
echo "  Home dir       = $HOME"
echo "  Android dir    = $ANDROID_DIR"
echo "  ROM Type       = $ROM_TYPE"

if [ "$ROM_TYPE" = "BlackICE" ]; then
  echo "  Kernel         = $KERNEL"
  echo "  BlackICE dir   = $BLACKICE_DIR"
fi

echo ""
echo "  Repo Sync      = $DO_SYNC"
echo "  Push to phone  = $DO_PUSH"
echo ""

# Set up the environment for doing a Cyanogen build. We need to do a 'source' here
# so that the environment variables are available for the following steps to access.
source build/envsetup.sh
RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR sourcing build/envsetup.sh = ${RESULT}"
  echo ""
  exit 1
fi

# We need to choose the target we are building for.
breakfast ${PHONE}
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR running 'breakfast ${PHONE}' = ${RESULT}"
  echo ""
  exit 1
fi

# Decide whether or not to run repo sync
if [ "$DO_SYNC" = "Yes" ] ; then
  repo sync -j16

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running repo sync = ${RESULT}"
    echo ""
    exit 1
  fi

fi

# Making the bacon is the main build. The -j6 needs to match the system
# that is being used to do the build.
NUM_CPUS=`grep -c processor /proc/cpuinfo`
make bacon -j $NUM_CPUS

RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR running make bacon = ${RESULT}"
  echo ""
  exit 1
fi

#
# Let's rename the ROM from its default name to something that we can identify
# that includes a data tag and clean up any old files that might be lying around.
#
ROM_DATE=`date +%Y%m%d_%H%M%S`

# OLD_ROM is what the Cyanogen makefile produces
OLD_ROM=${ROM_DIR}/update-cm-7*DesireHD-KANG-signed.zip

# New ROM is what we rename it to, just because
# We also need the base name, mainly if building for BlackICE
NEW_ROM_BASE=${USER}-cm7-${ROM_DATE}.zip
NEW_ROM=${ROM_DIR}/${NEW_ROM_BASE}

rm -f ${ROM_DIR}/${USER}-cm7*.zip
rm -f ${ROM_DIR}/${USER}-cm7*.zip.md5sum
rm -f ${ROM_DIR}/cyanogen_${PHONE}-ota-eng*.zip

mv $OLD_ROM $NEW_ROM
mv $OLD_ROM.md5sum $NEW_ROM.md5sum

if [ ! -e $NEW_ROM ] ; then
  echo ""
  echo "  ERROR creating ${NEW_ROM}"
  echo ""
  exit 1
fi

if [ ! -e $NEW_ROM.md5sum ] ; then
  echo ""
  echo "  ERROR creating ${NEW_ROM.md5sum}"
  echo ""
  exit 1
fi

echo ""
echo "New ROM = ${NEW_ROM}"
echo "New md5 = ${NEW_ROM}.md5sum"
echo ""

# Decide whether or not to build BlackICE
if [ "$ROM_TYPE" = "BlackICE" ] ; then
  echo ""
  echo "cp ${NEW_ROM} ${BLACKICE_DIR}/download"
  cp ${NEW_ROM} ${BLACKICE_DIR}/download
  echo ""

  # Export our rom date so that the BlackICE build will use it for its timestamp.
  # This allows us to know what the resulting BlackICE ROM name will be.
  export TIMESTAMP=$ROM_DATE
  cd $BLACKICE_DIR

  # We invoke this using "." so that we can access the $OUT_ZIP variable
  # afterwards in order to know what ROM to push onto the phone (if requested).
  echo ""
  echo ". tools/build.sh download/${NEW_ROM_BASE} download/${KERNEL}"
  echo ""
  . tools/build.sh download/${NEW_ROM_BASE} download/${KERNEL}

  RESULT="$?"
  if [ "$RESULT" != "0" ]; then
    echo "  ERROR running ${BLACKICE_DIR}/tools/build.sh = ${RESULT}"
    exit 1
  fi
fi

# Decide whether or not to push the result to the phone
if [ "$DO_PUSH" = "Yes" ] ; then
  if [ "$ROM_TYPE" = "Cyanogen" ] ; then
    echo ""
    echo "adb push ${NEW_ROM} /sdcard/"
    adb push ${NEW_ROM} /sdcard/
    echo ""
  else
    echo ""
    echo "adb push ${OUT_ZIP} /sdcard/"
    adb push ${OUT_ZIP} /sdcard/
    echo ""
  fi
fi

echo ""
echo "Bacon is cooked"
echo ""
