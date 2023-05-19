#!/usr/bin/env bash

# Backup of directories and files in flash drives
# The script works fine in Debian Linux

# To improve
# - create the function "check_dependences" for check and fix dependence problems

# Functions
# - help
# - version
# - parameters
# - flash_drive_is_busy
# - toggle_flash_drive_mount
# - create_dirs
# - backup
# - compress
# - clean
# - defragment
# - sound_device_is_busy
# - notification

declare flash_drive_path=
declare MOUNT_POINT_PATH=/media/gabriel
declare BACKUP_DIR_PATH=$MOUNT_POINT_PATH/backup
declare TEMP_DIR_NAME=$((RANDOM % 256)) # 0 to 255, an octect
declare TEMP_DIR_PATH=$BACKUP_DIR_PATH/$TEMP_DIR_NAME
declare BACKUP_FILE_NAME=`date +"%A"`.zip
declare BACKUP_FILE_PATH=$BACKUP_DIR_PATH/$BACKUP_FILE_NAME

function help {
	echo 'NAME'
    echo -e '\tbak - create backup of files and directories in flash drives'
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
        '-h' | '--help')
            help
            exit 0;;
        '-v' | '--version')
            version
            exit 0;;
        '-d' | '--device')
            if [ -n "$2" -a -e $2 ]; then
                flash_drive_path=$2
            else
                help
                exit 1
            fi;;
        *)
            help
            exit 1
    esac
}

function flash_drive_is_busy {
	fuser -s $flash_drive_path
	[[ $? -eq 0 ]] && echo 'True' || echo 'False'
}

# review this implementation
function toggle_flash_drive_mount {
	local action=$1

	if [ $action = '--mount' ]; then
    	mountpoint -q $MOUNT_POINT_PATH

	    if [ $? -eq 0 ]; then
    	    echo 'The flash drive already mounted.'
	    else
        	echo -n 'Mounting flash drive...'
    	    mount $flash_drive_path $MOUNT_POINT_PATH 2> /dev/null && echo ' [Success].' || echo ' [ Failure].'
	    fi
	else
    	mountpoint -q $MOUNT_POINT_PATH

	    if [ $? -ne 0 ]; then
    	    echo 'The flash drive already dismounted.'
	    else
        	echo -n 'Dismounting flash drive...'
    	    umount $flash_drive_path 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
	    fi
	fi
}

function create_dirs {
    if [ ! -e $BACKUP_DIR_PATH ]; then
        mkdir -p $BACKUP_DIR_PATH && echo "Was created the directory \"$BACKUP_DIR_PATH\"."
    fi

    mkdir -p $TEMP_DIR_PATH && echo "Was created the temporary directory \"$TEMP_DIR_NAME\"."
}

function backup {
    local i=0
    local items=
	local file_name='dirs-and-files.txt'
    local ITEMS_LIST=/home/gabriel/files/projetos/github/bak/$file_name

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
        cp -rp $item $TEMP_DIR_PATH
        [[ -d $item ]] && echo "(d) $item." || echo "(f) $item."
    done

    echo 'Empty directories and files were not copied.'
}

function compress {
    if [ -e $BACKUP_FILE_PATH ]; then
        rm -rf $BACKUP_FILE_PATH
    fi

    echo -n 'Compressing items...'
    zip -rq0 $BACKUP_FILE_PATH $TEMP_DIR_PATH 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
}

function clean {
    rm -r $TEMP_DIR_PATH && echo 'Temporary directory was removed.'
}

function defragment {
    echo -n 'Defragmenting compressed file...'
    e4defrag -v $BACKUP_FILE_PATH > /dev/null 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
}

function sound_device_is_busy {
    local sound_device=/dev/snd/pcmC0D0p # default sound output device
	fuser -s $sound_device
	[[ $? -eq 0 ]] && echo 'True' || echo 'False'
}

function notification {
	local file_name='sound.wav'
	local sound_path=/home/gabriel/files/projetos/github/bak/$file_name

    # verify if any process is using the device, returning "True" at positive case
	if [ `sound_device_is_busy` = 'False' ]; then
		aplay -q $sound_path & # this process run in background
	fi
}

parameters $*
if [ `flash_drive_is_busy` = 'True' ]; then
    echo 'The flash drive is busy.'
    echo -n 'Waiting...'
    while [ `flash_drive_is_busy` = 'True' ]; do
        : # nothing
    done
fi
echo ''
echo 'Starting backup...'
toggle_flash_drive_mount --mount
create_dirs
backup
compress
clean
defragment
toggle_flash_drive_mount --dismount
echo 'Backup finished.'
notification
