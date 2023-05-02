#!/usr/bin/env bash

temp_dir=/home/gabriel/$RANDOM
mountage_point=/media/gabriel
device=/dev/sdb1
destiny=$mountage_point/backup
backup_file=backup-`date +"%a"`.zip
items=()
empty_items=()
non_empty_items=()
input=/home/gabriel/files/projetos/bash/bak/input.txt
i=0
j=0

for item in `cat $input`; do
	items[$((i++))]=$item
done

i=0
for item in ${items[*]}; do
	if [ -d $item ]; then
		if [ `ls $item | wc -l` -eq 0 ]; then
			empty_items[$i]=$item
		else
			non_empty_items[$j]=$item
		fi
	else
        if [ -s $item ]; then
            non_empty_items[$j]=$item
        else
            empty_items[$i]=$item
        fi
	fi
	let i++ j++
done

clear

echo 'x--------------------------------x'
echo '| BAK: BACKUP IN USB FLASH DRIVE |'
echo 'x--------------------------------x'

echo -en "\n"

echo "Starting backup..."

mount $device $mountage_point
echo "The USB flash drive was mounted."

mkdir -p $temp_dir
echo "Was created the temporary directory \"$temp_dir\"."

if [ ! -d $destiny ]; then
    mkdir -p $destiny
    echo "Was created the directory \"$destiny\"."
fi

if [ -n "$non_empty_items" ]; then
	echo "The following items was copied:"
	for item in ${non_empty_items[*]}; do
		cp -r $item $temp_dir
		echo "+ $item."
	done
fi

if [ -z "$empty_items" ]; then
	echo "The following items was ignored:"
	for item in ${empty_items[*]}; do
    	echo "- $item."
	done
fi

echo "Compressing items..."
zip -rq9 $backup_file $temp_dir
echo "The items was compressed."
mv $backup_file $destiny
echo "The compressed file was moved to the destiny."

echo "Umounting USB flash drive..."
umount $device
echo "The USB flash drive was umounted."

rm -r $temp_dir
echo "The temporary directory was removed."
echo "Finished."
