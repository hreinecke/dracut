#!/bin/sh

# cifs_to_var CIFSROOT
# use CIFSROOT to set $server, $path, and $options.
# CIFSROOT is something like: cifs://[<username>[:<password>]]@<host>/<path>
# NETIF is used to get information from DHCP options, if needed.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

davfs_to_var() {
    local davfsuser; local davfspass
    # Check required arguments
    proto=${1%%://*}
    if [ "${proto}" != "http" -a "${proto}" != "https" ]; then
        proto="http"
    fi
    server=${1##h://}
    davfsuser=${server%@*}
    davfspass=${davfsuser#*:}
    if [ "$davfspass" != "$davfsuser" ]; then
	davfsuser=${davfsuser%:*}
    else
	davfspass=$(getarg davfspass)
    fi
    if [ "$davfsuser" != "$server" ]; then
	server="${server#*@}"
    else
	davfsuser=$(getarg davfsuser)
    fi

    if [ ! "$davfsuser" ]; then
        davfsuser="none"
    fi
    if [ ! "$davfspass" ]; then
        davfspass="none"
    fi

    path=${server#*/}
    server=${server%/*}

    [ -d /etc/davfs2 ] || mkdir /etc/davfs2
    echo "${proto}://${server}/${path} ${davfsuser} ${davfspass}" > \
         /etc/davfs2/secrets
}
