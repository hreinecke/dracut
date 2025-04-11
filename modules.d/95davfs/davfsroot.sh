#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
. /lib/cifs-lib.sh

[ "$#" = 3 ] || exit 1

# root is in the form root=davfs://user:pass@[server]/[folder] either from
# cmdline or dhcp root-path
netif="$1"
root="$2"
NEWROOT="$3"

davfs_to_var $root
echo proto: $proto
echo server: $server
echo path: $path

mount.davfs "${proto}://${server}/${path}" "$NEWROOT" && { [ -e /dev/root ] || ln -s null /dev/root ; }

# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -f -- "$job"' > $hookdir/initqueue/davfs.sh
# force udevsettle to break
> $hookdir/initqueue/work
