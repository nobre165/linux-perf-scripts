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
# Name: monitor_col_nmon.sh                                                 #
# Path: N/A                                                                 #
# Host(s): N/A                                                              #
# Info: Script to monitor performance data collection from host and GPFS    #
#                                                                           #
# Author: Anderson F Nobre                                                  #
# Creation date: 26/10/2016                                                 #
# Version: 1.0.3                                                            #
#                                                                           #
# Modification date: 22/12/2016                                             #
# Modified by: Anderson F. Nobre                                            #
# Modifications:                                                            #
# - Modifications to support new flags in gpfs_col_perf.bash script         #
#                                                                           #
# Modification date: 09/03/2020                                             #
# Modified by: Anderson F. Nobre                                            #
# Modifications:                                                            #
# - Modifications to support nmon                                           #
#                                                                           #
#############################################################################


#############################################################################
# Environment variables                                                     #
#############################################################################

COL_DIR=/var/perf/nmon
HOST=$(hostname)
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

    printf "Usage: %s \n" $0
    printf "       -s <sample>: duration in seconds of each data collection\n"
    printf "       -h|?: help\n"

}


#############################################################################
# Script main logic                                                         #
#############################################################################

sflag="0"
while getopts ":s:h" opt
do
    case $opt in
        s )
            sflag="1"
            SECS="$OPTARG"
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

PSCOUNT=$(ps -ef | grep -E "n[m]on -F" | wc -l)
if (($PSCOUNT == 0))
then
    if (($sflag == 0))
    then
        /usr/local/scripts/col_nmon.sh
    else
        /usr/local/scripts/col_nmon.sh -s ${SECS}
    fi
fi
