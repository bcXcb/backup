#!/usr/bin/env bash
# Backup in USB flash drives

declare -r TEMP_DIR=/home/gabriel/$((RANDOM % 256)) # 0 to 255
declare -r MOUNTAGE_POINT=/media/gabriel
declare -r DEVICE=/dev/sdb1
declare -r DESTINY=$MOUNTAGE_POINT/backup
declare -r INPUT=/home/gabriel/files/projetos/github/bak/input.txt
declare -r BACKUP_FILE=backup-`date +"%a"`.zip

declare -a items
declare -a empty_items
declare -a non_empty_items

declare -i i=0
declare -i j=0

for item in `cat $INPUT`; do
	items[$((i++))]=$item
done

i=0
for item in ${items[*]}; do
	if [ -d $item ]; then
		[[ `ls $item | wc -l` -eq 0 ]] && empty_items[$i]=$item || non_empty_items[$j]=$item
	else
        [[ -s $item ]] && non_empty_items[$j]=$item || empty_items[$i]=$item
	fi
	let i++ j++
done

clear

echo 'x--------------------------------x'
echo '| BAK: BACKUP IN USB FLASH DRIVE |'
echo 'x--------------------------------x'

echo -en "\n"

echo "Starting backup..."

mount $DEVICE $MOUNTAGE_POINT
echo "The USB flash drive was mounted."

mkdir -p $TEMP_DIR
echo "Was created the temporary directory \"$TEMP_DIR\"."

if [ ! -d $DESTINY ]; then
    mkdir -p $DESTINY
    echo "Was created the directory \"$DESTINY\"."
fi

if [ -n "$non_empty_items" ]; then
	echo "The following items was copied:"
	for item in ${non_empty_items[*]}; do
		cp -rp $item $TEMP_DIR
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
