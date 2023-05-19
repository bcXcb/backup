#!/usr/bin/env bash

# Backup in flash drives
# The script works fine in Debian Linux

# To improve
# - copy and compress files directly in flash drives
# - the mount point must be a command line parameter
# - to create the function "check_dependences" for check and fix (if possible) the dependence problems
#

declare TEMP_DIR_NAME=$((RANDOM % 256)) # 0 to 255, an octect
declare TEMP_DIR=/home/gabriel/$TEMP_DIR_NAME
declare MOUNT_POINT=/media/gabriel
declare DESTINY=$MOUNT_POINT/backup
declare BACKUP_FILE=`date +"%A"`.zip
declare device

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


# review the implementation
function toggle_flash_drive_mount {
	local action=$1

	if [ $action = '--mount' ]; then
    	mountpoint -q $MOUNT_POINT

	    if [ $? -eq 0 ]; then
    	    echo 'The flash drive already mounted.'
	    else
        	echo -n 'Mounting flash drive...'
    	    mount $device $MOUNT_POINT 2> /dev/null && echo ' [Success].' || echo ' [ Failure].'
	    fi
	else
    	mountpoint -q $MOUNT_POINT

	    if [ $? -ne 0 ]; then
    	    echo 'The flash drive already dismounted.'
	    else
        	echo -n 'Dismounting flash drive...'
    	    umount $device 2> /dev/null && echo ' [Success].' || echo ' [Failure].'
	    fi
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

function sound_device_is_busy {
    local sound_device=/dev/snd/pcmC0D0p # default sound output device

	fuser -s $sound_device

	[[ $? -eq 0 ]] && echo 'True' || echo 'False'
}

function notification {
	local is_busy
	local file_name='sound.wav'
	local sound=/home/gabriel/files/projetos/github/bak/$file_name

	is_busy=`sound_device_is_busy` # verify if any process is using the device, returning "True" at positive case

	if [ $is_busy = 'False' ]; then
		aplay -q $sound & # this process run in background
	fi
}

parameters $*
echo 'Starting backup...'
toggle_flash_drive_mount --mount
create_dirs
backup
compress
defragment
move
toggle_flash_drive_mount --dismount
clean
echo 'Backup finished.'
notification
