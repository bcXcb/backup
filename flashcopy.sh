#!/usr/bin/env bash

# Backup of directories and files in flash drives
# The script works fine in Debian Linux

declare flash_drive_path=
declare MOUNT_POINT_PATH=/media/gabriel
declare BACKUP_DIR_PATH=$MOUNT_POINT_PATH/backup
declare TEMP_DIR_NAME=$((RANDOM % 256)) # 0 to 255
declare TEMP_DIR_PATH=$BACKUP_DIR_PATH/$TEMP_DIR_NAME
declare BACKUP_FILE_NAME=`date +"%A"`.zip
declare BACKUP_FILE_PATH=$BACKUP_DIR_PATH/$BACKUP_FILE_NAME

function help {
	echo 'NAME'
	echo -e '\tflashcopy - create backup of files and directories in flash drives'
	echo ''
	echo 'SYNOPSIS'
	echo -e '\tflashcopy [OPTION]'
   	echo -e '\tflashcopy [OPTION] [DEVICE]'
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
    echo 'flashcopy v1.0'
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

function device_is_busy {
    local device_path=$1
    fuser -s $device_path
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

function check_dependences {
    # check if necessary programs are available
    local programs=(zip e4defrag fuser mountpoint aplay)
    local COMMAND_NOT_FOUND=127
    local flag='False'

    echo -n 'Checking dependences...'
    echo ''

    for program in ${programs[*]}; do
        # "> /dev/null 2>&1": redirect the standard output and standard error output to the null device
        command -v $program > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: the program \"$program\" is not available."
            flag='True'
        fi
    done

    if [ $flag = 'True' ]; then
        exit 1
    fi

    # verifies that the backup directory exists and is writable
    if [ ! -d $BACKUP_DIR_PATH ]; then
        mkdir -p $BACKUP_DIR_PATH
        if [ $? -ne 0 ]; then
            echo 'Was not possible create the backup directory.'
            exit 1
        fi
    else
        if [ ! -w $BACKUP_DIR_PATH ]; then
            chmod +w $BACKUP_DIR_PATH
            if [ $? -ne 0 ]; then
                echo 'The backup directory is not writable.'
                echo 'Was not possible to make the backup directory writable.'
                exit 1
            fi
        fi
    fi

    # Check if the temporary directory can be created.
    mkdir -p $TEMP_DIR_PATH && echo "Was created the temporary directory \"$TEMP_DIR_NAME\"."
    if [ $? -ne 0 ]; then
        echo "Error: unable to create temporary directory \"$TEMP_DIR_PATH\"."
        exit 1
    fi
}

function backup {
    local i=0
    local items=
    local non_empty_items_total=0
    local empty_items_total=0
    local file_name='items-for-backup.txt' # text file containing path of directories and files to backup
    local ITEMS_LIST=/home/gabriel/arquivos/github/flashcopy/$file_name

	for item in `cat $ITEMS_LIST`; do
		if [ -e $item ]; then
            		if [ -d $item -a `ls $item | wc -l` -gt 0 ]; then
	                	items[$((i++))]=$item
			fi

	            	if [ -f $item -a -s $item ]; then
        	        	items[$((i++))]=$item
			fi
			((non_empty_items_total++))
		else
			((empty_items_total++))
        	fi
	done

	echo 'd - directory, f - file.'
    echo 'The following items were copied:'
    for item in ${items[*]}; do
        cp -r --no-preserve=ownership $item $TEMP_DIR_PATH
        [[ -d $item ]] && echo "(d) $item." || echo "(f) $item."
    done

    echo "$non_empty_items_total directories and files were copied."
    echo "$empty_items_total empty or nonexistent directories and files were ignored."
}

# compression with exclusion
function compression_with_exclusion {
    if [ -e $BACKUP_FILE_PATH ]; then
        rm -rf $BACKUP_FILE_PATH
    fi

    # zip -9: maximum level of compression
    # zip -0: no compression, only store
    echo -n 'Compressing items...'
    zip -rq9 $BACKUP_FILE_PATH $TEMP_DIR_PATH 2> /dev/null && echo ' [Success].' || echo ' [Failure].'

    # remove the temporary directory
    echo -n 'Removing the temporary directory...'
    rm -r $TEMP_DIR_PATH && echo ' [ Success].' || echo ' [Failure].'
}

# note: normally, flash memory devices are formatted with fat32 or exFAT file
# systems, therefore, specific tools must be used to defragment these file
# systems. "e4defrag" is a tool for ext4 file system defragmentation.
function defragment {
    echo -n 'Defragmenting compressed file...'
    e4defrag -v $BACKUP_FILE_PATH > /dev/null 2>&1 && echo ' [Success].' || echo ' [Failure].'
}

function notification {
	local file_name='notification.wav'
	local sound_path=/home/gabriel/arquivos/github/flashcopy/$file_name
	local sound_device_path=/dev/snd/pcmC0D0p # default sound output device

    # verify if any process is using the device, returning "True" at positive case
	if [ `device_is_busy $sound_device_path` = 'False' ]; then
		aplay -q $sound_path & # this process run in background
	fi
}

parameters $*
# checks if the pendrive is busy, waiting for it to be idle
if [ `device_is_busy $flash_drive_path` = 'True' ]; then
    echo 'The flash drive is busy.'
    echo -n 'Waiting...'
    while [ `device_is_busy $flash_drive_path` = 'True' ]; do
		sleep 1 # avoidance of unnecessary processing
    done
	echo ''
fi
echo 'Starting backup...'
toggle_flash_drive_mount --mount
check_dependences
backup
compression_with_exclusion
#defragment
toggle_flash_drive_mount --dismount
echo 'Backup finished.'
notification
