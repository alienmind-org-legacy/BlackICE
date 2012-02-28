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
#  -clean {cm7, cm9, bi, cm7bi, cm9bi, none, ""}
#     cm7    = do a CM7 'make clobber'
#     cm9    = do a CM9 'make clobber'
#     bi     = do a BI 'make clean'
#     cm7bi  = do a CM7 and a BI clean
#     cm9bi  = do an CM9 and a BI clean
#     ""   = do not clean anything (do a normal build)
#     none = same as above
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
#  -rom {cm7, cm9, bi, cm7bi, cm9bi}
#     cm7   = only build a CM7 ROM.
#     cm9   = only build an CM9 ROM.
#     bi    = only build a BlackICE ROM (requires CM79_BASE_NAME to be set).
#     cm7bi = build a CM7 ROM and then a BlackICE ROM from that base.
#     cm9bi = build an CM9 ROM and then a BlackICE ROM from that base.
#     Affects the variable ROM_TYPE
#
#  -sync {cm7, cm9, bi, cm7bi, cm9bi, none, ""}
#     cm7   = sync the CM7 sources, 'repo sync', before building.
#     cm9   = sync the CM9 sources, 'repo sync', before building.
#     bi    = sync the BlackICE clone, 'git pull', before building.
#     cm7bi = sync both CM7 and BlackICE before building.
#     cm9bi = sync both CM9 and BlackICE before building.
#     ""   = do not sync anything before building.
#     none = same as above
#     Affects the variable SYNC_TYPE
#
#  -fpatch {no, yes, 0, 1}
#     no   = do not force patches to be applied when not syncing (default and suggested)
#     0    = same as 'no'
#     yes  = force patches to be applied when not syncing (not recommended)
#     1    = same as 'yes'
#     Normally you do not want to enable this becuase patching an already patched
#     code base will cause an error and the build will abort. This is mainly here
#     in case you did a manual sync and then decide to build and you want the normal
#     patches to be applied.
#     Affects the variable FORCE_PATCHING
#
#  -push {no, yes, 0, 1}
#     no  = do not 'adb push' the resulting KANG (CM7, CM9 or BlackICE) to your phone
#     0   = same as 'no'
#     yes = 'adb push' the resulting KANG (CM7, CM9 or BlackICE) to your phone, requires
#           your phone to be connected to your PC via USB and requires the 'adb'
#           tool to be in your path.
#     1   = same as 'yes'
#     Affects the variable PUSH_TO_PHONE
#
#  -phone <phone name>
#     ace = build for ACE (Desire HD). Building for other phones *might* work,
#           but this has not been tested!
#     Affects the variable PHONE
#
#  -cm7dir <cm7 source path>
#     Root directory where your CM7 sources are installed, for example:
#       ${HOME}/android/system
#     Only used if ROM_TYPE is 'cm7' or 'cm7bi'
#     Affects the variable CM7_DIR
#
#  -cm9dir <cm9 source path>
#     Root directory where your CM9 sources are installed, for example:
#       ${HOME}/android/cm9
#     Only used if ROM_TYPE is 'cm9' or 'cm9bi'
#     Affects the variable CM9_DIR
#
#  -bdir <blackICE BlackICE path>
#     Root directory where your BlackICE sources are installed, for example:
#       ${HOME}/android/blackice/BlackICE
#     Affects the variable BLACKICE_DIR
#
#  -dbox <dropbox path>
#     Directory of your dropbox (or a sub-directory inside of it) to copy the
#     result files to, for example:
#       ${HOME}/Dropbox  -- or -- ${HOME}/Dropbox/Public/BlackICE
#     This gets the upload started as soon as possible. The
#     files that get copied depend on the type of build, such as CM7 KANG,
#     CM9 KANG, BlackICE KANG, BlackICE Extra Apps.
#     If this is an empty value, "", then nothing is copied to the dropbox.
#     Affects the variable DROPBOX_DIR
#
#  -cmmake {bacon, full}
#     bacon = 'make bacon'
#     full  = 'make clobber' and then 'source build/envsetup.sh && brunch $PHONE'
#     Only used if ROM_TYPE is 'cm7' or 'cm9'
#     Affects the variable CM79_MAKE
#
#  -cmbase <name of CM7/CM9 KANG>
#     The name of a CM7/CM9 KANG that (previously built or downloaded) to use as a
#     base for building BlackICE on top of, for example:
#       cm7-20111223_004213.zip
#     This main be a full path or just the file name as shown in the example.
#     If the specified kernel does not exist, build_blackice.sh will try to
#     download it.
#     Only used if ROM_TYPE is 'cm7bi' or 'cm9bi'
#     Affects the variable CM79_BASE_NAME
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
#  -prompt {0..30, 999}
#     0     = do not pause and prompt for user input before doing the build.
#     1..30 = pause for the given number of seconds and then do the build.
#     999   = show the build information, but don't actually build anything.
#     Affects the variable PROMPT
#
#  -official {no, yes, 0, 1}
#     no  = do a 'nightly' build using a timestamp as part of the name.
#     0   = same as 'no'
#     yes = create an official release with 'RC' as part of the name before the timestamp.
#     1   = same as 'yes'
#     Affects the variable OFFICIAL
#

#
# Examples:
#   build.sh -ini custom.ini
#     - Initialize all the variables from the file 'custom.ini'
#     - Display what is going to be built and wait for 10 seconds before starting the build.
#
#   build.sh -ini ../cfg/test.ini -rom cm7 -sync none -push yes -prompt 0
#     - Initialize all the variables from the file '../cfg/test.ini'
#     - Build a CM7 KANG without doing a repo sync.
#     - The result is pushed to the phone.
#     - Start the build without a prompt or any delay.
#     - Other options come from the .ini file.
#
#   build.sh -ini bi.ini -rom bi -cmbase my-CM7-KANG.zip -bkernel lordmodUEv8.6-CFS.zip -bgps QATAR -bril 2.2.1003G -sync bi -prompt 999
#     - Initialize all the variables from the file 'bi.ini'
#     - Sync BlackICE before building ('get fetch').
#     - Build a BlackICE KANG using my-CM7-KANG.zip as a base. my-CM7-KANG.zip must
#       exist in the directory ${BLACKICE_DIR}/download.
#     - Kernel = lordmodUEv8.6-CFS.zip
#     - GPS    = QATAR
#     - RIL    = HTC-RIL_2.2.1003G
#     - Prompt = 999 = don't actually build, just show what would have been built.
#     - Other options come from the .ini file.
#
#   build.sh -ini bi.ini -rom cm7bi -bkernel lordmodUEv8.7-CFS-b2.zip -sync none -official 1
#     - Initialize all the variables from the file 'bi.ini'
#     - Don't sync CM7 or BlackICe before building.
#     - Build a CM7 KANG and then a BlackICE KANG using that.
#     - Kernel = lordmodUEv8.7-CFS-b2.zip
#     - Build an official release instead of a nightly.
#     - Other options come from the .ini file.
#

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

# If a 'clean' argument is given we will suppress some argument checking and
# will not build anything. We will just do the specified clean operation.
CLEAN_ONLY=0

#
# Helpers for testing which ROM to build. This is modfied based on the .ini file
# and/or command line arguments.
#
DO_CM7=0
DO_CM9=0
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
      INI_NAME=`GetAbsolutePath ${INI_NAME}`
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

  if [ "$1" = "-fpatch" ]; then
    shift 1
    FORCE_PATCHING=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-phone" ]; then
    shift 1
    PHONE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cm7dir" ]; then
    shift 1
    CM7_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cm9dir" ]; then
    shift 1
    CM9_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-bdir" ]; then
    shift 1
    BLACKICE_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-dbox" ]; then
    shift 1
    DROPBOX_DIR=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cmmake" ]; then
    shift 1
    CM79_MAKE=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-cmbase" ]; then
    shift 1
    CM79_BASE_NAME=$1
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

  if [ "$1" = "-prompt" ]; then
    shift 1
    PROMPT=$1
    SHOW_HELP=0
  fi

  if [ "$1" = "-official" ]; then
    shift 1
    OFFICIAL=$1
    SHOW_HELP=0
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

  if  [ "$CLEAN_TYPE" != "" ]    && [ "$CLEAN_TYPE" != "none" ] && [ "$CLEAN_TYPE" != "cm7" ] &&   \
      [ "$CLEAN_TYPE" != "cm9" ] && [ "$CLEAN_TYPE" != "bi" ]   && [ "$CLEAN_TYPE" != "cm7bi" ] && \
      [ "$CLEAN_TYPE" != "cm9bi" ] ; then
    echo ""
    echo "  ERROR: Valid values for CLEAN_TYPE (in .ini file) or '-clean' are {cm7, cm9, bi, cm7bi, cm9bi, none, \"\"}, saw '${CLEAN_TYPE}'"
    echo ""
    SHOW_HELP=1
  fi
  if  [ "$CLEAN_TYPE" != "" ] && [ "$CLEAN_TYPE" != "none" ]; then
    # When doing a clean there is no need to force the user to provide a lot of
    # correct arguments that won't even be used.
    CLEAN_ONLY=1
  fi

  if  [ "$CLEAN_ONLY" = "0" ]; then
    # We aren't doing a clean, so we need to validate EVERYTHING.

    if  [ "$ROM_TYPE" = "" ] || \
          ([ "$ROM_TYPE" != "cm7" ]    && [ "$ROM_TYPE" != "cm9" ] && [ "$ROM_TYPE" != "bi" ] && \
           [ "$ROM_TYPE" != "cm7bi" ]  && [ "$ROM_TYPE" != "cm9bi" ]); then
      echo ""
      echo "  ERROR: Valid values for ROM_TYPE (in .ini file) or '-rom' are {cm7, cm9, bi, cm7bi, cm9bi}, saw '${ROM_TYPE}'"
      echo ""
      SHOW_HELP=1
    fi

    # Set some helpers to make things easier and to prevent typos later
    if [ "$ROM_TYPE" = "bi" ] || [ "$ROM_TYPE" = "cm7bi" ] || [ "$ROM_TYPE" = "cm9bi" ]; then
      DO_BLACKICE=1
    fi
    if [ "$ROM_TYPE" = "cm7" ] || [ "$ROM_TYPE" = "cm7bi" ]; then
      DO_CM7=1
    fi
    if [ "$ROM_TYPE" = "cm9" ] || [ "$ROM_TYPE" = "cm9bi" ]; then
      DO_CM9=1
    fi


    if [ "$SYNC_TYPE" != "" ]    && [ "$SYNC_TYPE" != "none" ] && [ "$SYNC_TYPE" != "cm7" ] &&   \
       [ "$SYNC_TYPE" != "cm9" ] && [ "$SYNC_TYPE" != "bi" ]   && [ "$SYNC_TYPE" != "cm7bi" ] && \
       [ "$SYNC_TYPE" != "cm9bi" ]; then
      echo ""
      echo "  ERROR: Valid values for SYNC_TYPE (in .ini file) or '-sync' are {cm7, cm9, bi, cm7bi, cm9bi, none, \"\"}, saw '${SYNC_TYPE}'"
      echo ""
      SHOW_HELP=1
    else
      if [ "$SYNC_TYPE" == "" ]; then
        SYNC_TYPE="none"
      fi

      if [ "$SYNC_TYPE" = "cm7bi" ]; then
        if [ "$DO_CM7" !=  "1" ]; then
          SYNC_TYPE="bi"
        fi
        if [ "$DO_BLACKICE" !=  "1" ]; then
          SYNC_TYPE="cm7"
        fi
      fi

      if [ "$SYNC_TYPE" = "cm9bi" ]; then
        if [ "$DO_CM9" !=  "1" ]; then
          SYNC_TYPE="bi"
        fi
        if [ "$DO_BLACKICE" !=  "1" ]; then
          SYNC_TYPE="cm9"
        fi
      fi

      if ([ "$SYNC_TYPE" = "cm7" ] && [ "$DO_CM7" !=  "1" ]) || ([ "$SYNC_TYPE" = "cm9" ] && [ "$DO_CM9" !=  "1" ]); then
        SYNC_TYPE="none"
      fi
    fi

    if [ "$PUSH_TO_PHONE" = "" ] || \
         ([ "$PUSH_TO_PHONE" != "no" ] && [ "$PUSH_TO_PHONE" != "yes" ] && [ "$PUSH_TO_PHONE" != "0" ] && [ "$PUSH_TO_PHONE" != "1" ]); then
      echo ""
      echo "  ERROR: Valid values for PUSH_TO_PHONE (in .ini file) or '-phone' are {no, yes, 0, 1}, saw '${PUSH_TO_PHONE}'"
      echo ""
      SHOW_HELP=1
    else
      if [ "$PUSH_TO_PHONE" = "0" ]; then
        PUSH_TO_PHONE="no"
      fi
      if [ "$PUSH_TO_PHONE" = "1" ]; then
        PUSH_TO_PHONE="yes"
      fi
    fi

    if [ "$OFFICIAL" = "" ] || \
         ([ "$OFFICIAL" != "no" ] && [ "$OFFICIAL" != "yes" ] && [ "$OFFICIAL" != "0" ] && [ "$OFFICIAL" != "1" ]); then
      echo ""
      echo "  ERROR: Valid values for OFFICIAL (in .ini file) or '-phone' are {no, yes, 0, 1}, saw '${OFFICIAL}'"
      echo ""
      SHOW_HELP=1
    else
      if [ "$OFFICIAL" = "0" ]; then
        OFFICIAL="no"
      fi
      if [ "$OFFICIAL" = "1" ]; then
        OFFICIAL="yes"
      fi
    fi


    if [ "$FORCE_PATCHING" = "" ] || \
         ([ "$FORCE_PATCHING" != "no" ] && [ "$FORCE_PATCHING" != "yes" ] && [ "$FORCE_PATCHING" != "0" ] && [ "$FORCE_PATCHING" != "1" ]); then
      echo ""
      echo "  ERROR: Valid values for FORCE_PATCHING (in .ini file) or '-fpatch' are {no, yes, 0, 1}, saw '${FORCE_PATCHING}'"
      echo ""
      SHOW_HELP=1
    else
      if [ "$FORCE_PATCHING" = "0" ]; then
        FORCE_PATCHING="no"
      fi
      if [ "$FORCE_PATCHING" = "1" ]; then
        FORCE_PATCHING="yes"
      fi
    fi

    # A leading "-" indicates we got another command line option instead of a phone name.
    ARG_TEMP=${PHONE:0:1}
    if [ "$PHONE" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Invalid value for PHONE (in .ini file) or '-phone', saw '${PHONE}'"
      echo ""
      SHOW_HELP=1
    fi

    if [ "$DO_CM7" =  "1" ] || [ "$DO_CM9" =  "1" ]; then
      if [ "$CM79_MAKE" = "" ] || ([ "$CM79_MAKE" != "bacon" ] && [ "$CM79_MAKE" != "full" ]); then
        echo ""
        echo "  ERROR: Valid values fo CM79_MAKE (in .ini file) or '-cmmake' are {bacon, full}, saw '${CM79_MAKE}'"
        echo ""
        SHOW_HELP=1
      fi
    fi

    # A leading "-" indicates we got another command line option instead of a phone name.
    if [ "$DROPBOX_DIR" != "" ]; then
      ARG_TEMP=${DROPBOX_DIR:0:1}
      if [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for DROPBOX_DIR (in .ini file) or '-dbox', saw '${DROPBOX_DIR}'"
        echo ""
        SHOW_HELP=1
      else
        DROPBOX_DIR=`GetAbsolutePath ${DROPBOX_DIR}`
        if [ ! -d $DROPBOX_DIR ]; then
          echo ""
          echo "  ERROR: DROPBOX_DIR does not exist: '${DROPBOX_DIR}'"
          echo ""
          SHOW_HELP=1
        fi
      fi
    fi

    if [ "$DO_BLACKICE" =  "1" ]; then
      if [ "$ROM_TYPE" = "bi" ]; then
        # A leading "-" indicates we got another command line option instead of a name.
        ARG_TEMP=${CM79_BASE_NAME:0:1}
        if [ "$CM79_BASE_NAME" = "" ] || [ "$ARG_TEMP" = "-" ]; then
          echo ""
          echo "  ERROR: Invalid value for CM79_BASE_NAME (in .ini file) or '-cmbase', saw '${CM79_BASE_NAME}'"
          echo ""
          SHOW_HELP=1
        else
          CM79_BASE_NAME=`GetAbsolutePath ${CM79_BASE_NAME}`
          if [ ! -f $CM79_BASE_NAME ]; then
            echo ""
            echo "  ERROR: CM79_BASE_NAME does not exist: '${CM79_BASE_NAME}'"
            echo ""
            SHOW_HELP=1
          fi
        fi
      fi

      # A leading "-" indicates we got another command line option instead of a name.
      ARG_TEMP=${BLACKICE_KERNEL_NAME:0:1}
      if [ "$BLACKICE_KERNEL_NAME" = "" ] || [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_KERNEL_NAME (in .ini file) or '-bkernel', saw '${BLACKICE_KERNEL_NAME}'"
        echo ""
        SHOW_HELP=1
      else
        # Save the original unmodified name. We may need it a bit later.
        ORG_BLACKICE_KERNEL_NAME=${BLACKICE_KERNEL_NAME}
        BLACKICE_KERNEL_NAME=`GetAbsolutePath ${BLACKICE_KERNEL_NAME}`
      fi

      # A leading "-" indicates we got another command line option instead of a name.
      ARG_TEMP=${BLACKICE_GPS_NAME:0:1}
      if [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_GPS_NAME (in .ini file) or '-bgps', saw '${BLACKICE_GPS_NAME}'"
        echo ""
        SHOW_HELP=1
      fi

      # A leading "-" indicates we got another command line option instead of a name.
      ARG_TEMP=${BLACKICE_RIL_NAME:0:1}
      if [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for BLACKICE_RIL_NAME (in .ini file) or '-bril', saw '${BLACKICE_RIL_NAME}'"
        echo ""
        SHOW_HELP=1
      fi
    fi

  fi      # End of items skipped when CLEAN_ONLY is "1"

  #
  # These items need to be checked even if just doing a clean
  #

  if [ "$PROMPT" = "" ] || ([ $PROMPT -lt 0 -o $PROMPT -gt 30 ] && [ $PROMPT -ne 999 ]); then
    echo ""
    echo "  ERROR: Valid values for PROMPT (in .ini file) or '-prompt' are {0..30, 999}, saw '${PROMPT}'"
    echo ""
    SHOW_HELP=1
  fi

  if [ "$CLEAN_TYPE" != "bi" ]; then
    if [ "$DO_CM7" = "1" ]; then
      # A leading "-" indicates we got another command line option instead of a phone name.
      ARG_TEMP=${CM7_DIR:0:1}
      if [ "$CM7_DIR" = "" ] || [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for CM7_DIR (in .ini file) or '-cm7dir', saw '${CM7_DIR}'"
        echo ""
        SHOW_HELP=1
      else
        CM7_DIR=`GetAbsolutePath ${CM7_DIR}`
        if [ ! -d $CM7_DIR ]; then
          echo ""
          echo "  ERROR: CM7_DIR does not exist: '${CM7_DIR}'"
          echo ""
          SHOW_HELP=1
        fi
      fi
    fi

    if [ "$DO_CM9" = "1" ]; then
      # A leading "-" indicates we got another command line option instead of a phone name.
      ARG_TEMP=${CM9_DIR:0:1}
      if [ "$CM9_DIR" = "" ] || [ "$ARG_TEMP" = "-" ]; then
        echo ""
        echo "  ERROR: Invalid value for CM9_DIR (in .ini file) or '-cm9dir', saw '${CM9_DIR}'"
        echo ""
        SHOW_HELP=1
      else
        CM9_DIR=`GetAbsolutePath ${CM9_DIR}`
        if [ ! -d $CM9_DIR ]; then
          echo ""
          echo "  ERROR: CM9_DIR does not exist: '${CM9_DIR}'"
          echo ""
          SHOW_HELP=1
        fi
      fi
    fi
  fi

  if [ "$CLEAN_TYPE" != "cm7" ] && [ "$CLEAN_TYPE" != "cm9" ] && [ "$DO_BLACKICE" = "1" ]; then
    # A leading "-" indicates we got another command line option instead of a phone name.
    ARG_TEMP=${BLACKICE_DIR:0:1}
    if [ "$BLACKICE_DIR" = "" ] || [ "$ARG_TEMP" = "-" ]; then
      echo ""
      echo "  ERROR: Invalid value for BLACKICE_DIR (in .ini file) or '-bdir', saw '${BLACKICE_DIR}'"
      echo ""
      SHOW_HELP=1
    else
      BLACKICE_DIR=`GetAbsolutePath ${BLACKICE_DIR}`
      if [ ! -d $BLACKICE_DIR ]; then
        echo ""
        echo "  ERROR: BLACKICE_DIR does not exist: '${BLACKICE_DIR}'"
        echo ""
        SHOW_HELP=1
      fi
    fi
  fi
fi

if [ "$SHOW_HELP" = "1" ]; then
  echo ""
  echo "  Usage is $0 [params]"
  echo "    -ini <ini_file>"
  echo "       specifies the .ini file to load, which specifies most other options."
  echo "    -clean {cm7, cm9, bi, cm7bi, cm9bi, none, \"\"}"
  echo "       Do a clean of CM7, CM9, BlackICE, CM7+BlackICE, CM9+BlackICE or nothing."
  echo "       CM7 and CM9 cleans use 'make clobber', BlackICE uses 'make clean'"
  echo "       If any clean is specified then we do not build anything."
  echo "    -verbose {0..9}"
  echo "       0 = extra quite (not implemented), 1 = normal build messages,"
  echo "       2 = extra build messages, 3..9 = even more build messages (not be implemented)"
  echo "    -rom {{cm7, cm9, bi, cm7bi, cm9bi}"
  echo "       Build for CM7, CM9, BlackICE, CM7+BlackICE or CM9+BlackICE"
  echo "    -sync {cm7, cm9, bi, cm7bi, cm9bi, none, \"\"}"
  echo "       Do a sync of CM7, CM9, BlackICE, CM7+BlackICE, CM9+BlackICE or nothing."
  echo "       CM7 and CM9 use 'repo sync', BlackICE uses 'git pull'"
  echo "       The sync is done before the build"
  echo "    -push {no, yes, 0, 1}"
  echo "       no or 0 = do not 'adb push' KANG to phone, yes or 1 = 'adb push' KANG to phone"
  echo "    -fpatch {no, yes, 0, 1}"
  echo "       no or 0  = do not force patching when not syncing (default, recommended)"
  echo "       yes or 1 = force patching when NOT syncing (causes errors if already patched)"
  echo "    -phone <phone name>"
  echo "       Name of phone to build for, WARNING only tested with 'ace'"
  echo "    -cm7dir <path>"
  echo "       Full path to root of where CM7 source is located"
  echo "    -cm9dir <path>"
  echo "       Full path to root of where CM9 (ICS) source is located"
  echo "    -bdir <path>"
  echo "       Full path to the BlackICE 'BlackICE' directory "
  echo "    -dbox <path>"
  echo "       Full path to a Dropbox directory to copy results to, can be \"\""
  echo "    -cmmake {bacon, full}"
  echo "       bacon = 'make bacon', full = 'make clobber' + 'brunch'"
  echo "    -cmbase <name of CM7 KANG>"
  echo "       Name of CM7/CM9 KANG to use as a base for building BlackICE"
  echo "    -bkernel <kernel_file>"
  echo "       Name of kernel file to build into BlackICE"
  echo "    -bgps <gps_region>"
  echo "       Name of GPS region to build into BlackICE, can be \"\""
  echo "    -bril <ril_version>"
  echo "       Name of RIL to build into BlackICE, can be \"\""
  echo "    -prompt {0..30, 999}"
  echo "       Delay 0..30 seconds before building."
  echo "       999 = show the build info without actually building anything."
  echo ""
  echo "  For more details see the comments in the top of '$0'"
  echo ""
  return 1
fi

if [ "$CLEAN_ONLY" = "0" ]; then
  if [ "$DO_CM7" = "1" ]; then
    # The ROM we build will go here. Don't change this because it is where the
    # Cyanogen makefile puts the new ROM, it needs to match.
    CM_ROM_DIR=${CM7_DIR}/out/target/product/${PHONE}
  fi
  if [ "$DO_CM9" = "1" ]; then
    # The ROM we build will go here. Don't change this because it is where the
    # Cyanogen makefile puts the new ROM, it needs to match.
    CM_ROM_DIR=${CM9_DIR}/out/target/product/${PHONE}
  fi

  if [ "$CM79_BASE_NAME" != "" ] && [ "$ROM_TYPE" != "bi" ]; then
    echo ""
    echo "  Warning: '-cmbase' is ignored when '-rom' type is '$ROM_TYPE'"
    echo ""
  fi

  if [ "$DO_BLACKICE" = "1" ]; then
    if [ ! -f $BLACKICE_KERNEL_NAME ]; then
      if [ ! -f ${BLACKICE_DIR}/download/${BLACKICE_KERNEL_NAME} ]; then
        TEMP_BLACKICE_KERNEL_NAME=`basename ${BLACKICE_KERNEL_NAME}`
        if [ "$ORG_BLACKICE_KERNEL_NAME" != "$TEMP_BLACKICE_KERNEL_NAME" ] || [ ! -f ${BLACKICE_DIR}/download/${TEMP_BLACKICE_KERNEL_NAME} ]; then
          echo ""
          echo "  Warning: BlackICE kernel does not exist: '${BLACKICE_KERNEL_NAME}'"
          echo "           We will try to download it, but that may not be successful!"
          echo ""
        else
          # The kernel name was specified as just a file name without any path
          # and we found it in the BlackICE/download directory so fix the name
          # to point there.
          BLACKICE_KERNEL_NAME=${BLACKICE_DIR}/download/${TEMP_BLACKICE_KERNEL_NAME}
        fi
      fi
    fi

    if [ "$ROM_TYPE" = "bi" ]; then
      if [ ! -f $CM79_BASE_NAME ]; then
        if [ ! -f ${BLACKICE_DIR}/download/${CM79_BASE_NAME} ]; then
          echo ""
          echo "  Warning: CM7/CM9 Base KANG does not exist: '${CM79_BASE_NAME}'"
          echo "           We will try to download it, but that may not be successful!"
          echo ""
        fi
      fi
    fi

    # BLACKICE_GPS_NAME is allowed to be empty in order to use the default BlackICE
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

    # BLACKICE_RIL_NAME is allowed to be empty in order to use the default BlackICE
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

  #
  # Now read all of patches from the default_patches file. We need to do some
  # verification since someone could have edited this improperly.
  #
  ALL_PATCH_LIST=""
  LINE_NUMBER=0
  DEFAULT_PATCH_FILE=${BLACKICE_DIR}/src/default_patches

  while read patch_name  source_type  patch_type  patch_file  patch_dir
  do
    LINE_NUMBER=`expr ${LINE_NUMBER} + 1`

    # Empty lines and lines with a '#' in the first column are ignored
    if [ "$patch_name" != "" ] && [ "${patch_name:0:1}" != "#" ]; then
      PATCH_LINE="${patch_name}  ${source_type}  ${patch_type}  ${patch_file}  ${patch_dir}"

      if [ "$source_type" != "cm7" ] && [ "$source_type" != "cm9" ] && [ "$source_type" != "blackice" ]; then
        echo ""
        echo "  ERROR: Invalid patch definition at line ${LINE_NUMBER} of patch file '${DEFAULT_PATCH_FILE}'"
        echo "         Field 2 must be 'cm7', 'cm9' or 'blackice', saw: '${PATCH_LINE}'"
        echo ""
        return 1
      fi

      if [ "$patch_type" != "git" ] && [ "$patch_type" != "diff" ]; then
        echo ""
        echo "  ERROR: Invalid patch definition at line ${LINE_NUMBER} of '${DEFAULT_PATCH_FILE}'"
        echo "         Field 3 must be 'git' or 'diff', saw: '${PATCH_LINE}'"
        echo ""
        return 1
      fi

      if [ "$patch_file" = "" ]; then
        echo ""
        echo "  ERROR: Invalid patch definition at line ${LINE_NUMBER} of '${DEFAULT_PATCH_FILE}'"
        echo "         Field 4 is NULL, saw: '${PATCH_LINE}'"
        echo ""
        return 1
      fi

      patch_file=${BLACKICE_DIR}/src/$patch_file

      if [ ! -f $patch_file ]; then
        echo ""
        echo "  ERROR: Cannot find patch file specified at line ${LINE_NUMBER} of '${DEFAULT_PATCH_FILE}'"
        echo "         Field 4 is bad, saw: '${PATCH_LINE}'"
        echo ""
        return 1
      fi

      if [ "$patch_dir" = "" ]; then
        echo ""
        echo "  ERROR: Invalid patch directory at line ${LINE_NUMBER} of '${DEFAULT_PATCH_FILE}'"
        echo "         Field 5 is NULL, saw: '${PATCH_LINE}'"
        echo ""
        return 1
      fi

      # PATCH_VAR is the *name* of the variable that we want to test to see if
      # the patch is enabled. For example, if patch_name is TORCH then PATCH_VAR
      # will be PATCH_TORCH. To get the actual value we have to do this
      # ${!PATCH_VAR}
      #
      PATCH_VAR="PATCH_"${patch_name}

      KEEP_PATCH=0
      if [ "$source_type" = "cm7" ] && [ "$DO_CM7" = "1" ]; then
        if [ "$SYNC_TYPE" = "cm7" ] || [ "$SYNC_TYPE" = "cm7bi" ] || [ "$FORCE_PATCHING" = "yes" ]; then
          if [ "${!PATCH_VAR}" = "1" ]; then
            KEEP_PATCH=1
          fi
        fi
      fi
      if [ "$source_type" = "cm9" ] && [ "$DO_CM9" = "1" ]; then
        if [ "$SYNC_TYPE" = "cm9" ] || [ "$SYNC_TYPE" = "cm9bi" ] || [ "$FORCE_PATCHING" = "yes" ]; then
          if [ "${!PATCH_VAR}" = "1" ]; then
            KEEP_PATCH=1
          fi
        fi
      fi
      if [ "$source_type" = "blackice" ] && [ "$DO_BLACKICE" = "1" ]; then
        if [ "$SYNC_TYPE" = "bi" ] || [ "$SYNC_TYPE" = "cm7bi" ] || [ "$SYNC_TYPE" = "cm9bi" ] || [ "$FORCE_PATCHING" = "yes" ]; then
          if [ "${!PATCH_VAR}" = "1" ]; then
            KEEP_PATCH=1
          fi
        fi
      fi

      if [ "$KEEP_PATCH" = "1" ]; then
        if [ "$source_type" = "cm7" ]; then
          patch_dir=${CM7_DIR}/$patch_dir
        else
          if [ "$source_type" = "cm9" ]; then
            patch_dir=${CM9_DIR}/$patch_dir
          else
            patch_dir=${BLACKICE_DIR}/$patch_dir
          fi
        fi

        if [ ! -d $patch_dir ]; then
          echo ""
          echo "  ERROR: Invalid patch directory at line ${LINE_NUMBER} of '${DEFAULT_PATCH_FILE}'"
          echo "         Field 5 is bad, saw: '${PATCH_LINE}'"
          echo ""
          return 1
        fi

        # Save the patch information in a way that is easy to recreate it later.
        ALL_PATCH_LIST=$ALL_PATCH_LIST" ${patch_dir},${patch_file}"
      fi

#      echo "patch_name  = '$patch_name'"
#      echo "source_type = '$source_type'"
#      echo "patch_type  = '$patch_type'"
#      echo "patch_file  = '$patch_file'"
#      echo "patch_dir   = '$patch_dir'"
#      echo "variable    = '${PATCH_VAR}' = ${!PATCH_VAR}"
#      echo "Patch List  = '${ALL_PATCH_LIST}'"
#      echo ""
    fi
  done <${DEFAULT_PATCH_FILE}

fi  # end of test section in which "$CLEAN_ONLY" is 0

ShowMessage ""
ShowMessage "Build information"
ShowMessage "   INI file       = $INI_NAME"
ShowMessage "   User           = $USER"
ShowMessage "   Home dir       = $HOME"

if [ "$CLEAN_ONLY" = "0" ]; then
  ShowMessage "   Phone          = $PHONE"

  if [ "$ROM_TYPE" = "cm7" ]; then
    ShowMessage "   ROM            = CM7 only"
  fi
  if [ "$ROM_TYPE" = "cm9" ]; then
    ShowMessage "   ROM            = CM9 (ICS) only"
  fi
  if [ "$ROM_TYPE" = "bi" ]; then
    ShowMessage "   ROM            = BlackICE only"
  fi
  if [ "$ROM_TYPE" = "cm7bi" ]; then
    ShowMessage "   ROM            = CM7 + BlackICE"
  fi
  if [ "$ROM_TYPE" = "cm9bi" ]; then
    ShowMessage "   ROM            = CM9 + BlackICE [*** NOT SUPPORTED YET ***]"
  fi

  if [ "$DO_CM7" = "1" ]; then
    ShowMessage "   CM7 dir        = $CM7_DIR"

    if  [ "$CM79_MAKE" = "bacon" ]; then
      ShowMessage "   CM7 make       = make bacon"
    else
      ShowMessage "   CM7 make       = make clobber + brunch"
    fi
  fi
  if [ "$DO_CM9" = "1" ]; then
    ShowMessage "   CM9 dir        = $CM9_DIR"

    if  [ "$CM79_MAKE" = "bacon" ]; then
      ShowMessage "   CM9 make       = make bacon"
    else
      ShowMessage "   CM9 make       = make clobber + brunch"
    fi
  fi

  if [ "$DO_BLACKICE" = "1" ]; then
    ShowMessage "   BlackICE dir   = $BLACKICE_DIR"
    ShowMessage "   Kernel         = $BLACKICE_KERNEL_NAME"


    if [ "$BLACKICE_GPS_NAME" = "" ]; then
     ShowMessage "   GPS region     = << default >>"
    else
     ShowMessage "   GPS region     = $BLACKICE_GPS_NAME"
    fi

    if [ "$BLACKICE_RIL_NAME" = "" ]; then
      ShowMessage "   RIL            = << default >>"
    else
      ShowMessage "   RIL            = $BLACKICE_RIL_NAME"
    fi

    if [ "$DO_CM7" = "1" ]; then
      ShowMessage "   CM7 base       = << from CM7 build >>"
    else
      if [ "$DO_CM9" = "1" ]; then
        ShowMessage "   CM9 base       = << from CM9 build >>"
      else
        ShowMessage "   CM base        = $CM79_BASE_NAME"
      fi
    fi

  fi

  if [ "$ALL_PATCH_LIST" != "" ]; then
    ShowMessage ""
    for patch_file in $ALL_PATCH_LIST
    do
      # The items on ALL_PATCH_LIST have the form "patch_dir,patch_file", we
      # only want to show the patch_file part.
      patch_file=${patch_file##*,}
      ShowMessage "   Patch          = ${patch_file}"
    done
  fi

  if [ "$SYNC_TYPE" = "cm7" ]; then
    ShowMessage "   Sync           = CM7 (repo sync)"
  fi
  if [ "$SYNC_TYPE" = "cm9" ]; then
    ShowMessage "   Sync           = CM9 (repo sync)"
  fi
  if [ "$SYNC_TYPE" = "bi" ]; then
    ShowMessage "   Sync           = BlackICE (git pull)"
  fi
  if [ "$SYNC_TYPE" = "cm7bi" ]; then
    ShowMessage "   Sync           = CM7 + BlackICE (repo sync + git pull)"
  fi
  if [ "$SYNC_TYPE" = "cm9bi" ]; then
    ShowMessage "   Sync           = CM9 + BlackICE (repo sync + git pull)"
  fi
  if [ "$SYNC_TYPE" = "none" ]; then
    ShowMessage "   Sync           = none"

    if [ "$FORCE_PATCHING" = "yes" ]; then
      ShowMessage "   Force Patching = yes (NOT RECOMMENDED)"
    fi
  fi

  if [ "$DROPBOX_DIR" = "" ]; then
    ShowMessage "   Dropbox dir    = none"
  else
    ShowMessage "   Dropbox dir    = $DROPBOX_DIR"
  fi

  ShowMessage "   Push to phone  = $PUSH_TO_PHONE"
  ShowMessage "   Official build = $OFFICIAL"

  if [ $PROMPT -eq 999 ]; then
    ShowMessage ""
    ShowMessage "(Not building anything because PROMPT = ${PROMPT})"
  fi

else

  # CLEAN_ONLY is 1
  if [ "$DO_CM7" = "1" ]; then
    ShowMessage "   CM7 dir        = $CM7_DIR"
  fi
  if [ "$DO_CM9" = "1" ]; then
    ShowMessage "   CM9 dir        = $CM9_DIR"
  fi
  if [ "$DO_BLACKICE" = "1" ]; then
    ShowMessage "   BlackICE dir   = $BLACKICE_DIR"
  fi

  if [ "$CLEAN_TYPE" = "cm7" ]; then
    ShowMessage "   Clean          = CM7"
  fi
  if [ "$CLEAN_TYPE" = "cm9" ]; then
    ShowMessage "   Clean          = CM9"
  fi
  if [ "$CLEAN_TYPE" = "bi" ]; then
    ShowMessage "   Clean          = BlackICE"
  fi
  if [ "$CLEAN_TYPE" = "cm7bi" ]; then
    ShowMessage "   Clean          = CM7 + BlackICE"
  fi
  if [ "$CLEAN_TYPE" = "cm9bi" ]; then
    ShowMessage "   Clean          = CM9 + BlackICE"
  fi
fi
ShowMessage ""

# Return 0 for no error
return 0


