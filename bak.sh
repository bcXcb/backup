#!/usr/bin/env bash

# Backup in USB flash drives
# The script works fine in Debian Linux

declare -r TEMP_DIR=/home/gabriel/$((RANDOM % 256)) # 0 to 255
declare -r MOUNT_POINT=/media/gabriel
declare -r DEVICE=/dev/sdb1
declare -r DESTINY=$MOUNT_POINT/backup
declare -r BACKUP_FILE=backup-`date +"%a"`.zip
declare -i exit_status

fill_arrays() {
    declare -i local i=0
    declare -i local j=0
    declare -r local ITEMS_LIST=/home/gabriel/files/projetos/github/bak/items.txt

	for item in `cat $ITEMS_LIST`; do
		if [ -d $item ]; then
			[[ `ls $item | wc -l` -eq 0 ]] && empty_items[$i]=$item || non_empty_items[$j]=$item
		else
        	[[ -s $item ]] && non_empty_items[$j]=$item || empty_items[$i]=$item
		fi
		let i++ j++
	done
}

backup() {
	declare -a empty_items
	declare -a non_empty_items

	fill_arrays

	echo 'd - directory, f - file.'
    if [ -n "$non_empty_items" ]; then
        echo 'The following items was copied:'
        for item in ${non_empty_items[*]}; do
            cp -rp $item $TEMP_DIR
			[[ -d $item ]] && echo "(d) $item." || echo "(f) $item."
        done
    fi

    if [ ! -n "$empty_items" ]; then
        echo 'The following items was ignored (empty):'
        for item in ${empty_items[*]}; do
            [[ -d $item ]] && echo "(d) $item." || echo "(f) $item."
        done
    fi
}

echo 'Starting backup...'

mountpoint -q $MOUNT_POINT
exit_status=$?

if [ $exit_status -eq 0 ]; then
	echo 'The USB flash drive already mounted.'
else
	mount $DEVICE $MOUNT_POINT && echo 'The USB flash drive was mounted.'
fi

mkdir -p $TEMP_DIR && echo "Was created the temporary directory \"$TEMP_DIR\"."

if [ ! -e $DESTINY ]; then
    mkdir -p $DESTINY && echo "Was created the directory \"$DESTINY\"."
fi

backup

echo 'Compressing items...'
zip -rq0 $BACKUP_FILE $TEMP_DIR && echo 'Success.'
echo 'Defragmenting compressed file...'
e4defrag -v $BACKUP_FILE > /dev/null && echo 'Success.'
echo 'Moving the compressed file to the destiny...'
mv -uf $BACKUP_FILE $DESTINY && echo 'Success.'

#echo 'Umounting USB flash drive...'
#umount $DEVICE && echo 'The USB flash drive was umounted.'

rm -r $TEMP_DIR && echo 'The temporary directory was removed.'
echo 'Backup finished.'
