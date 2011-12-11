#!/bin/bash

#
# bacon.sh
#
# Apr 2011 - Initial version for building CM7 KANGs.
#
# Dec 2011 - Reworked to allow optionally building BlackICE KANGs.
#          - Cleaned up script variables and command line argument processing.
#

#
# This script file builds a KANGed ROM from CyanogenMod (CM7) sources, which you
# must have already checked out and done an initial build for, i.e.
#   . build/envsetup.sh && brunch ace
#
# If you don't know how to get or setup the CM7 sources then here is one link that
# may help you get started
#   http://wiki.cyanogenmod.com/index.php?title=Compile_CyanogenMod_for_Ace
#
# Note that "ace" is referenced above, which is the codename for the Desire HD.
# Although this script *might* work for other phones it has only been tested for
# ACE builds.
#
# As an option, this script can call the BlackICE script build.sh to reprocess the
# CM7 KANG in order to create a BlackICE version.
#

#
# Misc variables for this script are given default values in bacon.ini, which must
# either exist in your path or in ./conf (when packaged with ICEDroid the script
# will be in the ./conf directory). You can modify the variables in bacon.ini in
# order to suit your needs, but you do so at your own risk.
#

#
# Command line arguments (see bacon.ini for more details):
#
#  -ch, -check
#     Doesn't take an argument. Just checks all the parameters and displays what
#     would have been built, but does not build anything. You may combine this
#     with any of the other command line arguments.
#
#  -bi, -blackice
#     0 = CM7 build, 1 = BlackICE build
#     Affects the variable ADD_BLACKICE
#
#  -cs, -csync
#     0 = no CM7 'repo sync', 1 = do CM7 'repo sync'
#     Affects the variable DO_CM7_SYNC
#
#  -bs, -bsync
#     0 = no BlackICE 'git pull', 1 = do BlackICE 'git pull'
#     Affects the variable DO_BLACKICE_SYNC
#
#  -pu, -push
#     0 = do not 'adb push' KANG to phone, 1 = 'adb push' KANG to phone
#     Affects the variable PUSH_TO_PHONE
#
#  -ph, -phone
#     Name of phone to build for, WARNING only tested with 'ace'
#     Affects the variable PHONE
#
#  -adir
#     Full path to root of where Android (CM7) source is located
#     Affects the variable ANDROID_DIR
#
#  -bdir
#     Full path to the BlackICE's 'ICEDroid' directory
#     Affects the variable BLACKICE_DIR
#
#  -bk, -bkernel
#     Name of kernel file to build into BlackICE
#     Affects the variable BLACKICE_KERNEL_NAME
#
#  -bg, -bgps
#     Name of GPS region to build into BlackICE. If this is set to the special
#     value of "" then it the BlackICE build.sh script will use its normal
#     default of system/etc/gps.conf (from ICEDroid).
#     Affects the variable BLACKICE_GPS_NAME
#
#  -br, -bril
#     Name of RIL to build into BlackICE. If this is set to the special value
#     of "" then it the BlackICE build.sh script will use its normal CM7 default
#     RIL that is part of ICEDroid.
#     Affects the variable BLACKICE_RIL_NAME
#
# Examples:
#   bacon.sh -check
#     - Display what would normal be built without actually building anything.
#
#   bacon.sh -bi 0 -csync 0 -push 1
#     - Builds a CM7 KANG without first doing a repo sync. The result is pushed to the phone.
#
#   bacon.sh -bi 1 -bk lordmodUEv8.6-CFS-b5 -bg QATAR -br 2.2.1003G -bsync 1
#     - Builds a BlackICE KANG using the following
#       - Kernel = lordmodUEv8.6-CFS-b5 (this .zip must be in the ICEDroid/download directory)
#       - GPS    = QATAR
#       - RIL    = HTC-RIL_2.2.1003G
#       - Does a 'repo sync' of CM7 first (assuming the bacon.ini defaults haven't changed)
#       - Does a 'git pull' of BlackICE before building.
#       - Pushes the result to the phone (assuming the bacon.ini defaults haven't changed)
#

#
# Helper function to return a 'Yes' or 'No' string based on the value of the
# given argument.
#
function yesNo() {
  YN_STRING=No
  if [ "$1" = "1" ]; then
    YN_STRING=Yes
  fi

  echo $YN_STRING
}

#
# Helper function for displaying a banner to indicate which step in the build is
# currently being done.
#
function banner() {
  echo ""
  echo "*******************************************************************************"
  echo "  Performing: $1"
  echo "*******************************************************************************"
  echo ""
}


if [ "$USER" = "" ] || [ "$HOME" = "" ] ; then
  echo ""
  echo "$0: The Linux environment variables USER and HOME must be defined!"
  echo ""
  exit 1
fi

#
# Load bacon.ini and try to be a bit flexible in finding it...
# This will initialize some variables to default values.
#
BACON_DIR=`dirname $0`
if [ -f bacon.ini ]; then
  source bacon.ini
else
  if [ -f ./conf/bacon.ini ]; then
    source ./conf/bacon.ini
  else
    if [ -f ${BACON_DIR}/bacon.ini ]; then
      source ${BACON_DIR}/bacon.ini
    else
      echo ""
      echo "$0: Unable to find bacon.ini in PATH, ./conf or ${BACON_DIR}/"
      echo ""
      exit 1
    fi
  fi
fi

# If the -check command line option is given we only check everything and display
# what would normally be built, but we quit without building anything.
CHECK_ONLY=0

# SHOW_HELP will let us decide if we need to display the usage information
SHOW_HELP=0

# Debug helpers to show which .ini items have been overridden.
# " " = normal, "*" = overridden.
BI_OVER=" "
BS_OVER=" "
CS_OVER=" "
PU_OVER=" "
PH_OVER=" "
AD_OVER=" "
BD_OVER=" "
BK_OVER=" "
BG_OVER=" "
BR_OVER=" "

while [ $# -gt 0 ]; do
  # We need to set this to 1 every time in order to detect a bad option.
  SHOW_HELP=1

  if [ "$1" = "-h" ] || [ "$1" = "-?" ]; then
    break;
  fi

  if [ "$1" = "-ch" ] || [ "$1" = "-check" ]; then
    # We aren't going to actually do the build
    CHECK_ONLY=1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bi" ] || [ "$1" = "-blackice" ]; then
    shift 1
    ADD_BLACKICE=$1
    BI_OVER="*"

    if [ "$ADD_BLACKICE" != "0" ] && [ "$ADD_BLACKICE" != "1" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-cs" ] || [ "$1" = "-csync" ]; then
    shift 1
    DO_CM7_SYNC=$1
    CS_OVER="*"

    if [ "$DO_CM7_SYNC" != "0" ] && [ "$DO_CM7_SYNC" != "1" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-bs" ] || [ "$1" = "-bsync" ]; then
    shift 1
    DO_BLACKICE_SYNC=$1
    BS_OVER="*"

    if [ "$DO_BLACKICE_SYNC" != "0" ] && [ "$DO_BLACKICE_SYNC" != "1" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-pu" ] || [ "$1" = "-push" ]; then
    shift 1
    PUSH_TO_PHONE=$1
    PU_OVER="*"

    if [ "$PUSH_TO_PHONE" != "0" ] && [ "$PUSH_TO_PHONE" != "1" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-ph" ] || [ "$1" = "-phone" ]; then
    shift 1
    PHONE=$1
    PH_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a phone name.
    ARG_TEMP=${PHONE:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-adir" ]; then
    shift 1
    ANDROID_DIR=$1
    AD_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a directory name.
    ARG_TEMP=${ANDROID_DIR:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-bdir" ]; then
    shift 1
    BLACKICE_DIR=$1
    BD_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a directory name.
    ARG_TEMP=${BLACKICE_DIR:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-bk" ] || [ "$1" = "-bkernel" ]; then
    shift 1
    BLACKICE_KERNEL_NAME=$1
    BK_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a directory name.
    ARG_TEMP=${BLACKICE_KERNEL_NAME:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-bg" ] || [ "$1" = "-bgps" ]; then
    shift 1
    BLACKICE_GPS_NAME=$1
    BG_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a directory name.
    ARG_TEMP=${BLACKICE_GPS_NAME:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$1" = "-br" ] || [ "$1" = "-bril" ]; then
    shift 1
    BLACKICE_RIL_NAME=$1
    BR_OVER="*"

    # Check for leading "-", which indicates we got another command line option
    # instead of a directory name.
    ARG_TEMP=${BLACKICE_RIL_NAME:0:1}
    if [ "$ARG_TEMP" = "-" ]; then
      break
    fi

    SHOW_HELP=0
  fi

  if [ "$SHOW_HELP" = "1" ]; then
    break
  fi

  shift 1
done


if [ "$SHOW_HELP" = "1" ]; then
  echo ""
  echo "  Usage is $0 [params]"
  echo "    -bi, -blackice"
  echo "       0 = CM7 build, 1 = BlackICE build"
  echo "    -csync"
  echo "       0 = no CM7 'repo sync', 1 = do CM7 'repo sync'"
  echo "    -bsync"
  echo "       0 = no BlackICE 'git pull', 1 = do BlackICE 'git pull'"
  echo "    -pu, -push"
  echo "       0 = do not 'adb push' KANG to phone, 1 = 'adb push' KANG to phone"
  echo "    -ph, -phone"
  echo "       Name of phone to build for, WARNING only tested with 'ace'"
  echo "    -adir"
  echo "       Full path to root of where Android (CM7) source is located"
  echo "    -bdir"
  echo "       Full path to the BlackICE's 'ICEDroid' directory "
  echo "    -bk, -bkernel"
  echo "       Name of kernel file to build into BlackICE"
  echo "    -bg, -bgps"
  echo "       Name of GPS region to build into BlackICE, can be \"\""
  echo "    -br, -bril"
  echo "       Name of RIL to build into BlackICE, can be \"\""
  echo ""
  echo "  For more details look in bacon.ini"
  echo ""
  exit 1
fi

#
# If some tools can't be found you may need to include on or more of these directories in your path.
#
# #export PATH=./:${HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ANDROID_DIR}/out/host/linux-x86/bin
#

#
# These are here instead of in bacon.ini because the command line might change
# them. These shouldn't be modified unless the structure of ICEDroid changes.
#
BLACKICE_KERNEL_FILE=${BLACKICE_DIR}/download/${BLACKICE_KERNEL_NAME}
BLACKICE_GPS_FILE=${BLACKICE_DIR}/sdcard/blackice/gpsconf/${BLACKICE_GPS_NAME}/gps.conf
BLACKICE_RIL_FILE=${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_${BLACKICE_RIL_NAME}


# The ROM we build will go here. Don't change this because it is where the
# Cyanogen makefile puts the new ROM, it needs to match.
CM7_ROM_DIR=${ANDROID_DIR}/out/target/product/${PHONE}

cd $ANDROID_DIR

if [ "$ADD_BLACKICE" = "1" ]; then
  if [ ! -f $BLACKICE_KERNEL_FILE ]; then
    if [ -f ${BLACKICE_KERNEL_FILE}.zip ]; then
      BLACKICE_KERNEL_FILE=${BLACKICE_KERNEL_FILE}.zip
    else
      echo ""
      echo "  ERROR: BlackICE kernel does not exist: ${BLACKICE_KERNEL_FILE}"
      echo ""
      exit 1
    fi
  fi

  # BLACKICE_GPS_NAME is allowed to be empty in order to use the default ICEDroid
  # GPS info in the build
  if [ "$BLACKICE_GPS_NAME" = "" ]; then
    BLACKICE_GPS_FILE="<<ICEDroid Default>>"
  else
    if [ ! -f ${BLACKICE_GPS_FILE} ]; then
      echo ""
      echo "  ERROR: BlackICE gps.conf does not exist: ${BLACKICE_GPS_FILE}"
      echo ""
      exit 1
    fi
  fi

  # BLACKICE_RIL_NAME is allowed to be empty in order to use the default ICEDroid
  # RIL in the build
  if [ "$BLACKICE_RIL_NAME" = "" ]; then
    BLACKICE_RIL_FILE="<<ICEDroid Default>>"
  else
    if [ ! -d ${BLACKICE_RIL_FILE} ]; then
      echo ""
      echo "  ERROR: BlackICE ril directory does not exist: ${BLACKICE_RIL_FILE}"
      echo ""
      exit 1
    fi
  fi
fi

echo ""
echo "Build information ('*' = changed by command line option)"
echo "   User          = $USER"
echo "  ${PH_OVER}Phone         = $PHONE"
echo "   Home dir      = $HOME"
echo "  ${AD_OVER}Android dir   = $ANDROID_DIR"

if [ "$ADD_BLACKICE" = "1" ]; then
  echo "  ${BI_OVER}ROM Type      = BlackICE"
  echo "  ${BD_OVER}BlackICE dir  = $BLACKICE_DIR"
  echo "  ${BK_OVER}Kernel        = $BLACKICE_KERNEL_NAME  [$BLACKICE_KERNEL_FILE]"
  echo "  ${BG_OVER}GPS region    = $BLACKICE_GPS_NAME  [$BLACKICE_GPS_FILE]"
  echo "  ${BR_OVER}RIL           = $BLACKICE_RIL_NAME  [$BLACKICE_RIL_FILE]"
else
  echo "  ${BI_OVER}ROM Type      = CM7"
fi

echo ""
echo "  ${CS_OVER}CM7 Repo Sync = "`yesNo $DO_CM7_SYNC`
echo "  ${BS_OVER}BI Git Pull   = "`yesNo $DO_BLACKICE_SYNC`
echo "  ${PU_OVER}Push to phone = "`yesNo $PUSH_TO_PHONE`
echo ""

if [ "$CHECK_ONLY" != "0" ]; then
  # Quit without building anything.
  exit 1
fi

# Delay so we have time to read the build information!
sleep 5

# Set up the environment for doing a Cyanogen build. We need to do a 'source' here
# so that the environment variables are available for the following steps to access.
banner "source build/envsetup.sh"
source build/envsetup.sh
RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR sourcing build/envsetup.sh = ${RESULT}"
  echo ""
  exit 1
fi

# We need to choose the target we are building for.
banner "breakfast ${PHONE}"
breakfast ${PHONE}
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR running 'breakfast ${PHONE}' = ${RESULT}"
  echo ""
  exit 1
fi

# Do a CM7 'repo sync' if requested
if [ "$DO_CM7_SYNC" = "1" ] ; then
  banner "CM7 repo sync -j16"
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
# We do this now so we don't have to wait for the entire CM7 build to finsih
# before finding out if we have a BlackICE sync error.
if [ "$ADD_BLACKICE" = "1" ] && [ "$DO_BLACKICE_SYNC" = "1" ] ; then
  banner "BlackICE git pull"
  cd $BLACKICE_DIR

  git pull

  RESULT="$?"
  if [ "$RESULT" != "0" ] ; then
    echo ""
    echo "  ERROR running BlackICE 'git pull' = ${RESULT}"
    echo ""
    exit 1
  fi

  # Change back to where we were previously
  cd $ANDROID_DIR
fi

# Making the bacon is the main build. The -j6 needs to match the system
# that is being used to do the build.
NUM_CPUS=`grep -c processor /proc/cpuinfo`
banner "make bacon -j ${NUM_CPUS}"
make bacon -j ${NUM_CPUS}

RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo ""
  echo "  ERROR running 'make bacon' = ${RESULT}"
  echo ""
  exit 1
fi

#
# Let's rename the ROM from its default name to something that we can identify
# that includes a data tag and clean up any old files that might be lying around.
#
CM7_ROM_DATE=`date +%Y%m%d_%H%M%S`

# CM7_OLD_ROM is what the Cyanogen makefile produces
CM7_OLD_ROM=${CM7_ROM_DIR}/update-cm-7*DesireHD-KANG-signed.zip

# New ROM is what we rename it to, just because
# We also need the base name, mainly if building for BlackICE
CM7_NEW_ROM_BASE=${USER}-cm7-${CM7_ROM_DATE}.zip
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
  exit 1
fi

if [ ! -e ${CM7_NEW_ROM}.md5sum ] ; then
  echo ""
  echo "  ERROR creating ${CM7_NEW_ROM}.md5sum"
  echo ""
  exit 1
fi

echo ""
echo "New ROM = ${CM7_NEW_ROM}"
echo "New md5 = ${CM7_NEW_ROM}.md5sum"
echo ""

# Decide whether or not to build BlackICE
if [ "$ADD_BLACKICE" = "1" ] ; then
  echo ""
  echo "cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download"
  cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download
  echo ""

  # Export our rom date so that the BlackICE build will use it for its timestamp.
  # This allows us to know what the resulting BlackICE ROM name will be.
  export TIMESTAMP=$CM7_ROM_DATE
  cd $BLACKICE_DIR

  # We invoke this using "source" so that we can access the $OUT_ZIP variable
  # afterwards in order to know what ROM to push onto the phone (if requested).
  banner "source tools/build.sh download/${CM7_NEW_ROM_BASE} download/${BLACKICE_KERNEL_NAME} ${BLACKICE_GPS_NAME} ${BLACKICE_RIL_NAME}"
  source tools/build.sh download/${CM7_NEW_ROM_BASE} download/${BLACKICE_KERNEL_NAME} ${BLACKICE_GPS_NAME} ${BLACKICE_RIL_NAME}

  RESULT="$?"
  if [ "$RESULT" != "0" ]; then
    echo "  ERROR running ${BLACKICE_DIR}/tools/build.sh = ${RESULT}"
    exit 1
  fi
fi

# Decide whether or not to push the result to the phone
if [ "$PUSH_TO_PHONE" = "1" ] ; then
  if [ "$ADD_BLACKICE" = "0" ] ; then
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

echo ""
echo " *** Freshly cooked bacon is ready!"
echo ""
