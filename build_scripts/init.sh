#!/bin/bash

#
# init.sh
#

#
# Command line arguments:
#
#  -ini <ini_file>
#     Specifies the .ini file to load, which defines the script variables needed.
#     It's a good idea to specify this so you don't have to enter a LOT of options
#     on the command line!
#
#  -check
#     Checks all the parameters and displays what would have been built, but does
#     not build anything. You may combine this with any of the other command line
#     arguments. This lets you safely check what would happen with various options.
#
#  -clean {cm7, bi, all, ""}
#     cm7 = do a CM7 'make clobber'
#     bi  = do a BI 'make clean'
#     all = do both of the above
#     ""  = do not clean anything (do a normal build)
#     If any clean is specified then nothing will be built and most other arguments
#     will be ignored.
#     Affects the variable CLEAN_TYPE
#
#  -verbose {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
#     0    = extra quite build messages (may not be implemented).
#     1    = normal build messages.
#     2    = additional build messages.
#     3..9 = even more build messages (may not be implemented yet)
#     Affects the variable VERBOSE
#
#  -rom {cm7, bi, all}
#     cm7  = only build a CM7 ROM.
#     bi   = only build a BlackICE ROM (requires CM7_BASE_NAME to be set).
#     all  = build a CM7 ROM and then a BlackICE ROM from that base.
#     Affects the variable ROM_TYPE
#
#  -sync {cm7, bi, all, ""}
#     cm7 = sync the CM7 sources, 'repo sync', before building.
#     bi  = sync the BlackICE clone, 'git pull', before building.
#     all = sync both CM7 and BlackICE before building.
#     ""  = do not sync anything before building.
#     Affects the variable SYNC_TYPE
#
#  -push {no, yes}
#     no  = do not 'adb push' the resulting KANG (CM7 or BlackICE) to your phone
#     yes = 'adb push' the resulting KANG (CM7 or BlackICE) to your phone, requires
#           your phone to be connected to your PC via USB and requires the 'adb'
#           tool to be in your path.
#     Affects the variable PUSH_TO_PHONE
#
#  -phone <phone name>
#     ace = build for ACE (Desire HD). Building for other phones *might* work,
#           but this has not been tested!
#     Affects the variable PHONE
#
#  -adir <android source path>
#     Root directory where your CM7 sources are installed, for example:
#       ${HOME}/android/system
#     Affects the variable ANDROID_DIR
#
#  -bdir <blackICE ICEDroid path>
#     Root directory where your BlackICE sources are installed, for example:
#       ${HOME}/android/blackice/ICEDroid
#     Affects the variable BLACKICE_DIR
#
#  -cm7make {bacon, full}
#     bacon = 'make bacon'
#     full  = 'make clobber' and then 'source build/envsetup.sh && brunch $PHONE'
#
#  -cm7base <name of CM7 KANG>
#     The name of a CM7 KANG that (previously built or downloaded) to use as a
#     base for building BlackICE on top of, for example:
#       cm7-20111223_004213.zip
#     This main be a full path or just the file name as shown in the example.
#     If the specified kernel does not exist, build_blackice.sh will try to
#     download it.
#     Ignored if ROM_TYPE is 'cm7' or 'all'
#     Affects the variable CM7_BASE_NAME
#
#  -bkernel <kernel name>
#     The name of the kernel file to use for the BlackICE KANG. For example:
#       lordmodUEv8.6-CFS.zip
#     This main be a full path or just the file name as shown in the example.
#     If the specified kernel does not exist, build_blackice.sh will try to
#     download it.
#     Affects the variable BLACKICE_KERNEL_NAME
#
#  -bgps <GPS region name>
#     The GPS region to use for the BlackICE KANG. This name must match one of
#     the sub-directory names under ${BLACKICE_DIR}/sdcard/blackice/gpsconf.
#     For example:
#       TAIWAN
#     If this is an empty value, "", then the BlackICE build.sh script will use
#     its default value.
#     Affects the variable BLACKICE_GPS_NAME
#
#  -bril <RIL number>
#     The RIL to use for the BlackICE KANG. This name must match the numeric
#     part of one of the sub-directory names under ${BLACKICE_DIR}/sdcard/blackice/ril.
#     For example:
#       2.2.0018G
#     (this matches the sub-directory name 'HTC-RIL_2.2.0018G').
#     If this is an empty value, "", then the BlackICE build.sh script will use
#     its default value.
#     Affects the variable BLACKICE_RIL_NAME
#
#  -patch <patch file name>
#     Name of a .git or .patch patch file to be applied to the BlackICE sources.
#     The patches are applied *after* all syncs are done ('repo sync' and 'git pull').
#     If you specify multiple patches then they will done in the order given.
#
#     The format of a patch file name is very important because the build process
#     uses that name to figure out what CM7 or BlackICE directory to change into in
#     order to apply the patch! The name of the patch file must match one of these:
#       android_<patch_dir>@<any_name>.{git|patch}
#       blackice_<patch_dir>@<any_name>.{git|patch}
#
#     - The prefix of 'android_' or 'blackice_' indicates whether to patch CM7 or
#       BlackICE (currently we haven't tested any BlackICE patching...).
#     - The 'patch_dir', between the prefix and the '@' character indicates the
#       directory to apply the patch to. A '_' (underscore) must be used to
#       separate subdirectories.
#     - The part after the '@' and before the extension can be any descriptive
#       name you want.
#     - The description must be either .git or .patch and which one you use depends
#       on the type of patch.
#       - A .git patch file contains a 'git fetch ...' command
#       - A .patch patch file is a git diff file containing the diffs to apply
#
#     Here is an example from the ICEDroid/src directory:
#       android_frameworks_base@FRAMEWORK_TORCH.git
#
#     - "android_" indicates we will patch the CM7 sources at ${ANDROID_DIR}
#     - "frameworks_base" means we will apply the patch at ${ANDROID_DIR}/frameworks/base
#     - "FRAMEWORK_TORCH" is just a descriptive name for us humans
#     - ".git" means we will execute this like a shell script.
#
#
# Examples:
#   build.sh -ini custom.ini -check
#     - Initialize all the variables from the file 'custom.ini'
#     - Display what would normal be built without actually building anything.
#
#   build.sh -ini ../cfg/test.ini -rom cm7 -sync none -push yes
#     - Initialize all the variables from the file '../cfg/test.ini'
#     - Build a CM7 KANG without doing a repo sync.
#     - The result is pushed to the phone.
#
#   build.sh -ini bi.ini -rom bi -cm7base my-CM7-KANG.zip -bkernel lordmodUEv8.6-CFS -bgps QATAR -bril 2.2.1003G -sync bi
#     - Initialize all the variables from the file 'bi.ini'
#     - Sync BlackICE before building ('get fetch').
#     - Build a BlackICE KANG using my-CM7-KANG.zip as a base. my-CM7-KANG.zip must
#       exist in the directory ${BLACKICE_DIR}/download.
#     - Kernel = lordmodUEv8.6-CFS
#     - GPS    = QATAR
#     - RIL    = HTC-RIL_2.2.1003G
#     - The command line did not specify whether or not the result is pushed to
#       the phone. So the setting for this in 'bi.ini' will be used.
#

#
# Helper function for displaying a banner to indicate which step in the build is
# currently being done.
#
function banner() {
  echo ""
  echo "*******************************************************************************"
  echo "  $1"
  echo "*******************************************************************************"
  echo ""
}


if [ "$USER" = "" ] || [ "$HOME" = "" ] ; then
  echo ""
  echo "$0: The Linux environment variables USER and HOME must be defined!"
  echo ""
  return 1
fi

#
# Stores the .ini file name for display and also so we can detect if it was given
#
INI_NAME=""

# If the -check command line option is given we only check everything and display
# what would normally be built, but we quit without building anything.
CHECK_ONLY=0

# If a 'clean' argument is given we will suppress some argument checking and
# will not build anything. We will just do the specified clean operation.
CLEAN_ONLY=0

#
# Helpers for testing which ROM to build. This is modfied based on the .ini file
# and/or command line arguments.
#
DO_CM7=0
DO_BLACKICE=0

# SHOW_HELP will let us decide if we need to display the usage information
SHOW_HELP=0

if [ "$1" = "-h" ] || [ "$1" = "-?" ]; then
  # Setting this to 1 will cause the command line loop processing to be skipped.
  SHOW_HELP=1
fi

#
# We don't check for errors in this loop. Instead we wait until we are done
# so we can detect errors that occur becuase of either the .ini file for the
# command line.
#
while [ $# -gt 0 ] && [ "$SHOW_HELP" = "0" ]; do
  # We need to set this to 1 every time in order to detect a bad option.
  SHOW_HELP=1

  if [ "$1" = "-ini" ]; then
    shift 1
    INI_NAME=$1

    # Check for leading "-", which indicates we got another command line option
    # instead of an ini name.
    ARG_TEMP=${INI_NAME:0:1}
    if [ "$INI_NAME" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Expected a file name after '-ini', saw '${INI_NAME}'"
      echo ""
    else
      TEMP_INI_DIR=$(cd "$(dirname "$INI_NAME")"; pwd)
      TEMP_INI_BASE=`basename ${INI_NAME}`
      INI_NAME=${TEMP_INI_DIR}/${TEMP_INI_BASE}
      if [ ! -f $INI_NAME ]; then
        echo ""
        echo "  ERROR .ini file '${INI_NAME}' does not exist"
        echo ""
      else
        source ${INI_NAME}
        RESULT="$?"
        if [ "$RESULT" != "0" ] ; then
          echo ""
          echo "  ERROR processing '${INI_NAME}' = ${RESULT}"
          echo ""
        else
          SHOW_HELP=0
        fi
      fi
    fi
  fi

  if [ "$1" = "-check" ]; then
    # We aren't going to actually do the build
    CHECK_ONLY=1
    SHOW_HELP=0
  fi

  if [ "$1" = "-verbose" ]; then
    shift 1
    VERBOSE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-clean" ]; then
    shift 1
    CLEAN_TYPE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-rom" ]; then
    shift 1
    ROM_TYPE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-sync" ]; then
    shift 1
    SYNC_TYPE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-push" ]; then
    shift 1
    PUSH_TO_PHONE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-phone" ]; then
    shift 1
    PHONE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-adir" ]; then
    shift 1
    ANDROID_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bdir" ]; then
    shift 1
    BLACKICE_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cm7make" ]; then
    shift 1
    CM7_MAKE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cm7base" ]; then
    shift 1
    CM7_BASE_NAME=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bkernel" ]; then
    shift 1
    BLACKICE_KERNEL_NAME=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bgps" ]; then
    shift 1
    BLACKICE_GPS_NAME=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bril" ]; then
    shift 1
    BLACKICE_RIL_NAME=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-patch" ]; then
    shift 1
    TEMP_PATCH=$1
    if [ "$TEMP_PATCH" = "" ]; then
      echo ""
      echo "  ERROR no patch file specified for '-patch'"
      echo ""
    else
      # Get the full absolute path to this file
      ##TEMP_PATCH=$(readlink -f "$TEMP_PATCH")
      TEMP_PATCH_DIR=$(cd "$(dirname "$TEMP_PATCH")"; pwd)
      TEMP_PATCH_BASE=`basename ${TEMP_PATCH}`
      PATCH_FILE_LIST=${PATCH_FILE_LIST}" ${TEMP_PATCH_DIR}/${TEMP_PATCH_BASE}"
      SHOW_HELP=0
    fi
  fi

  shift 1
done

#
# Now that we got all the command line parameters, verify the variables. We do this
# now instead of in the command parser so that we also verify the values of
# variables that come from the .ini file in case someone made a typo in there.
#
if [ "$SHOW_HELP" = "0" ]; then

  if [ "$VERBOSE" = "" ]; then
    VERBOSE=1
  fi
  if [ $VERBOSE -lt 0 -o $VERBOSE -gt 9 ]; then
    echo ""
    echo "  ERROR: Valid values for VERBOSE (in .ini file) or '-verbose' are {0..9}, saw '${VERBOSE}'"
    echo ""
    SHOW_HELP=1
  fi

  if  [ "$CLEAN_TYPE" != "" ] && [ "$CLEAN_TYPE" != "cm7" ] && [ "$CLEAN_TYPE" != "bi" ] && [ "$CLEAN_TYPE" != "all" ]; then
    echo ""
    echo "  ERROR: Valid values for CLEAN_TYPE (in .ini file) or '-clean' are {cm7, bi, all, \"\"}, saw '${CLEAN_TYPE}'"
    echo ""
    SHOW_HELP=1
  fi
  if  [ "$CLEAN_TYPE" != "" ]; then
    # When doing a clean there is no need to force the user to provide a lot of
    # correct arguments that won't even be used.
    CLEAN_ONLY=1
  fi

  if  [ "$CLEAN_ONLY" = "0" ]; then
    # We aren't doing a clean, so we need to validate EVERyTHING.

    if  [ "$ROM_TYPE" = "" ] || ([ "$ROM_TYPE" != "cm7" ] && [ "$ROM_TYPE" != "bi" ] && [ "$ROM_TYPE" != "all" ]); then
      echo ""
      echo "  ERROR: Valid values for ROM_TYPE (in .ini file) or '-rom' are {cm7, bi, all}, saw '${ROM_TYPE}'"
      echo ""
      SHOW_HELP=1
    fi

    # Set some helpers to make things easier and to prevent typos later
    if [ "$ROM_TYPE" = "bi" ] || [ "$ROM_TYPE" = "all" ]; then
      DO_BLACKICE=1
    fi
    if [ "$ROM_TYPE" = "cm7" ] || [ "$ROM_TYPE" = "all" ]; then
      DO_CM7=1
    fi


    if [ "$SYNC_TYPE" != "" ] && [ "$SYNC_TYPE" != "cm7" ] && [ "$SYNC_TYPE" != "bi" ] && [ "$SYNC_TYPE" != "all" ] && [ "$SYNC_TYPE" != "none" ]; then
      echo ""
      echo "  ERROR: Valid values for SYNC_TYPE (in .ini file) or '-sync' are {cm7, bi, all, \"\"}, saw '${SYNC_TYPE}'"
      echo ""
      SHOW_HELP=1
    fi

    if [ "$PUSH_TO_PHONE" = "" ] || ([ "$PUSH_TO_PHONE" != "no" ] && [ "$PUSH_TO_PHONE" != "yes" ]); then
      echo ""
      echo "  ERROR: Valid values for PUSH_TO_PHONE (in .ini file) or '-phone' are {no, yes}, saw '${PUSH_TO_PHONE}'"
      echo ""
      SHOW_HELP=1
    fi


    # A leading "-" indicates we got another command line option instead of a phone name.
    ARG_TEMP=${PHONE:0:1}
    if [ "$PHONE" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Invalid value for PHONE (in .ini file) or '-phone', saw '${PHONE}'"
      echo ""
      SHOW_HELP=1
    fi

    if [ "$DO_CM7" =  "1" ]; then
      if [ "$CM7_MAKE" = "" ] || ([ "$CM7_MAKE" != "bacon" ] && [ "$CM7_MAKE" != "full" ]); then
        echo ""
        echo "  ERROR: Valid values fo CM7_MAKE (in .ini file) or '-cm7make' are {bacon, full}, saw '${CM7_MAKE}'"
        echo ""
        SHOW_HELP=1
      fi
    fi

    if [ "$DO_BLACKICE" =  "1" ]; then
      if [ "$ROM_TYPE" = "bi" ]; then
        # A leading "-" indicates we got another command line option instead of a phone name.
        ARG_TEMP=${CM7_BASE_NAME:0:1}
        if [ "$CM7_BASE_NAME" = "" ] || [ "$ARG_TEMP" = "-" ]; then
          echo ""
          echo "  ERROR: Invalid value for CM7_BASE_NAME (in .ini file) or '-cm7base', saw '${CM7_BASE_NAME}'"
          echo ""
          SHOW_HELP=1
        fi
      fi

      # A leading "-" indicates we got another command line option instead of a phone name.
      ARG_TEMP=${BLACKICE_KERNEL_NAME:0:1}
      if [ "$BLACKICE_KERNEL_NAME" = "" ] || [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_KERNEL_NAME (in .ini file) or '-bkernel', saw '${BLACKICE_KERNEL_NAME}'"
        echo ""
        SHOW_HELP=1
      fi


      # A leading "-" indicates we got another command line option instead of a phone name.
      ARG_TEMP=${BLACKICE_GPS_NAME:0:1}
      if [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_GPS_NAME (in .ini file) or '-bgps', saw '${BLACKICE_GPS_NAME}'"
        echo ""
        SHOW_HELP=1
      fi


      # A leading "-" indicates we got another command line option instead of a phone name.
      if [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_RIL_NAME (in .ini file) or '-bril', saw '${BLACKICE_RIL_NAME}'"
        echo ""
        SHOW_HELP=1
      fi
    fi

    for patch_file in $PATCH_FILE_LIST
    do
      # A valid patch file name must end with ".git" or ".patch"
      if [ "${patch_file:(-4)}" != ".git" ] && [ "${patch_file:(-6)}" != ".patch" ]; then
        echo ""
        echo "  ERROR: Valid patch names must have the extension '.git' or '.patch', saw '${patch_file}'"
        echo ""
        SHOW_HELP=1
      fi
    done
  fi      # End of items skipped when CLEAN_ONLY is "1"

  #
  # These items need to be checked even if just doing a clean
  #

  if [ "$CLEAN_TYPE" != "bi" ] && [ "$DO_CM7" = "1" ]; then
    # A leading "-" indicates we got another command line option instead of a phone name.
    ARG_TEMP=${ANDROID_DIR:0:1}
    if [ "$ANDROID_DIR" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Invalid value for ANDROID_DIR (in .ini file) or '-adir', saw '${ANDROID_DIR}'"
      echo ""
      SHOW_HELP=1
    fi
  fi

  if [ "$CLEAN_TYPE" != "cm7" ] && [ "$DO_BLACKICE" = "1" ]; then
    # A leading "-" indicates we got another command line option instead of a phone name.
    ARG_TEMP=${BLACKICE_DIR:0:1}
    if [ "$BLACKICE_DIR" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Invalid value for BLACKICE_DIR (in .ini file) or '-bdir', saw '${BLACKICE_DIR}'"
      echo ""
      SHOW_HELP=1
    fi
  fi
fi

if [ "$SHOW_HELP" = "1" ]; then
  echo ""
  echo "  Usage is $0 [params]"
  echo "    -ini <ini_file>"
  echo "       specifies the .ini file to load, which specifies most other options."
  echo "    -check"
  echo "       show what would have been built, but do not build anything"
  echo "    -clean {cm7, bi, all, \"\"}"
  echo "       Do a CM7 'make clobber', a BlackICE 'make clean', both or none."
  echo "       If the value is non-NULL then we do not build anything."
  echo "    -verbose {0..9}"
  echo "       0 = extra quite (not implemented), 1 = normal build messages,"
  echo "       2 = extra build messages, 3..9 = even more build messages (not be implemented)"
  echo "    -rom {cm7, bi, all}"
  echo "       Build for CM7, BlackICE or All (both)"
  echo "    -sync {cm7, bi, all, \"\"}"
  echo "       Do a 'repo sync' (CM7), 'git pull' (BlackICE), All (both) or No sync"
  echo "       The sync is done before the build"
  echo "    -push {no, yes}"
  echo "       no = do not 'adb push' KANG to phone, yes = 'adb push' KANG to phone"
  echo "    -phone <phone name>"
  echo "       Name of phone to build for, WARNING only tested with 'ace'"
  echo "    -adir <path>"
  echo "       Full path to root of where Android (CM7) source is located"
  echo "    -bdir <path>"
  echo "       Full path to the BlackICE 'ICEDroid' directory "
  echo "    -bkernel <kernel_file>"
  echo "       Name of kernel file to build into BlackICE"
  echo "    -bgps <gps_region>"
  echo "       Name of GPS region to build into BlackICE, can be \"\""
  echo "    -bril <ril_version>"
  echo "       Name of RIL to build into BlackICE, can be \"\""
  echo "    -patch <patch_file>"
  echo "       Name of .git or .patch patch file. May be be given multiple times"
  echo ""
  echo "  For more details see the comments in the top of '$0'"
  echo ""
  return 1
fi

if [ "$CLEAN_ONLY" = "0" ]; then
  #
  # If some tools can't be found you may need to include on or more of these directories in your path.
  #
  # #export PATH=./:${HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ANDROID_DIR}/out/host/linux-x86/bin
  #

  # The ROM we build will go here. Don't change this because it is where the
  # Cyanogen makefile puts the new ROM, it needs to match.
  CM7_ROM_DIR=${ANDROID_DIR}/out/target/product/${PHONE}

  if [ "$CM7_BASE_NAME" != "" ] && [ "$ROM_TYPE" != "bi" ]; then
    echo ""
    echo "  Warning: '-cm7base' is ignored when '-rom' type is '$ROM_TYPE'"
    echo ""
  fi

  if [ "$DO_BLACKICE" = "1" ]; then
    if [ ! -f $BLACKICE_KERNEL_NAME ]; then
      if [ ! -f ${BLACKICE_DIR}/download/${BLACKICE_KERNEL_NAME} ]; then
        echo ""
        echo "  Warning: BlackICE kernel does not exist: '${BLACKICE_KERNEL_NAME}'"
        echo "           We will try to download it, but that may not be successful!"
        echo ""
      fi
    fi

    if [ "$ROM_TYPE" = "bi" ]; then
      if [ ! -f $CM7_BASE_NAME ]; then
        if [ ! -f ${BLACKICE_DIR}/download/${CM7_BASE_NAME} ]; then
          echo ""
          echo "  Warning: CM7 Base KANG does not exist: '${CM7_BASE_NAME}'"
          echo "           We will try to download it, but that may not be successful!"
          echo ""
        fi
      fi
    fi

    # BLACKICE_GPS_NAME is allowed to be empty in order to use the default ICEDroid
    # GPS info in the build
    if [ "$BLACKICE_GPS_NAME" != "" ]; then
      BLACKICE_GPS_FILE=${BLACKICE_DIR}/sdcard/blackice/gpsconf/${BLACKICE_GPS_NAME}/gps.conf
      if [ ! -f ${BLACKICE_GPS_FILE} ]; then
        echo ""
        echo "  ERROR: BlackICE gps.conf does not exist: ${BLACKICE_GPS_FILE}"
        echo ""
        return 1
      fi
    fi

    # BLACKICE_RIL_NAME is allowed to be empty in order to use the default ICEDroid
    # RIL in the build
    if [ "$BLACKICE_RIL_NAME" != "" ]; then
      BLACKICE_RIL_FILE=${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_${BLACKICE_RIL_NAME}
      if [ ! -d $BLACKICE_RIL_FILE ]; then
        echo ""
        echo "  ERROR: BlackICE ril directory does not exist: ${BLACKICE_RIL_FILE}"
        echo ""
        return 1
      fi
    fi
  fi

  # Verify that all specified patch files exist and specify a valid directory
  # to patch into
  if [ "$PATCH_FILE_LIST" != "" ]; then
    # As we verify the destination directory we have to do some work to figure
    # out what that directory is. We might as well save that here rather than
    # doing it all again when we are actually ready to patch.
    #
    # The file will have a format like
    #   <path>/d@f.git
    #   <path>/d@f.patch
    # 'd' part of the file name specifies the directory to apply the patch to
    # to changing '_' to '/' to create a directory tree.
    # '@' separats the above directory specifier from the arbitray patch name.
    #

    # We will move all the patch files onto this list, but change each entry
    # to have the following format:
    #   patch_dir,patch_file
    # This will make it simpler for build.sh to apply the patches because we
    # want have to figure out the directory again.
    ALL_PATCH_LIST=

    ANDROID_PREFIX="android_"
    BLACKICE_PREFIX="blackice_"

    echo ""
    for PATCH_FILE in $PATCH_FILE_LIST
    do
      if [ ! -f ${PATCH_FILE} ]; then
        echo ""
        echo "  ERROR: patch file does not exist: '${PATCH_FILE}'"
        echo ""
        return 1
      fi

      # Remove any path from the patch file name or it will mess up our tests.
      PATCH_FILE_BASE=`basename $PATCH_FILE`
      if [ "${PATCH_FILE_BASE:0:8}" = "$ANDROID_PREFIX" ]; then
        if [ "$ROM_TYPE" != "bi" ]; then
          # Remove the prefix
          PATCH_DIR=${PATCH_FILE_BASE#$ANDROID_PREFIX}
          # Remove the '@' and everything after it
          PATCH_DIR=${PATCH_DIR%%@*}
          # Replace *all* underscores with '/'
          PATCH_DIR=${PATCH_DIR//_/\/}
          if [ ! -d ${ANDROID_DIR}/${PATCH_DIR} ]; then
            echo ""
            echo "  ERROR: patch file directory does not exist: '${ANDROID_DIR}/${PATCH_DIR}'"
            echo ""
            return 1
          fi

          # Save the directory for this patch so we can  use it when we actually
          # do the patch without having to rebuild it again.
          ALL_PATCH_LIST=$ALL_PATCH_LIST" ${ANDROID_DIR}/${PATCH_DIR},${PATCH_FILE}"
        else
          echo ""
          echo "  Warning: skiping CM7 specific patch: '$PATCH_FILE'"
          echo ""
        fi
      else
        if [ "${PATCH_FILE_BASE:0:9}" = "$BLACKICE_PREFIX" ]; then
          if [ "$ROM_TYPE" != "cm7" ]; then
            # Remove the prefix
            PATCH_DIR=${PATCH_FILE_BASE#$BLACKICE_PREFIX}
            # Remove the '@' and everything after it
            PATCH_DIR=${PATCH_DIR%%@*}
            # Replace *all* underscores with '/'
            PATCH_DIR=${PATCH_DIR//_/\/}

            if [ ! -d ${BLACKICE_DIR}/${PATCH_DIR} ]; then
              echo ""
              echo "  ERROR: patch file directory does not exist: '${BLACKICE_DIR}/${PATCH_DIR}'"
              echo ""
              return 1
            fi

            # Save the directory for this patch so we can  use it when we actually
            # do the patch without having to rebuild it again.
            ALL_PATCH_LIST=$ALL_PATCH_LIST" ${BLACKICE_DIR}/${PATCH_DIR},${PATCH_FILE}"
          else
            echo ""
            echo "  Warning: skiping BlackICE specific patch: '$PATCH_FILE'"
            echo ""
          fi
        else
          echo ""
          echo "  ERROR: patch file must have a prefix of '${ANDROID_PREFIX}' or '${BLACKICE_PREFIX}', saw '${PATCH_FILE}'"
          echo ""
          return 1
        fi
      fi
    done
  fi
fi


echo "Build information"
echo "   INI file      = $INI_NAME"
echo "   User          = $USER"
echo "   Home dir      = $HOME"

if [ "$CLEAN_ONLY" = "0" ]; then
  echo "   Phone         = $PHONE"

  if [ "$ROM_TYPE" = "cm7" ]; then
    echo "   ROM           = CM7 only"
  else
    if [ "$ROM_TYPE" = "bi" ]; then
      echo "   ROM           = BlackICE only"
    else
      echo "   ROM           = CM7 + BlackICE"
    fi
  fi

  if [ "$DO_CM7" = "1" ]; then
    echo "   Android dir   = $ANDROID_DIR"

    if  [ "$CM7_MAKE" = "bacon" ]; then
      echo "   CM7 make      = make bacon"
    else
      echo "   CM7 make      = make clobber + brunch"
    fi
  fi

  if [ "$DO_BLACKICE" = "1" ]; then
    echo "   BlackICE dir  = $BLACKICE_DIR"
    echo "   Kernel        = $BLACKICE_KERNEL_NAME"


    if [ "$BLACKICE_GPS_NAME" = "" ]; then
     echo "   GPS region    = << default >>"
    else
     echo "   GPS region    = $BLACKICE_GPS_NAME"
    fi

    if [ "$BLACKICE_RIL_NAME" = "" ]; then
      echo "   RIL           = << default >>"
    else
      echo "   RIL           = $BLACKICE_RIL_NAME"
    fi

    if [ "$DO_CM7" = "1" ]; then
      echo "   CM7 base      = << from CM7 build >>"
    else
      echo "   CM7 base      = $CM7_BASE_NAME"
    fi

  fi

  if [ "$PATCH_FILE_LIST" != "" ]; then
    echo ""
    for patch_file in $PATCH_FILE_LIST
    do
      echo "   Patch         = ${patch_file}"
    done
  fi

  if [ "$SYNC_TYPE" = "cm7" ]; then
    echo "   Sync          = CM7 (repo sync)"
  else
    if [ "$SYNC_TYPE" = "bi" ]; then
      echo "   Sync          = BlackICE (git pull)"
    else
      if [ "$SYNC_TYPE" = "all" ]; then
        echo "   Sync          = CM7 + BlackICE (repo sync + git pull)"
      else
        echo "   Sync          = none"
      fi
    fi
  fi

  echo "   Push to phone = $PUSH_TO_PHONE"

else

  # CLEAN_ONLY is 1
  if [ "$DO_CM7" = "1" ]; then
    echo "   Android dir   = $ANDROID_DIR"
  fi

  if [ "$DO_BLACKICE" = "1" ]; then
    echo "   BlackICE dir  = $BLACKICE_DIR"
  fi

  if [ "$CLEAN_TYPE" = "bi" ]; then
    echo "   Clean         = BlackICE"
  else
    if [ "$CLEAN_TYPE" = "cm7" ]; then
      echo "   Clean         = CM7"
    else
      if [ "$CLEAN_TYPE" = "all" ]; then
        echo "   Clean         = CM7 + BlackICE"
      fi
    fi
  fi
fi
echo ""

# Return 0 for no error
return 0


