#!/bin/bash

# This script was generated with the help of ChatGPT, Feb 13 Version. 

# **** This script must be installed manually! ****
# It is included in this repo for record-keeping, but has no one-liner
# to automatically set this up. Please see the README for info.

# This is the conduit through which NUT notifications are handled and
# acted on.
# https://networkupstools.org/docs/user-manual.chunked/ar01s07.html
#
# In short, however, this script will define a series of functions.
# When this script is called by NUT [see README], it will run with an
# environment variable ${NOTIFYTYPE}, which will be a string such as
# "ONLINE", "ONBATT", "LOWBATT". Depending on this value, actions will
# be taken to shut down machines or make a beeping sound (the UPS this
# script was originally intended to manage made such an insufferable
# beep that I turned it off in place of the server's MoBo beeper.)
# --------------------

# explicit PATH, and umask (though unused)
export PATH=/usr/bin:/bin/:/usr/sbin:/sbin
umask 2

# Start logging things, put both STDERR and STDOUT into said log.
ME=$(basename "$0")
exec 3>&2 >> /opt/log/${ME}.log 2>&1
# sets:
# - errexit: exit if simple command fails (nonzero return value)
# - nounset: write message to stderr if trying to expand unset variable
# - verbose: Write input to standard error as it is read.
# - xtrace : Write to stderr trace for each command after expansion.
set -euvx
uname -a
date

failure () { echo FAILED. >&3; exit 1; }
trap failure EXIT

# Check that NOTIFYTYPE environment variable is set
if [ -z "${NOTIFYTYPE}" ]; then
  echo "Error: NOTIFYTYPE environment variable is not set."
  exit 1
fi

# Define function for printing event information
function print_event_info {
  echo "UPS event      : ${NOTIFYTYPE}"
  echo "UPS name       : ${UPSNAME}"
  echo "UPS status     : ${UPSSTATUS}"
  echo "Battery charge : ${BCHARGE}%"
  echo "Time left      : ${TIMELEFT}"
  echo "Load           : ${LOAD}"
}

# Define functions for each NOTIFYTYPE value
event_ONLINE () {
  print_event_info
  # Add any additional commands to run when the UPS goes online
}

event_ONBATT () {
  print_event_info
  # Add any additional commands to run when the UPS goes on battery
}

event_LOWBATT () {
  print_event_info
  # Add any additional commands to run when the UPS battery is low
}

event_FSD () {
  print_event_info
  # Add any additional commands to run when a forced shutdown is initiated
}

event_COMMOK () {
  print_event_info
  # Add any additional commands to run when communication with the UPS is restored
}

event_COMMBAD () {
  print_event_info
  # Add any additional commands to run when communication with the UPS is lost
}

event_SHUTDOWN () {
  print_event_info
  # Add any additional commands to run when the UPS initiates a shutdown
}

# Check the value of NOTIFYTYPE and perform appropriate action
case ${NOTIFYTYPE} in
  "ONLINE")
    event_ONLINE
    ;;
  "ONBATT")
    event_ONBATT
    ;;
  "LOWBATT")
    event_LOWBATT
    ;;
  "FSD")
    event_FSD
    ;;
  "COMMOK")
    event_COMMOK
    ;;
  "COMMBAD")
    event_COMMBAD
    ;;
  "SHUTDOWN")
    event_SHUTDOWN
    ;;
  *)
    echo "Error: Unrecognized NOTIFYTYPE value: ${NOTIFYTYPE}"
    exit 1
    ;;
esac

trap - EXIT
exit 0
