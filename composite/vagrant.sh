#!/bin/sh

# Copyright (c) 2026 Biptec
# All rights reserved.

set -e

. $(dirname ${0})/util.sh

REQUEST=${1:-vmware,20G,never}
OLDIFS=${IFS}
IFS=,
set -- ${REQUEST}
IFS=${OLDIFS}

PROVIDER=${1:-vmware}
SIZE=${2:-20G}
SWAP=${3:-never}
if [ -n "${4:-}" ]; then
    echo "Usage: make vagrant-vmware[,size[,swap]]" >&2
    exit 1
fi
if [ "${PROVIDER}" != "vmware" -a "${PROVIDER}" != "vmware_desktop" ]; then
    echo "Unsupported Vagrant provider: ${PROVIDER}" >&2
    exit 1
fi

load_make_vars PRODUCT_ARCH PRODUCT_CORE PRODUCT_SUFFIX SETSDIR
CORE_VERSION=$(load_core_version ${SETSDIR} ${PRODUCT_ARCH} ${PRODUCT_CORE})
add_package()
{
    case " ${ADDITIONS:-} " in
    *" ${1} "*)
        ;;
    *)
        ADDITIONS="${ADDITIONS:-} ${1}"
        ;;
    esac
}

add_package sudo
add_package open-vm-tools-nox11

make clean-vm \
    vm-vmdk,${SIZE},${SWAP},vagrant \
    ADDITIONS="${ADDITIONS# }" \
    SUFFIX="${PRODUCT_SUFFIX}" \
    VERSION="${CORE_VERSION}"

make vagrantbox-${PROVIDER} \
    SUFFIX="${PRODUCT_SUFFIX}" \
    VERSION="${CORE_VERSION}"
