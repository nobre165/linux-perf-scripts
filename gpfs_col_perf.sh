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
# Name: gpfs_col_perf.sh                                                    #
# Path: N/A                                                                 #
# Host(s): N/A                                                              #
# Info: Script to collect performance data from host and GPFS               #
#                                                                           #
# Author: Anderson F Nobre                                                  #
# Creation date: 26/10/2016                                                 #
# Version: 0.1                                                              #
#                                                                           #
# Modification date: DD/MM/YYYY                                             #
# Modified by: XXXXXXXXXXXXXXXX                                             #
# Modifications:                                                            #
# - XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             #
#                                                                           #
#############################################################################


#############################################################################
# Environment variables                                                     #
#############################################################################

COL_DIR=/var/perf/dstat
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")


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
    Usage: $0 [-s <sample>] [-c <count>] [-D <collect dir>] [-d <days>]
           -s <sample>: duration in seconds of each data collection
           -c <count>: number of times to collect performance data
           -D <collect dir>: performance collection directory
                Default directory is ${COL_DIR}
           -d <days>: number of days to compress older nmon files
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

#----------------------------------------------------------------------------
# Function: check_dstat
# 
# Arguments:
# - N/A
# 
# Retun:
# - N/A

function check_dstat {
    
    type dstat
    RC=$?
    if (( $RC != 0))
    then
        printf "dstat command not installed!!!\n"
        exit -1
    fi
    
}

#----------------------------------------------------------------------------
# Function: check_gpfs_extension
# 
# Arguments:
# - N/A
# 
# Retun:
# - N/A

function check_gpfs_extension {
    
    if [[ ! -f /usr/lpp/mmfs/samples/util/dstat_gpfsops.py.dstat.0.7 && \
          ! -f /usr/share/dstat/dstat_gpfsops.py ]]
    then
        printf "There\'s no GPFS plugin available in nether directory!!!\n"
        exit 1
    fi
    
    if [[ ! -f /usr/lpp/mmfs/samples/util/dstat_gpfsops.py.dstat.0.7 ]]
    then
        printf "GPFS dstat extension not available in GPFS samples!!!\n"
    else
        if [[ ! -f /usr/share/dstat/dstat_gpfsops.py ]]
        then
            cp /usr/lpp/mmfs/samples/util/dstat_gpfsops.py.dstat.0.7 /usr/share/dstat/dstat_gpfsops.py
            chmod 644 /usr/share/dstat/dstat_gpfsops.py
        fi
    fi
    
}


#############################################################################
# Script main logic                                                         #
#############################################################################


# Set default values for SECS and COUNT
SECS="60"
DIFF_SECS=$(get_remain_secs)
COUNT="$((${DIFF_SECS} / ${SECS}))"
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

# Check if dstat command exists
check_dstat

# Check if GPFS dstat extension is on a node
check_gpfs_extension

# Start data collection
if (( $dflag == 0 ))
then
    cd ${COL_DIR}
    RC=$?
    if (( $RC == 0 ))
    then
        DSTAT_GPFS_WHAT=all dstat -afv --gpfs --gpfs-ops --nocolor --output ${COL_DIR}/$(hostname)_${DATE}_${TIME}.dst ${SECS} ${COUNT}
        find ${COL_DIR} -xdev -name \*.dst -mtime +${BDAYS} -exec bzip2 {} \;
    else
        printf "Couldn't change to directory %s\n" ${COL_DIR}
    fi
else
# Purge oldest data collected
    cd ${COL_DIR}
    RC=$?
    if (( $RC == 0 ))
    then
        find ${COL_DIR} -xdev -name \*.dst -mtime +${DAYS} -exec bzip2 {} \;
    else
        printf "Couldn't change to directory %s\n" ${COL_DIR}
    fi
fi
