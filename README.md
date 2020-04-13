# linux-perf-scripts

## A. Summary

A collection of scripts to collect performance data for further analysis

## B. Dependencies

If you are going to collect performance data with dstat, you need install it
first:

- For RHEL/CentOS, install with yum:
  yum install dstat

- For SLES, install with zypper:
  zypper install dstat

- For Ubuntu, install with apt-get:
  sudo apt install dstat


If you are going to collect performance data with nmon, you need install it
first:

- For RHEL/CentOS, first add EPEL repository. See the following link for
  additional instructions:
  https://www.tecmint.com/install-epel-repository-on-centos/

  Then, install with yum:
  yum install nmon

- For SLES, install with zypper:
  zypper install nmon

- For Ubuntu, install with apt-get:
  sudo apt install nmon

If you are going to collect performance data from Spectrum Scale (formerly
GPFS), it's suposed that the cluster is running. It uses dstat and 
dstat_gpfsops.py module.

## C. Supported Systems

In theory, any Linux. In practice, I only tested on RHEL 7.x environments

## Installation

The scripts always work in pairs, the 'col_*.sh' that collects the data. And
monitor_col_* that is scheduled in crontab every 10 minutes, checks if col_*.sh
is running. If not, runs again. So, to install follow the steps described
below.

- Create a directory /usr/local/scripts and copy the scripts to this directory:
  mkdir /usr/local/scripts

- Change the permissions to 755
  cd /usr/local/scripts
  chmod 755 *.sh

- Add the following line in the crontab, according your monitoring:
  - For dstat
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_dstat.sh >
  /var/log/monitor_col_dstat.log 2>&1

  - For gpfs_stats:
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_gpfs_mmdiag--stats.sh
  > /var/log/monitor_col_gpfs_mmdiag--stats.log 2>&1

  - For gpfs_waiters:
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_waiters.sh >
  /var/log/monitor_col_waiters.log 2>&1

  - For iostat:
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_iostat.sh >
  /var/log/monitor_col_iostat.log 2>&1

  - For nmon:
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_nmon.sh >
  /var/log/monitor_col_nmon.log 2>&1

  - For gpfs_perf:
  0,10,20,30,40,50 * * * * /usr/local/scripts/monitor_col_gpfs_perf.sh >
  /var/log/monitor_col_gpfs_perf.log 2>&1


## Notes

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
