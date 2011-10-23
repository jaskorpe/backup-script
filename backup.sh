#!/bin/bash

# Copyright (C) 2011 Jon Anders Skorpen
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



# This script uses files in directory "targets" for host and directory
# information. It stores the backup in directory "storage".  The
# hostname is taken from the filename, and the "target files" must
# contain the directory that will be backed up. Use ** for wildcard.
#
# /home/jaskorpe/public_git/**
#
# The above line in a file called "targets/facies.mindmutation.net
# will back up everything in that directory on that host, recursively.

EMAILTO=root@mindmutation.net

backup_target ()
{
    target=$1
    /usr/bin/rdiff-backup --include-globbing-filelist=${target} --exclude '**' jaskorpe@${target##*/}::/ ${target%targets*}storage/${target##*/}/
    if [ $? -eq 0 ]; then
	echo "${target##*/} backed up" >> /var/log/backup
    else
	echo "Problem backing up ${target##*/}" >> /var/log/backup
	echo -ne "To: ${EMAILTO}\nFrom: ${USER}@${HOSTNAME}\nDate: $(date)\nSubject: Backup\nProblem backing up ${target##*/}\n" | sendmail -t
    fi
}

backup ()
{
    echo "Starting backup: $(date)" >> /var/log/backup
    for target in /home/backups/targets/*; do
	backup_target $target
    done
    echo "Nightly backup finished: $(date)" >> /var/log/backup
}

mirror ()
{
    RSYNC=/usr/bin/rsync
    REMOTE_DEST=/var/backups/jaskorpe/
    REMOTE_HOST=facies.mindmutation.net

    echo "Starting remote sync: $(date)" >> /var/log/backup
    for target in /home/backups/targets/*; do
	rsync -av --delete-after --rsh="ssh -l jaskorpe" storage/${target##*/} ${REMOTE_HOST}:${REMOTE_DEST}
	if [ $? -eq 0 ]; then
	    echo "${target##*/} synced" >> /var/log/backup
	else
	    echo "Problem syncing ${target##*/}" >> /var/log/backup
	    echo -ne "To: ${EMAILTO}\nFrom: ${USER}@${HOSTNAME}\nDate: $(date)\nSubject: Backup\nProblem syncing ${target##*/}\n" | sendmail -t
	fi
    done
    echo "Nightly remote sync finished: $(date)" >> /var/log/backup

}

case "$1" in
    "backup" )
	backup
	;;
    "mirror" )
	mirror
	;;
    * )
	backup
	mirror
	;;
esac