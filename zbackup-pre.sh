#!/bin/bash

#
# The MIT License (MIT)
# Copyright (c) 2016 Stephanie Sunshine <stephanie@isula.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

source /etc/zbackup/zbackup.conf

if [[ $* == *--debug* ]]; then
  debug="/dev/stdout"
fi

if [ -f "$volfile" ]; then
  volumes=( `cat "$volfile" | grep -vE '^#' ` )
else
  echo "$volfile missing. Abort"
fi

append_summary () {
  summary=( "${summary[@]}" "$1" )
}

append_summary "ZBackup pre started $(date)"
append_summary " "
append_summary "UID: $unique_snapshot_name"
append_summary "Volfile: $volfile"
append_summary "Backup location: $backup_mount_point"
append_summary "Backup ZVol location: $backup_zvol_point"
append_summary "Diskfile location: $diskfile "
append_summary " "
append_summary "Targets to backup:"
append_summary "`cat "$volfile" | grep -vE '^#'`"
append_summary " "
append_summary "Current Mappings:"
append_summary "`zfs list`"
append_summary " "
append_summary "Mappings:"
append_summary " "

mkdir "$backup_mount_point" &> "$debug"
mkdir "$backup_zvol_point" &> "$debug"

zfs_snapdev_pre () {
  for vol in "${volumes[@]}"
  do  
    zfs set snapdev=visible "$vol"
  done
}

zfs_destroy_snapshots () {
  for vol in "${volumes[@]}"
  do
    zfs destroy "$vol@$unique_snapshot_name" &> "$debug"
  done
}

zfs_create_snapshots () {
  for vol in "${volumes[@]}"
  do  
    zfs snapshot "$vol@$unique_snapshot_name" &> "$debug" 
  done
}

diskfile_mount_volume_snapshot () {
  vol=$1
  echo "diskfile_mount_volume_snapshot got: $vol" &> "$debug"
  real_bd=$(realpath "/dev/$vol@$unique_snapshot_name")
  echo "Real path: $real_bd" &> "$debug"
  short_bd=$( echo $real_bd | sed -e 's/\/dev\///' )
  append_summary "$vol maps to: $backup_zvol_point$short_bd"
  zvol_block_devices=("${zvol_block_devices[@]}" "$real_bd")
}

diskfile_mount_filesystem_snapshot () {
  vol=$1
  echo "diskfile_mount_filesystem_snapshot got: $vol" &> "$debug"
  cooked_mp=$(echo "$vol@$unique_snapshot_name" | sed -e 's/\//\!/g;' )
  commands_to_be_ran=( "${commands_to_be_ran[@]}" "mkdir "$backup_mount_point$cooked_mp"")
  ss_mountpoint=$(zfs get -H -o value -p mountpoint "$vol" | sed -e 's/\/$//' )
  commands_to_be_ran=( "${commands_to_be_ran[@]}" "mount --bind "$ss_mountpoint/.zfs/snapshot/$unique_snapshot_name" "$backup_mount_point$cooked_mp"")
  append_summary "$vol maps to: $backup_mount_point$cooked_mp"
}

diskfile_mount_prep () {
for vol in "${volumes[@]}"
do
  # Here is where things get tricky
  voltype=$(zfs get -H -o value -p type "$vol")

  echo ""$vol" is: "$voltype"" &> "$debug"

  case "$voltype" in
    filesystem) 
                diskfile_mount_filesystem_snapshot $vol
                echo &> "$debug"
                ;;

    volume)     
                diskfile_mount_volume_snapshot $vol
                echo &> "$debug"
                ;;

    *)
                echo "Error: Volume type should be either filesystem or volume.  Received "$voltype""
                zfs_destroy_snapshots
                exit 1
                ;;
  esac
done
}

diskfile_mount () {
  df="$diskfile "${zvol_block_devices[@]}" $backup_zvol_point"
  commands_to_be_ran=( "$df" "${commands_to_be_ran[@]}")
  
  df="umount $backup_zvol_point"
  commands_to_be_ran=( "$df" "${commands_to_be_ran[@]}")
 
  truncate "$summary_file" --size 0
 
  for line in "${summary[@]}"
  do
    echo "$line"
    echo "$line" >> "$summary_file"
  done

echo 

  for cmd in "${commands_to_be_ran[@]}"
  do
    $($cmd &> "$debug")
  done
}

# Main
zfs_snapdev_pre
zfs_destroy_snapshots
zfs_create_snapshots

diskfile_mount_prep
echo &> "$debug"
diskfile_mount

echo
