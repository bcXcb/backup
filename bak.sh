#!/usr/bin/env bash

# Backup in USB flash drives
# The script works fine in Debian Linux

# To improve
# - copy and compress files directly in USB flash drive
# - verify if the sound device is busy
# - the mount point must be a command line parameter
# - to create the function "check_dependences" for check and fix (if possible) the dependence problems
#

declare TEMP_DIR_NAME=$((RANDOM % 256)) # 0 to 255, an octect
declare TEMP_DIR=/home/gabriel/$TEMP_DIR_NAME
declare MOUNT_POINT=/media/gabriel
declare DESTINY=$MOUNT_POINT/backup
declare BACKUP_FILE=backup-`date +"%a"`.zip
declare device

function help {
	echo 'NAME'
    echo -e '\tbak - create backup of files and directories in usb flash drives'
	echo ''
	echo 'SYNOPSIS'
    echo -e '\tbak [OPTION]'
   	echo -e '\tbak [OPTION] [DEVICE]'
	echo ''
	echo 'DESCRIPTION'
    echo -e '\t-d, --device'
	echo -e '\t\tselect the device on which the backup will be performed'
    echo -e '\t-h, --help'
	echo -e '\t\tdisplay this help and exit'
    echo -e '\t-v, --version'
	echo -e '\t\toutput version information and exit'
	echo ''
	echo 'AUTHOR'
	echo -e '\tWritten by Gabriel Cavalcante de Jesus Oliveira.'
}

function version {
    echo 'bak v1.0'
	echo 'license: none - pubic domain'
    echo 'Written by: Gabriel C. de J. Oliveira'
}

function parameters {
    case $1 in
        '')
            help
            exit 1;;
        '-h'|'--help')
            help
            exit 0;;
        '-v'|'--version')
            version
            exit 0;;
        '-d'|'--device')
            if [ -n "$2" ]; then
                device=$2
            else
                help
                exit 1
            fi;;
        *)
            help
            exit 1
    esac
}

function mount_device {
    local status

    mountpoint -q $MOUNT_POINT
    status=$?

    if [ $status -eq 0 ]; then
        echo 'The USB flash drive already mounted.'
    else
        echo -n 'Mounting USB flash drive...'
        mount $device $MOUNT_POINT 2> /dev/null && echo ' [Success].' || echo ' [ Failure].'

		# bad implementation
        mountpoint -q $MOUNT_POINT
        status=$?

        if [ $status -ne 0 ]; then
            exit 1
        fi
    fi
}

function dismount_device {
    local status

    mountpoint -q $MOUNT_POINT
    status=$?

    if [ $status -eq 0 ]; then
        echo -n 'Dismounting USB flash drive...'
        umount $device 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
    fi
}

function create_dirs {
    mkdir -p $TEMP_DIR && echo "Was created the temporary directory \"$TEMP_DIR_NAME\"."

    if [ ! -e $DESTINY ]; then
        mkdir -p $DESTINY && echo "Was created the directory \"$DESTINY\"."
    fi
}

function backup {
    local i=0
    local items
    local ITEMS_LIST=/home/gabriel/files/projetos/github/bak/items.txt

	for item in `cat $ITEMS_LIST`; do
		if [ -e $item ]; then
            if [ -d $item -a `ls $item | wc -l` -gt 0 ]; then
                items[$((i++))]=$item
            fi

            if [ -f $item -a -s $item ]; then
                items[$((i++))]=$item
            fi
        fi
	done

	echo 'd - directory, f - file.'
    echo 'The following items were copied:'
    for item in ${items[*]}; do
        cp -rp $item $TEMP_DIR
        [[ -d $item ]] && echo "(d) $item." || echo "(f) $item."
    done

    echo 'Empty directories and files were not copied.'
}

function compress {
    echo -n 'Compressing items...'
    zip -rq0 $BACKUP_FILE $TEMP_DIR 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
}

function defragment {
    echo -n 'Defragmenting compressed file...'
    e4defrag -v $BACKUP_FILE > /dev/null 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
}

function move {
    echo -n 'Moving compressed file to the destiny...'
    mv -uf $BACKUP_FILE $DESTINY 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
}

function clean {
    rm -r $TEMP_DIR && echo 'Temporary directory was removed.'
}

function notification {
	local sound=/home/gabriel/files/projetos/github/bak/sound.wav
	aplay -q $sound & # run in background
}

parameters $*
echo 'Starting backup...'
mount_device
create_dirs
backup
compress
defragment
move
dismount_device
clean
echo 'Backup finished.'
notification
