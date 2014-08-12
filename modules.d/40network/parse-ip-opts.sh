#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Format:
#       ip=[dhcp|on|any]
#
#       ip=<interface>:[dhcp|on|any][:[<mtu>][:<macaddr>]]
#
#       ip=<client-IP-number>:<server-IP-number>:<gateway-IP-number>:<netmask>:<client-hostname>:<interface>:{dhcp|on|any|none|off}[:[<mtu>][:<macaddr>]]
#
# When supplying more than only ip= line, <interface> is mandatory and
# bootdev= must contain the name of the primary interface to use for
# routing,dns,dhcp-options,etc.
#

command -v getarg >/dev/null          || . /lib/dracut-lib.sh

if [ -n "$netroot" ] && [ -z "$(getarg ip=)" ] && [ -z "$(getarg BOOTIF=)" ]; then
    # No ip= argument(s) for netroot provided, defaulting to DHCP
    return;
fi

BOOTDEV=$(getarg bootdev=)

# Check ip= lines
# XXX Would be nice if we could errorcheck ip addresses here as well
for p in $(getargs ip=); do
    ip_to_var $p

    # make first device specified the BOOTDEV
    if [ -z "$BOOTDEV" ] && [ -n "$dev" ]; then
        BOOTDEV="$dev"
        warn "Setting bootdev to '$BOOTDEV'"
    fi

    # skip ibft since we did it above
    [ "$autoconf" = "ibft" ] && continue

    # We need to have an ip= line for the specified bootdev
    [ "$dev" = "$BOOTDEV" ] && BOOTDEVOK=1

    # Empty autoconf defaults to 'dhcp'
    if [ -z "$autoconf" ] ; then
        warn "Empty autoconf values default to dhcp"
        autoconf="dhcp"
    fi

    # Error checking for autoconf in combination with other values
    case $autoconf in
        error) die "Error parsing option 'ip=$p'";;
        bootp|rarp|both) die "Sorry, ip=$autoconf is currently unsupported";;
        static)
            if [ ! -e /etc/sysconfig/network/ifcfg-${dev} ] ; then
                warn "No ifcfg configuration present for interface $dev, skipping"
                continue
            fi
            ;;
        none|off)
            [ -z "$ip" ] && \
            die "For argument 'ip=$p'\nValue '$autoconf' without static configuration does not make sense"
            [ -z "$mask" -a -z "$prefix" ] && \
                die "Sorry, automatic calculation of netmask is not yet supported"
            ;;
        auto6);;
        dhcp|dhcp6|on|any) ;;
        *) die "For argument 'ip=$p'\nSorry, unknown value '$autoconf'";;
    esac

    dup=0
    if [ -n "$dev" ] ; then
        # We don't like duplicate device configs
        if [ -n "$IFACES" ] ; then
            for i in $IFACES ; do
                [ "$dev" = "$i" ] && dup=1 && break
            done
        fi
        # IFACES list for later use
        if [ $dup -eq 0 ]; then
             IFACES="$IFACES $dev"
        fi
    fi

    # Do we need to check for specific options?
    if [ -n "$NEEDDHCP" ] || [ -n "$DHCPORSERVER" ] ; then
        # Correct device? (Empty is ok as well)
        [ "$dev" = "$BOOTDEV" ] || continue
        # Server-ip is there?
        [ -n "$DHCPORSERVER" ] && [ -n "$srv" ] && continue
        # dhcp? (It's simpler to check for a set ip. Checks above ensure that if
        # ip is there, we're static
        [ -z "$ip" ] && continue
        # Not good!
        die "Server-ip or dhcp for netboot needed, but current arguments say otherwise"
    fi

done

# put BOOTIF in IFACES to make sure it comes up
if getargbool 1 "rd.bootif" && BOOTIF="$(getarg BOOTIF=)"; then
    BOOTDEV=$(fix_bootif $BOOTIF)
    IFACES="$BOOTDEV $IFACES"
fi

# This ensures that BOOTDEV is always first in IFACES
if [ -n "$BOOTDEV" ] && [ -n "$IFACES" ] ; then
    IFACES="${IFACES%$BOOTDEV*} ${IFACES#*$BOOTDEV}"
    IFACES="$BOOTDEV $IFACES"
fi

# Store BOOTDEV and IFACES for later use
[ -n "$BOOTDEV" ] && echo $BOOTDEV > /tmp/net.bootdev
[ -n "$IFACES" ]  && echo $IFACES > /tmp/net.ifaces
