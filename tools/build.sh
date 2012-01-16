#!/bin/bash

#
# BlackICE/tools/build.sh
#

#
# *** This script is assumed to be running in BlackICE/tools and although we try
# *** to be flexible some things have to make use of this assumption.
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
# See BlackICE/build_scripts/init.sh for command line argument information.
#

# *** TODO: Can this replace FixPath in util_sh?

# Returns the absolute path of the item which can be a file or directory
function GetAbsolutePath() {
  local ARG=$1
  local TEMP_BASE_NAME=`basename ${ARG}`
  local TEMP_DIR_NAME="$(cd "$(dirname "${ARG}")" && pwd)"

  if [ "$TEMP_BASE_NAME" != "." ]; then
    ARG=${TEMP_DIR_NAME}/${TEMP_BASE_NAME}
  else
    ARG=${TEMP_DIR_NAME}
  fi

  echo $ARG
}

# Returns the absolute directory for the given file
function GetAbsoluteDirOfFile() {
  local ARG=$1
  ARG="$(cd "$(dirname "${ARG}")" && pwd)"
  echo $ARG
}

#
# Helper function for displaying a banner to indicate which step in the build is
# currently being done. Note that we can not use this until util_sh is loaded,
# which defines ShowMessage.
#
function banner() {
  ShowMessage ""
  ShowMessage "*******************************************************************************"
  ShowMessage "  $@"
  ShowMessage "*******************************************************************************"
  ShowMessage ""
}


# This time is used for our log and our final ROM(s).
TIMESTAMP=`date +%Y%m%d_%H%M%S`

# Get the full path of the directory that the script is running in.
# This is expected to be the BlackICE/tools directory.
BUILD_DIR=`GetAbsoluteDirOfFile $0`

#
# By putting the log in our parent directory the assumption is that it is
# going into the the BlackICE directory.
# Note that until we successfully load util_sh we need to use 'echo' to write to
# the log. After util_sh is loaded we can use ShowMessage.
#
LOG=${BUILD_DIR}/../build-${TIMESTAMP}.log
export LOG

# Reset log
echo "" > $LOG
echo "Date    : $TIMESTAMP" >> $LOG
echo "Cmd Line: $@" >> $LOG


# Most of the included scripts are expected to be in BlackICE/build_scripts.
# An exception is util_sh, which is in the tools directory (in theory the
# directory we are running in now).
SCRIPT_DIR=${BUILD_DIR}/../build_scripts

source ${BUILD_DIR}/util_sh >> $LOG
RESULT="$?"
if [ "$RESULT" != "0" ] ; then
  echo "" | tee -a $LOG
  echo "  ERROR running 'util_sh' = ${RESULT}" | tee -a $LOG
  echo "" | tee -a $LOG
  exit 1
fi

#
# OK, now we can use ShowMessage to simplify writing to the log
#

# Process all the command line arguments before changing directory in case
# there are any relative paths.
source ${SCRIPT_DIR}/init.sh || ExitError "Running 'build_scripts/init.sh'"

if [ "$CLEAN_TYPE" = "cm7" ] || [ "$CLEAN_TYPE" = "all" ]; then
  cd $ANDROID_DIR

  banner "Cleaning CM7 (make clobber)"
  make clobber || ExitError "Doing CM7 clean, 'make clobber'"
fi

if [ "$CLEAN_TYPE" = "bi" ] || [ "$CLEAN_TYPE" = "all" ]; then
  banner "Cleaning BlackICE"

  # We don't provide any parameters, but build_blackice.sh will do a clean because
  # the variable CLEAN_ONLY is 1.
  source ${SCRIPT_DIR}/build_blackice.sh || ExitError "Doing BlackICE clean, 'build_scripts/build_blackice.sh'"
fi

if [ "$CLEAN_ONLY" = "1" ]; then
  exit 0
fi

#
# The default is to wait for user input so they can see the build information and
# decide whether or not to continute before doing something stupid. This can be
# overriden by specifying '-prompt 0' on the command line.
if [ "$PROMPT" = "yes" ]; then
  echo ""
  echo " --- The build will start in 10 seconds (press CTRL-C to abort) --- "

  for i in {10..1}
  do
    # -n = no newline
    # -e = interpret escape characters
    # \r = carriage return, but no newline
    echo -n -e "\r            $i  "
    sleep 1
  done
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
  repo sync -j16 >> $LOG  || ExitError "Running CM7 'repo sync'"
fi

# Do a BlackICE 'git pull' if requested
if [ "$DO_BLACKICE" = "1" ] && ([ "$SYNC_TYPE" = "bi" ] || [ "$SYNC_TYPE" = "all" ]); then
  banner "BlackICE git pull"
  cd ${BLACKICE_DIR}

  git pull || ExitError "Running BlackICE 'git pull'"
fi

#
# See if there are any GIT or DIFF patches to apply. We do not have to check
# FORCE_PATCHING here because that was used to determine whether or not to
# put patches on the ALL_PATCH_LIST. So if something is on the list we will do it.
#
if [ "$ALL_PATCH_LIST" != "" ]; then
  for PATCH_ITEM in $ALL_PATCH_LIST
  do
    PATCH_DIR=${PATCH_ITEM%%,*}
    PATCH_FILE=${PATCH_ITEM##*,}

    banner "Applying patch: ${PATCH_FILE}"
    if [ ! -d $PATCH_DIR ]; then
      ExitError "Patch file destination directory does not exist, '${PATCH_DIR}"
    fi

    # Change into the directory that the patch file needs to patch into.
    cd ${PATCH_DIR}

    if [ "${PATCH_FILE:(-4)}" = ".git" ]; then
      # .git patches are just like a shell script. Execute the patch.
      $PATCH_FILE || ExitError "Applying patch file '$PATCH_FILE'"
    else
      # .patch patches are diff files
      patch --no-backup-if-mismatch -p0 < ${PATCH_FILE} || ExitError "Applying patch file '$PATCH_FILE'"
    fi

    cd - &>/dev/null
  done
fi

#
# Now do the build(s)
#

if [ "$DO_CM7" = "1" ]; then
  source ${SCRIPT_DIR}/build_cm7.sh || ExitError "Running 'build_scripts/build_cm7.sh'"

  # If we are also building for BlackICE then we need to copy the CM7 result
  # over to the BlackICE directory so we can build on top of it.
  if [ "$DO_BLACKICE" = "1" ]; then
    banner "cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE}"
    cp ${CM7_NEW_ROM} ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE}
    ShowMessage ""
  fi
fi


if [ "$DO_BLACKICE" = "1" ]; then
  if [ "$DO_CM7" = "1" ]; then
    # If we just built a CM7 KANG then we will use that for the base on which
    # to build BlackICE on top of. Otherwise we use whatever was specified
    # for CM7_BASE_NAME.
    CM7_BASE_NAME=$CM7_NEW_ROM_BASE
  fi

  source ${SCRIPT_DIR}/build_blackice.sh || ExitError "Running 'build_scripts/build_blackice.sh'"
fi

#
# Copy results to Dropbox if requested
#
if [ "$DROPBOX_DIR" != "" ] ; then
  banner "Copying files to Dropbox folder"

  if [ "$DO_BLACKICE" = "1" ]; then
    ShowMessage "cp ${OUT_ZIP} ${DROPBOX_DIR}"
    cp ${OUT_ZIP} ${DROPBOX_DIR}

    if [ "$EXTRA_APPS" = "1" ] ; then
      ShowMessage "cp ${OUT_EXTRAAPPS_ZIP} ${DROPBOX_DIR}"
      cp ${OUT_EXTRAAPPS_ZIP} ${DROPBOX_DIR}
    fi

    if [ "$DO_CM7" = "1" ]; then
      ShowMessage "cp ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE} ${DROPBOX_DIR}"
      cp ${BLACKICE_DIR}/download/${CM7_NEW_ROM_BASE} ${DROPBOX_DIR}
    else
      ShowMessage "cp ${CM7_BASE_NAME} ${DROPBOX_DIR}"
      cp ${CM7_BASE_NAME} ${DROPBOX_DIR}
    fi
  else
    if [ "$DO_CM7" = "1" ]; then
      ShowMessage "cp ${CM7_NEW_ROM} ${DROPBOX_DIR}"
      cp ${CM7_NEW_ROM} ${DROPBOX_DIR}
    fi
  fi
fi

#
# Decide whether or not to push the result to the phone
#
if [ "$PUSH_TO_PHONE" = "yes" ] ; then
  if [ "$DO_BLACKICE" = "0" ] ; then
    banner "adb push ${CM7_NEW_ROM} /sdcard/"
    adb push ${CM7_NEW_ROM} /sdcard/ || ExitError "Pushing ROM to phone (is the phone attached?)"
  else
    banner "adb push ${OUT_ZIP} /sdcard/"
    adb push ${OUT_ZIP} /sdcard/ || ExitError "Pushing ROM to phone (is the phone attached?)"
  fi
fi

banner "Freshly cooked bacon is ready!"

if [ "$DO_CM7" = "1" ]; then
  ShowMessage "  CM7:"
  ShowMessage "    ROM = ${CM7_NEW_ROM}"
  ShowMessage "    MD5 = ${CM7_NEW_ROM}.md5sum"
  ShowMessage ""
fi
if [ "$DO_BLACKICE" = "1" ]; then
  ShowMessage "  BlackICE:"
  ShowMessage "    ROM = ${OUT_ZIP}"
  ShowMessage "    MD5 = ${OUT_ZIP}.md5sum"
  ShowMessage ""

  if [ "$SIGN_ZIP" = "1" ]; then
    ShowMessage "  BlackICE Signed:"
    ShowMessage "    ROM = ${OUT_SIGNED}"
    ShowMessage "    MD5 = ${OUT_SIGNED}.md5sum"
    ShowMessage ""
  fi

  if [ "$EXTRA_APPS" = "1" ] ; then
    ShowMessage "  BlackICE Extra APPs:"
    ShowMessage "    ROM = ${OUT_EXTRAAPPS_ZIP}"
    ShowMessage "    MD5 = ${OUT_EXTRAAPPS_ZIP}.md5sum"
    ShowMessage ""

    if [ "$SIGN_ZIP" = "1" ]; then
      ShowMessage "  BlackICE Extra APPs Signed:"
      ShowMessage "    ROM = ${OUT_EXTRAPPS_SIGNED}"
      ShowMessage "    MD5 = ${OUT_EXTRAPPS_SIGNED}.md5sum"
      ShowMessage ""
    fi
  fi
fi

