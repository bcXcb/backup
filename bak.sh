#!/usr/bin/env bash
# Backup in USB flash drives

declare -r TEMP_DIR=/home/gabriel/$((RANDOM % 256)) # 0 to 255
declare -r MOUNTAGE_POINT=/media/gabriel
declare -r DEVICE=/dev/sdb1
declare -r DESTINY=$MOUNTAGE_POINT/backup
declare -r BACKUP_FILE=backup-`date +"%a"`.zip
declare -a empty_items
declare -a non_empty_items

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
    echo 'bak 1.0'
    echo 'GPLv3+ License: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>'
    echo 'This is free software: you are free to change and redistribute it.'
    echo 'THERE IS NO WARRANTY, TO THE MAXIMUM EXTENT PERMITTED BY LAW.'
    echo ''
    echo 'Written by Gabriel Cavalcante de J. Oliveira.'
}

fill_arrays() {
    declare -i local i
    declare -i local j
    declare -a local items
    declare -r local ITEMS=/home/gabriel/files/projetos/github/bak/items.txt
    
	i=0
	for item in `cat $ITEMS`; do
		items[$((i++))]=$item
	done

	i=0
	j=0
	for item in ${items[*]}; do
		if [ -e $item ]; then
			[[ `ls $item | wc -l` -eq 0 ]] && empty_items[$i]=$item || non_empty_items[$j]=$item
		else
        	[[ -s $item ]] && non_empty_items[$j]=$item || empty_items[$i]=$item
		fi
		((i++))
		((j++))
	done
}

backup() {
    if [ -n "$non_empty_items" ]; then
        echo "The following items was copied:"
        for item in ${non_empty_items[*]}; do
            cp -rp $item $TEMP_DIR
            if [ -d $item ]; then
                echo "(+) $item. (dir)"
            else
                echo "(+) $item. (file)"
            fi
        done
    fi

    if [ -z "$empty_items" ]; then
        echo "The following items was ignored:"
        for item in ${empty_items[*]}; do
            if [ -d $item ]; then
                echo "(-) $item. (dir) (empty)"
            else
                echo "(-) $item. (file) (empty)"
            fi
        done
    fi
}

clear

parameters $1

fill_arrays

echo "Starting backup..."

mount $DEVICE $MOUNTAGE_POINT
echo "The USB flash drive was mounted."

mkdir -p $TEMP_DIR
echo "Was created the temporary directory \"$TEMP_DIR\"."

if [ ! -d $DESTINY ]; then
    mkdir -p $DESTINY
    echo "Was created the directory \"$DESTINY\"."
fi

backup

echo "Compressing items..."
zip -rq9 $BACKUP_FILE $TEMP_DIR
echo "The items was compressed."
mv $BACKUP_FILE $DESTINY
echo "The compressed file was moved to the destiny."

echo "Umounting USB flash drive..."
umount $DEVICE
echo "The USB flash drive was umounted."

rm -r $TEMP_DIR
echo "The temporary directory was removed."
echo "Finished."
