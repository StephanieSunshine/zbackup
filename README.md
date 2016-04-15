# zBackup

ZFS backup staging for snapshots of zvols and filesystems for Crashplan.  Built to work with Proxmox VE, but should work with anything ZFS based.

  - Supports ZVols
  - Supports Filesystems
  - Gets around Crashplans backup of block device problem

[Crashplan] from [Code42] has been an excellent backup solution for all my desktop needs and most of my server needs.  However, [Crashplan] has a few weaknesses.  Mainly, it isn't [ZFS] aware and it cannot backup raw block devices.  Both of which you would normally need to backup any [Proxmox VE] server using [ZFS] virtual machine storage.

Zbackup fixes this problem.  Zbackup uses ZFS snapshots, bind mounts, and a tool called [diskfile] to work it's magic.  ZVol snapshots are mounted in such a fashion that they look like flat files, without using any extra disk space and filesystem snapshots are mounted using bind mounts to give [Crashplan] the exact configuration it's looking for.

## Requirements
Things you will need:
 - [Git]
 - [libfuse]
 - [Diskfile]
 - [zBackup]
 - [Crashplan]
 
## Installation
This assumes you already have Proxmox VE, ZFS, and Crashplan already installed.
```sh
root@pve:/# apt-get install build-essential git libfuse-dev libfuse
```
### Install [diskfile]
```sh
root@pve:/# cd /usr/src
root@pve:/usr/src# git clone https://github.com/vasi/diskfile.git
root@pve:/usr/src# cd diskfile
root@pve:/usr/src/diskfile# make
root@pve:/usr/src/diskfile# cp diskfile /usr/local/bin/ 
```
### Install [zBackup]
```sh
root@pve:/# cd /usr/src
root@pve:/usr/src# git clone https://github.com/StephanieSunshine/zbackup.git
root@pve:/usr/src/# cd zBackup
root@pve:/usr/src/zBackup# cp -r etc/* /etc/
root@pve:/usr/src/zBackup# chmod +x *.sh
root@pve:/usr/src/zBackup# cp *.sh /usr/local/bin/
```
## Configuration
Zbackup by default stores everything in /backups/zfs/.  It is recomended that you create a zfs volume for /backups/

```sh
root@pve:/# zfs create rpool/backups
root@pve:/# zfs set mountpoint=/backups rpool/backups
```

All zBackup configuration settings can be found in /etc/zbackup/zbackup.conf.  To select which volumes you would like to backup, edit the /etc/zbackup/zbackup.volfile and change the current settings to the shares you would like to backup.  One volume per line

```sh
root@pve:/usr/src/diskfile# cat /etc/zbackup/zbackup.volfile 
# One line per ZFS volume
rpool/ROOT/pve-1/vm-100-disk-1
rpool/ROOT/pve-1/vm-101-disk-1
rpool/ROOT/pve-1/vm-102-disk-1
rpool/ROOT/pve-1/vm-108-disk-1
rpool/ROOT/pve-1
rpool/subvol-110-disk-1
```
Configure [Crashplan] to now backup only /backups.  This way, you can use zfs snapshots of the host's file system instead of directly relying on the file system.

## Running
Zbackup is designed to run from cron right before [Crashplan] starts.  Edit the crontab for root and set zbackup-cycle.sh to run 15 minutes before Crashplan is scheduled to start.
```cron
45 8 * * * /usr/local/bin/zbackup-cycle.sh >/dev/null 2>&1
```

Crashplan must have realtime backups turned off and backups scheduled to start 15 minutes after zbackup has ran.

## Conclusion

Please file an issue with the Github issue tracker if you find a bug.  Feel free to submit a pull request.

## License
The MIT License (MIT)
Copyright (c) <2016> Stephanie Sunshine <stephanie@isula.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[libfuse]: <https://github.com/libfuse/libfuse>
[Git]: <https://git-scm.com/>
[Crashplan]: <http://www.code42.com/crashplan/>
[Code42]: <http://www.code42.com/>
[Proxmox VE]: <http://www.proxmox.com/en/>
[ZFS]: <http://zfsonlinux.org/>
[diskfile]: <https://github.com/vasi/diskfile>
[zBackup]: <https://github.com/StephanieSunshine/zbackup>
