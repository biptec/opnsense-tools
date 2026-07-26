#!/bin/sh

# Copyright (c) 2026 Biptec
# All rights reserved.

set -eu

ROOTDIR=${1:-}
TOOLSDIR=${TOOLSDIR:-$(dirname $(dirname ${0}))}
CONFIG_XML=${CONFIG_XML:-/usr/local/etc/config.xml}

if [ -z "${ROOTDIR}" ] || [ ! -d "${ROOTDIR}" ]; then
    echo "Usage: ${0##*/} rootdir" >&2
    exit 1
fi
if [ ! -f "${ROOTDIR}${CONFIG_XML}" ]; then
    echo "Missing ${ROOTDIR}${CONFIG_XML}" >&2
    exit 1
fi
if [ ! -x "${ROOTDIR}/usr/local/bin/sudo" ]; then
    echo "The sudo package is required for the Proxmox profile" >&2
    exit 1
fi
if [ ! -x "${ROOTDIR}/usr/local/bin/qemu-ga" ]; then
    echo "The os-qemu-guest-agent package is required for the Proxmox profile" >&2
    exit 1
fi

/usr/local/bin/php "${TOOLSDIR}/build/profile-proxmox.php" \
    "${ROOTDIR}${CONFIG_XML}"
