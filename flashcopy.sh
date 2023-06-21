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

function set_font_color {
	color=$1
	case $color in
		'default') echo -en '\e[0m';;
		'gray')    echo -en '\e[30;1m';;
		'red')     echo -en '\e[31;1m';;
		'green')   echo -en '\e[32;1m';;
		'yellow')  echo -en '\e[33;1m';;
		'blue')    echo -en '\e[34;1m';;
		'magenta') echo -en '\e[35;1m';;
		'cyan')    echo -en '\e[36;1m';;
		'white')   echo -en '\e[37;1m'
	esac
}

function show_help {
	local FILE_PATH=/home/gabriel/arquivos/projetos/github/flashcopy/txt/help.txt
    cat $FILE_PATH
}

function show_version {
    local FILE_PATH=/home/gabriel/arquivos/projetos/github/flashcopy/txt/version.txt
    cat $FILE_PATH
}

function parameters {
    case $1 in
        '')
            show_help
            exit 1;;
        '-h' | '--help')
            show_help
            exit 0;;
        '-v' | '--version')
            show_version
            exit 0;;
        '-d' | '--device')
            if [ -n "$2" -a -e $2 ]; then
                flash_drive_path=$2
            else
                show_help
                exit 1
            fi;;
        *)
            show_help
            exit 1
    esac
}

function device_is_busy {
    local device_path=$1
    fuser -s $device_path
    [[ $? -eq 0 ]] && echo 'True' || echo 'False'
}

function toggle_flash_drive_mount {
	local action=$1

    set_font_color 'magenta'
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
    set_font_color 'default'
}

function check_dependences {
    # check if necessary programs are available
    local programs=(zip fuser mountpoint aplay)
    local COMMAND_NOT_FOUND=127
    local flag='False'

    set_font_color 'magenta'
    echo 'Checking dependences...'

    for program in ${programs[*]}; do
        # "> /dev/null 2>&1": redirect the standard output and standard error output to the null device
        command -v $program > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: is necessary the program \"$program\"."
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
    set_font_color 'default'
}

function backup {
    local i=0
    local non_exist=0
    local empty_dirs=0
    local empty_files=0
    local non_empty_dirs=0
    local non_empty_files=0
    local file_name='items-for-backup.txt'
    local ITEMS_LIST=/home/gabriel/arquivos/projetos/github/flashcopy/txt/$file_name
    local bar=()
    local foo=()

    set_font_color 'magenta'
    echo 'Copying...'
	echo 'd - directory, f - file.'

    set_font_color 'blue'
	for item in `cat $ITEMS_LIST`; do
        if [ -e $item ]; then
            if [ -d $item ]; then
                if [ `ls $item | wc -l` -gt 0 ]; then
                    cp -r --no-preserve=ownership $item $TEMP_DIR_PATH
                    echo "(d) $item."
                    ((non_empty_dirs++))
                else
                    ((empty_dirs++))
                fi
            else
                if [ -s $item ]; then
                    cp --no-preserve=ownership $item $TEMP_DIR_PATH
                    echo "(f) $item."
                    ((non_empty_files++))
                else
                    ((empty_files++))
                fi
            fi
        else
            ((non_exist++))
        fi
    done

    foo=($non_exist $empty_files $empty_dirs $non_empty_files $non_empty_dirs)
    bar=('missing items' 'empty files' 'empty directories' 'files copied' 'directories copied')

    set_font_color 'yellow'
    for foobar in ${foo[*]}; do
        if [ $foobar -gt 0 ]; then
            echo "$foobar ${bar[$i]}."
        fi
        ((i++))
    done
    set_font_color 'default'
}

# compression with exclusion
function compression_with_exclusion {
    if [ -e $BACKUP_FILE_PATH ]; then
        rm -rf $BACKUP_FILE_PATH
    fi

    set_font_color 'magenta'

    # zip -9: maximum level of compression
    # zip -0: no compression, only store
    echo -n 'Compressing items...'
    zip -rq9 $BACKUP_FILE_PATH $TEMP_DIR_PATH 2> /dev/null && echo ' [Success].' || echo ' [Failure].'

    # remove the temporary directory
    echo -n 'Removing the temporary directory...'
    rm -r $TEMP_DIR_PATH && echo ' [ Success].' || echo ' [Failure].'

    set_font_color 'default'
}

function notification {
	local file_name='backup-finished.wav'
	local sound_path=/home/gabriel/arquivos/projetos/github/flashcopy/sound/$file_name
	local sound_device_path=/dev/snd/pcmC0D0p # default sound output device

    # verify if any process is using the device, returning "True" at positive case
	if [ `device_is_busy $sound_device_path` = 'False' ]; then
		aplay -q $sound_path & # this process run in background
	fi
}

parameters $*
set_font_color 'magenta'
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
toggle_flash_drive_mount --dismount
set_font_color 'magenta'
echo 'Backup finished.'
set_font_color 'default'
notification
