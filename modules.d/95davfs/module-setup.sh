#!/bin/bash

# called by dracut
check() {
    # If our prerequisites are not met, fail anyways.
    require_binaries mount.davfs || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ "$fs" == "https" ]] && return 0
            [[ "$fs" == "http" ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
depends() {
    # We depend on network modules being loaded
    echo network
}

# called by dracut
install() {
    local _i
    local _nsslibs
    inst_multiple -o mount.davfs
    inst_multiple /etc/services /etc/nsswitch.conf /etc/protocols

    inst_hook cmdline 90 "$moddir/parse-davfsroot.sh"
    inst "$moddir/cifsroot.sh" "/sbin/davfsroot"
    inst "$moddir/cifs-lib.sh" "/lib/davfs-lib.sh"
    dracut_need_initqueue
}
