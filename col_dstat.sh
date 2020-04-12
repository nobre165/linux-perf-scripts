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
# Name: col_dstat.sh                                                        #
# Path: N/A                                                                 #
# Host(s): N/A                                                              #
# Info: Script to collect performance data from host and GPFS               #
#                                                                           #
# Author: Anderson F Nobre                                                  #
# Creation date: 26/10/2016                                                 #
# Version: 0.3                                                              #
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
#############################################################################


#############################################################################
# Environment variables                                                     #
#############################################################################

# Directory's data collection
COL_DIR=/var/perf/dstat
HOST=$(hostname)
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
DSTTXT=dstat_${HOST}_${DATE}_${TIME}.dst

# A list of dstat long to short options
declare -A DSTAT_LTS_OPTIONS=([cpu]=c [disk]=d [page]=g [int]=i [load]=l [mem]=m [net]=n [proc]=p [io]=r [swap]=s [sys]=s)

# A list of dstat short to long options
declare -A DSTAT_STL_OPTIONS=([c]=cpu [d]=disk [g]=page [i]=int [l]=load [m]=mem [n]=net [p]=proc [r]=io [s]=swap [s]=sys)

# Dstat short options to be used for data collection
SCRIPT_OPT_SHORT="f,i,l,m,p,s"

# Dstat long options to be used for data collection
SCRIPT_OPT_LONG="aio,ipc,lock,socket,tcp,udp,unix,vm,nfs3,nfs3-ops,nfs3d,nfsd3-ops,proc-count,rpc,rpcd,gpfs,gpfs-ops,top-bio,top-cpu,top-cputime,top-cputime-avg,top-io,top-latency,top-latency-avg,top-mem"

# Dstat short options that effectivelly will be used
declare -a OPTSHORT
declare -a OPTLONG


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
           -b <days>: number of days to compress older nmon files
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
    if (( $RC != 0 ))
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

#----------------------------------------------------------------------------
# Function: check_dstat_counter_options
#
# Arguments:
# - N/A
#
# Return:
# - N/A

function check_dstat_counter_options {

        declare -a DSTAT_LIST_SHORT
        declare -a DSTAT_LIST_LONG
        declare -a TMP_OPT_SHORT

        # For the short options...
        # collect dstat's available options
        DSTAT_LIST_SHORT=$(dstat --list | awk '/^internal:/{flag=1;next}/\/usr\/share\/dstat:/{flag=0}flag' | tr '\n' ' ' | tr ',' ' ')

        # convert script's short options to long
        for shortopt in $(echo ${SCRIPT_OPT_SHORT} | tr ',' '\n' | sort -u)
        do
            if [[ ! -z ${DSTAT_STL_OPTIONS[$shortopt]} ]]
            then
                TMP_OPT_SHORT+=(${DSTAT_STL_OPTIONS[$shortopt]})
            fi
        done

        # compare script's options with the available options and alert which of
        # them won't be used
        SHORT_OPT_FIRST=$(comm -23 <(echo ${TMP_OPT_SHORT[@]} | tr ' ' '\n' | sort -u) <(echo ${DSTAT_LIST_SHORT[@]} | tr ' ' '\n' | sort -u))
        SHORT_OPT_COMMON=$(comm -12 <(echo ${TMP_OPT_SHORT[@]} | tr ' ' '\n' | sort -u) <(echo ${DSTAT_LIST_SHORT[@]} | tr ' ' '\n' | sort -u))
        if [[ ! -z ${SHORT_OPT_FIRST} ]]
        then
            printf "The following short options won\'t be collected:"
            for i in $(echo ${SHORT_OPT_FIRST})
            do
                printf " -%s" ${DSTAT_LTS_OPTIONS[$i]}
            done
            printf "\n\n"
        fi

        # list the common options between dstat's options from script and available
        for i in $(echo ${SHORT_OPT_COMMON})
        do
            OPTSHORT+=('-'${DSTAT_LTS_OPTIONS[$i]})
        done

        # For the long options...
        # collect dstat's available options
        DSTAT_LIST_LONG=$(dstat --list | awk '/^\/usr\/share\/dstat:/{flag=1;next}flag' | tr '\n' ' ' | tr ',' ' ')

        # compare script's options with the available options and alert which of
        # them won't be used
        LONG_OPT_FIRST=$(comm -23 <(echo ${SCRIPT_OPT_LONG} | tr ',' '\n' | sort -u) <(echo ${DSTAT_LIST_LONG[@]} | tr ' ' '\n' | sort -u))
        LONG_OPT_COMMON=$(comm -12 <(echo ${SCRIPT_OPT_LONG} | tr ',' '\n' | sort -u) <(echo ${DSTAT_LIST_LONG[@]} | tr ' ' '\n' | sort -u))
        if [[ ! -z ${LONG_OPT_FIRST} ]]
        then
            printf "The following long options won't be collected:"
            for i in $(echo ${LONG_OPT_FIRST})
            do
                printf " --%s" $i
            done
            printf "\n\n"
        fi

        # list the common options between dstat's options from script and available
        for i in $(echo ${LONG_OPT_COMMON})
        do
            OPTLONG+=('--'$i)
        done

}

#############################################################################
# Script main logic                                                         #
#############################################################################

# Set default number of days to compress data
BDAYS="3"
DAYS="90"

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

# Check if dstat command exists
check_dstat

# Check if GPFS dstat extension is on a node
check_gpfs_extension

# Check if all counter options are available in the dstat command
check_dstat_counter_options

# Start data collection
if (( $dflag == 0 ))
then
    cd ${COL_DIR}
    RC=$?
    if (( $RC == 0 ))
    then
        #DSTAT_GPFS_WHAT=all dstat -t -afv ${OPTSHORT[@]} ${OPTLONG[@]} --nocolor --output ${COL_DIR}/${DSTTXT} ${SECS} ${COUNT}
        DSTAT_GPFS_WHAT=all dstat -t -cdfgilmnprsy -M gpfs --aio --fs --ipc --lock --raw --socket --tcp --udp --unix --vm --nfs3 --nfs3-ops --nfsd3-ops --proc-count --rpc --rpcd --top-bio --top-cpu --top-cputime --top-cputime-avg --top-io --top-latency --top-latency-avg --top-mem --nocolor --output ${COL_DIR}/${DSTTXT} ${SECS} ${COUNT}
        find ${COL_DIR} -xdev -name \*.dst -mtime +${BDAYS} -exec bzip2 {} \;
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
