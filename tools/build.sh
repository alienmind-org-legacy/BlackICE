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


# Get the UTC time in 2 formats
#  - UTC_DATE_STRING is a human readable string for display purposes
#  - UTC_DATE_FILE is the *same* date, but suitable for including in file names
UTC_DATE_STRING=`date -u`
UTC_DATE_FILE=`date -u --date="${UTC_DATE_STRING}" +%Y.%m.%d_%H.%M.%S_%Z`

# Get the full path of the directory that the script is running in.
# This is expected to be the BlackICE/tools directory.
BUILD_DIR=`GetAbsoluteDirOfFile $0`

#
# By putting the log in our parent directory the assumption is that it is
# going into the the BlackICE directory.
# Note that until we successfully load util_sh we need to use 'echo' to write to
# the log. After util_sh is loaded we can use ShowMessage.
#
LOG=${BUILD_DIR}/../build-${UTC_DATE_FILE}.log
export LOG

# Reset log
echo "" > $LOG
echo "Date    : $UTC_DATE_STRING" >> $LOG
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

if [ "$CLEAN_TYPE" = "cm7" ] || [ "$CLEAN_TYPE" = "cm7bi" ]; then
  cd $CM7_DIR

  banner "Cleaning CM7 (make clobber)"
  make clobber || ExitError "Doing CM7 clean, 'make clobber'"
fi

if [ "$CLEAN_TYPE" = "cm9" ] || [ "$CLEAN_TYPE" = "cm9bi" ]; then
  cd $CM9_DIR

  banner "Cleaning CM9 (make clobber)"
  make clobber || ExitError "Doing CM9 clean, 'make clobber'"
fi

if [ "$CLEAN_TYPE" = "bi" ] || [ "$CLEAN_TYPE" = "cm7bi" ] || [ "$CLEAN_TYPE" = "cm9bi" ]; then
  banner "Cleaning BlackICE"

  # We don't provide any parameters, but build_blackice.sh will do a clean because
  # the variable CLEAN_ONLY is 1.
  source ${SCRIPT_DIR}/build_blackice.sh || ExitError "Doing BlackICE clean, 'build_scripts/build_blackice.sh'"
fi

if [ "$CLEAN_ONLY" = "1" ]; then
  exit 0
fi

# Someday, we *might* support this...
if [ "$ROM_TYPE" = "cm9bi" ]; then
  ExitError "Building BlackICE on top of CM9 (ICS) is not supported yet!"
fi

#
# PROMPT determines how long we wait before doing the build. This allows the user
# to have a chance to press CTRL-C if they did something stupid.
if [ $PROMPT -eq 999 ]; then
  # The special prompt value of 999 does not actually let anything get built.
  # It's like an infinite delay.
  exit 0
fi

if [ $PROMPT -gt 0 ]; then
  echo ""
  echo " --- The build will start in ${PROMPT} seconds (press CTRL-C to abort) --- "

  DELAY=$PROMPT
  while [ $DELAY -gt 0 ]
  do
    # -n = no newline
    # -e = interpret escape characters
    # \r = carriage return, but no newline
    echo -n -e "\r            $DELAY  "
    sleep 1
    (( DELAY-- ))
  done
fi

#
# We do all the syncing first so that any error due to syncing is detected before
# spending a long time building. Also in case there are any patches to apply we
# can do all of them before building.
#

# Do a CM7 'repo sync' if requested
if [ "$DO_CM7" = "1" ] && ([ "$SYNC_TYPE" = "cm7" ] || [ "$SYNC_TYPE" = "cm7bi" ]); then
  banner "CM7 repo sync -j16"
  cd ${CM7_DIR}
  repo sync -j16 >> $LOG  || ExitError "Running CM7 'repo sync'"
fi

# Do a CM9 'repo sync' if requested
if [ "$DO_CM9" = "1" ] && ([ "$SYNC_TYPE" = "cm9" ] || [ "$SYNC_TYPE" = "cm9bi" ]); then
  banner "CM9 repo sync -j16"
  cd ${CM9_DIR}
  repo sync -j16 >> $LOG  || ExitError "Running CM9 'repo sync'"
fi

# Do a BlackICE 'git pull' if requested
if [ "$DO_BLACKICE" = "1" ] && ([ "$SYNC_TYPE" = "bi" ] || [ "$SYNC_TYPE" = "cm7bi" ] || [ "$SYNC_TYPE" = "cm9bi" ]); then
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
      ShowMessage `cat $PATCH_FILE`
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
if [ "$DO_CM7" = "1" ] || [ "$DO_CM9" = "1" ]; then
  if [ "$DO_CM7" = "1" ]; then
    source ${SCRIPT_DIR}/build_cm7.sh || ExitError "Running 'build_scripts/build_cm7.sh'"
  else
    source ${SCRIPT_DIR}/build_cm9.sh || ExitError "Running 'build_scripts/build_cm9.sh'"
  fi

  # If we are also building for BlackICE then we need to copy the CM7/CM9 result
  # over to the BlackICE directory so we can build on top of it.
  if [ "$DO_BLACKICE" = "1" ]; then
    banner "cp ${CM_NEW_ROM} ${BLACKICE_DIR}/download/${CM_NEW_ROM_BASE}"
    cp ${CM_NEW_ROM} ${BLACKICE_DIR}/download/${CM_NEW_ROM_BASE}
    ShowMessage ""

    # Use the name of the CM7/CM9 KANG that we just built to build BlackICE on top of.
    CM79_BASE_NAME=$CM_NEW_ROM_BASE
  fi
fi

if [ "$DO_BLACKICE" = "1" ]; then
  source ${SCRIPT_DIR}/build_blackice.sh || ExitError "Running 'build_scripts/build_blackice.sh'"
fi

#
# Copy results to Dropbox if requested
#
if [ "$DROPBOX_DIR" != "" ] ; then
  banner "Copying files to Dropbox folder"

  if [ "$DO_BLACKICE" = "1" ]; then
    ShowMessage "cp ${RELEASE_ZIP} ${DROPBOX_DIR}"
    cp ${RELEASE_ZIP} ${DROPBOX_DIR}

    if [ "$EXTRA_APPS" = "1" ] ; then
      ShowMessage "cp ${RELEASE_EXTRAAPPS_ZIP} ${DROPBOX_DIR}"
      cp ${RELEASE_EXTRAAPPS_ZIP} ${DROPBOX_DIR}
    fi

    if [ "$DO_CM7" = "1" ] || [ "$DO_CM9" = "1" ]; then
      ShowMessage "cp ${BLACKICE_DIR}/download/${CM_NEW_ROM_BASE} ${DROPBOX_DIR}"
      cp ${BLACKICE_DIR}/download/${CM_NEW_ROM_BASE} ${DROPBOX_DIR}
    else
      ShowMessage "cp ${CM79_BASE_NAME} ${DROPBOX_DIR}"
      cp ${CM79_BASE_NAME} ${DROPBOX_DIR}
    fi
  else
    if [ "$DO_CM7" = "1" ] || [ "$DO_CM9" = "1" ]; then
      ShowMessage "cp ${CM_NEW_ROM} ${DROPBOX_DIR}"
      cp ${CM_NEW_ROM} ${DROPBOX_DIR}
    fi
  fi
fi

#
# If we are building for BlackICE we do a few things to make doing a release easier:
#  - copy the CM7 result or base Kand into the release directory
#  - perform an md5sum of all the .zip files
#  - process the md5sum output to remove the path name of each file (we just want
#    the sum and the base filename).
#  - create the skeleton change log file in the release directory (probably needs
#    manual editing, but the tedious stuff is done automatically).
#
if [ "$DO_BLACKICE" = "1" ]; then

  # First we copy the CM7/CM9 Kang into the release directory. If we built this as
  # part of this release then it is sitting in the CM7/CM9 out directory. If we used
  # an existing Kang (-cm7base xxx) then we are copying that one. In either case
  # CM79_BASE_NAME points to the correct file.
  cp ${CM79_BASE_NAME} ${RELEASE_DIR}

  # Create and write to changes.txt...
  CHANGES_FILE=${RELEASE_DIR}/changes.txt

  # Get the BlackICE version number without the leading 'BlackICE.'
  THE_TEMP=${BLACKICE_VERSION}
  THE_TEMP=${THE_TEMP#BlackICE.}
  echo "-------------------------------------------------------------------------------" >> ${CHANGES_FILE}
  echo "${THE_TEMP}" >> ${CHANGES_FILE}
  echo "-------------------------------------------------------------------------------" >> ${CHANGES_FILE}

  THE_TEMP=`basename ${RELEASE_ZIP}`
  echo " - BlackICE KANG  : ${THE_TEMP}" >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}

  THE_TEMP=`basename ${KERNELFILE}`
  echo " - Kernel         : ${THE_TEMP}" >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}

  THE_TEMP=`basename ${CM79_BASE_NAME}`
  echo " - CM7 Base KANG  : ${THE_TEMP}" >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}
  echo " - Main changes   : " >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}
  echo " - CM7 changes    : " >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}
  echo " - Miscellaneous  : " >> ${CHANGES_FILE}
  echo "" >> ${CHANGES_FILE}

  # Now create the md5sums for all the .zip files with one command and send the
  # output to md5sums.txt. We change into the directory where the .zip files are
  # located so that the file names that md5sum emits are just the base name
  # without any path.
  #
  cd ${RELEASE_DIR}
  md5sum -b *.zip > md5sums.txt
  cd - &>/dev/null
fi

#
# Decide whether or not to push the result to the phone
#
if [ "$PUSH_TO_PHONE" = "yes" ] ; then
  if [ "$DO_BLACKICE" = "0" ] ; then
    banner "adb push ${CM_NEW_ROM} /sdcard/"
    adb push ${CM_NEW_ROM} /sdcard/ || ExitError "Pushing ROM to phone (is the phone attached?)"
  else
    banner "adb push ${RELEASE_ZIP} /sdcard/"
    adb push ${RELEASE_ZIP} /sdcard/ || ExitError "Pushing ROM to phone (is the phone attached?)"
  fi
fi

banner "Freshly cooked bacon is ready!"

if ([ "$DO_CM7" = "1" ] || [ "$DO_CM9" = "1" ]) && [ "$DO_BLACKICE" = "0" ]; then
  if [ "$DO_CM7" = "1" ]; then
    ShowMessage "  CM7:"
  else
    ShowMessage "  CM9 (ICS):"
  fi

  ShowMessage "    ROM = ${CM_NEW_ROM}"
  ShowMessage "    MD5 = ${CM_NEW_ROM}.md5sum"
  ShowMessage ""
fi

if [ "$DO_BLACKICE" = "1" ]; then
  ShowMessage "  Final files for this build are in"
  ShowMessage "    ${RELEASE_DIR}"
  ShowMessage ""
fi

