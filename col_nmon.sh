#!/bin/bash

#set -x

# Copyright 2016 IBM Systems Lab Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#############################################################################
#                                                                           #
# Name: col_nmon.sh                                                         #
# Path: N/A                                                                 #
# Host(s): N/A                                                              #
# Info: Script to collect performance data from host                        #
#                                                                           #
# Author: Anderson F Nobre                                                  #
# Creation date: 26/10/2016                                                 #
# Version: 1.0.4                                                            #
#                                                                           #
# Modification date: 25/10/2017                                             #
# Modified by: Anderson F Nobre                                             #
# Modifications:                                                            #
# - Changing data collection options                                        #
#                                                                           #
# Modification date: 22/12/2016                                             #
# Modified by: Anderson F Nobre                                             #
# Modifications:                                                            #
# - Additional data collection                                              #
#                                                                           #
# Modification date: 09/03/2020                                             #
# Modified by: Anderson F Nobre                                             #
# Modifications:                                                            #
# - Changing data collection with nmon                                      #
#                                                                           #
#############################################################################


#############################################################################
# Environment variables                                                     #
#############################################################################

# Directory's data collection
COL_DIR=/var/perf/nmon
HOST=$(hostname)
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
NMONTXT=${HOST}_${DATE}_${TIME}.nmon

# Set default number of days to compress data
BDAYS="16"
DAYS="90"


#############################################################################
# Function definitions                                                      #
#############################################################################

#----------------------------------------------------------------------------
# Function: usage
#
# Arguments:
# - N/A
#
# Retun:
# - N/A

function usage {

cat <<EOF
    Usage: $0 [-s <sample>] [-c <count>] [-D <collect dir>] [-d <days>] [-b <days>]
           -s <sample>: duration in seconds of each data collection
           -c <count>: number of times to collect performance data
           -D <collect dir>: performance collection directory
                Default directory is ${COL_DIR}
           -d <days>: number of days to delete older nmon files
                Default number of days to delete older nmon files is ${DAYS}
           -b <days>: number of days to compress older nmon files
                Default number of days to compres older nmon files is ${BDAYS}
           -h|?: help
EOF

}

#----------------------------------------------------------------------------
# Function: get_remain_secs
#
# Arguments:
# - N/A
#
# Retun:
# - remain_secs Remain seconds from now till end of day

function get_remain_secs {

    echo $(($(date -d 23:59:59 +%s) - $(date +%s) + 1))

}


#############################################################################
# Script main logic                                                         #
#############################################################################

# Set default values for SECS and COUNT
SECS="60"
DIFF_SECS=$(get_remain_secs)
COUNT="$((${DIFF_SECS} / ${SECS}))"

# Set initial flag values
Dflag="0"
cflag="0"
dflag="0"
bflag="0"
sflag="0"

while getopts ":D:s:c:d:b:" opt
do
    case $opt in
        D )
            Dflag="1"
            COL_DIR="$OPTARG"
            ;;
        s )
            sflag="1"
            SECS="$OPTARG"
            ;;
        c )
            cflag="1"
            COUNT="$OPTARG"
            ;;
        d )
            dflag="1"
            DAYS="$OPTARG"
            ;;
        b )
            bflag="1"
            BDAYS="$OPTARG"
            ;;
        h|\? )
            usage
            exit 2
            ;;
        * )
            usage
            exit -1
            ;;
    esac
done

shift $((OPTIND - 1))

# If only the sample (SECS) is set, then recalculate the number of intervals
if (( $sflag == 1 && $cflag == 0 ))
then
    COUNT="$((${DIFF_SECS} / ${SECS}))"
fi

# Check if data collection directory exists, if not create it
if [[ ! -d ${COL_DIR} ]]
then
    mkdir -p ${COL_DIR}
    RC=$?
    if (( $RC != 0 ))
    then
        printf "Couldn't create directory %s!!!\n" ${COL_DIR}
        exit -1
    fi
fi

# Start data collection
if (( $dflag == 0 ))
then
    cd ${COL_DIR}
    RC=$?
    if (( $RC == 0 ))
    then
        nmon -F ${COL_DIR}/${NMONTXT} -s ${SECS} -c ${COUNT} -D -g auto -NTUx 
        find ${COL_DIR} -xdev -name \*.nmon -mtime +${BDAYS} -exec bzip2 {} \;
    else
        printf "Couldn\'t change to directory %s\n" ${COL_DIR}
    fi
else
# Purge oldest data collected
    cd ${COL_DIR}
    RC=$?
    if (( $RC == 0 ))
    then
        find ${COL_DIR} -xdev -name \*.bz2 -mtime +${DAYS} -exec rm {} \;
    else
        printf "Couldn\'t change to directory %s\n" ${COL_DIR}
    fi
fi
