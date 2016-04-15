#!/bin/bash -x

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

zfs_destroy_snapshots () {
  for vol in "${volumes[@]}"
  do
    zfs destroy "$vol@$unique_snapshot_name" &> "$debug"
  done
}

umount "$backup_zvol_point" && rm -r "$backup_zvol_point"
umount $(ls -d -1 $backup_mount_point* | grep '@' | tr '\n' ' ') && rm -r $(ls -d -1 $backup_mount_point* | grep '@' | tr '\n' ' ')

rm "$summary_file"
zfs_destroy_snapshots
