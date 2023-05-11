#!/usr/bin/env bash

# Backup in USB flash drives
# The script works fine in Debian Linux

declare -r TEMP_DIR=/home/gabriel/$((RANDOM % 256)) # 0 to 255
declare -r MOUNTAGE_POINT=/media/gabriel
declare -r DEVICE=/dev/sdb
declare -r DESTINY=$MOUNTAGE_POINT/backup
declare -r BACKUP_FILE=backup-`date +"%a"`.zip
declare -a empty_items
declare -a non_empty_items
declare -i exit_status

parameters() {
    case $1 in
        '') : ;;
        '--version')
            version
            exit 0;;
        *)
            echo 'Invalid parameter!'
            exit 1
    esac
}

version() {
    echo 'bak v1.0'
    echo 'GPLv3+ License: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>'
    echo 'This is free software: you are free to change and redistribute it.'
    echo 'THERE IS NO WARRANTY, TO THE MAXIMUM EXTENT PERMITTED BY LAW.'
    echo ''
    echo 'Written by Gabriel Cavalcante de J. Oliveira.'
}

fill_arrays() {
    declare -i local i=0
    declare -i local j=0
    declare -a local items
    declare -r local ITEMS=/home/gabriel/files/projetos/github/bak/items.txt

	for item in `cat $ITEMS`; do
		items[$((i++))]=$item
	done

	i=0
	for item in ${items[*]}; do
		if [ -e $item ]; then
			[[ `ls $item | wc -l` -eq 0 ]] && empty_items[$i]=$item || non_empty_items[$j]=$item
		else
        	[[ -s $item ]] && non_empty_items[$j]=$item || empty_items[$i]=$item
		fi
		let i++ j++
	done
}

backup() {
    if [ -n "$non_empty_items" ]; then
        echo 'The following items was copied:'
        for item in ${non_empty_items[*]}; do
            cp -rp $item $TEMP_DIR
			[[ -d $item ]] && echo "(+) $item (dir)." || echo "(-) $item (file)."
        done
    fi

    if [ -z "$empty_items" ]; then
        echo 'The following items was ignored:'
        for item in ${empty_items[*]}; do
            [[ -d $item ]] && echo "(-) $item (dir) (empty)." || echo "(-) $item (file) (empty)."
        done
    fi
}

parameters $1

fill_arrays

echo 'Starting backup...'

mountpoint -q /media/gabriel
exit_status=$?

if [ $exit_status -eq 0 ]; then
	echo 'The USB flash drive already mounted.'
else
	echo 'Mounting the USB flash drive...'
	mount $DEVICE $MOUNTAGE_POINT && echo 'The USB flash drive was mounted.'
fi


mkdir -p $TEMP_DIR && echo "Was created the temporary directory \"$TEMP_DIR\"."

if [ ! -e $DESTINY ]; then
    mkdir -p $DESTINY && echo "Was created the directory \"$DESTINY\"."
fi

backup

echo 'Compressing items...'
# no compression (only store) is more fast
#zip -rq9 $BACKUP_FILE $TEMP_DIR && echo 'The items was compressed.'
zip -rq0 $BACKUP_FILE $TEMP_DIR && echo 'The items was compressed.'
mv $BACKUP_FILE $DESTINY && echo 'The compressed file was moved to the destiny.'

# it takes too long
#echo 'Umounting USB flash drive...'
#umount $DEVICE && echo 'The USB flash drive was umounted.'

rm -r $TEMP_DIR && echo 'The temporary directory was removed.'
echo 'Backup finished.'
