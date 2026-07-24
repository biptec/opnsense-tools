#!/bin/sh

# Copyright (c) 2026 Biptec
# All rights reserved.

set -e

SELF=vagrantbox
. ./common.sh

PROVIDER=${1:-vmware}
case "${PROVIDER}" in
vmware|vmware_desktop)
    PROVIDER=vmware_desktop
    ;;
*)
    echo "Unsupported Vagrant provider: ${PROVIDER}" >&2
    exit 1
    ;;
esac

VMIMG=${IMAGESDIR}/${PRODUCT_RELEASE}-vm-${PRODUCT_ARCH}.vmdk
if [ ! -f "${VMIMG}" ]; then
    echo "Cannot find VMDK image: ${VMIMG}" >&2
    exit 1
fi

ASSETS=${TOOLSDIR}/assets/vagrant-vmware
BOX_STAGE=${STAGEDIR}/vagrantbox
BOX=${VAGRANTBOXESDIR}/${PRODUCT_RELEASE}-vagrant-${PRODUCT_ARCH}.box
case "${PRODUCT_ARCH}" in
amd64)
    BOX_ARCH=amd64
    GUEST_OS=freeBSD15-64
    FIRMWARE=bios
    FIRMWARE_OPTIONS=
    NVRAM_OPTION=
    ;;
aarch64)
    BOX_ARCH=arm64
    GUEST_OS=arm-freeBSD15-64
    FIRMWARE=efi
    FIRMWARE_OPTIONS='uefi.secureBoot.enabled = "FALSE"'
    NVRAM_OPTION='nvram = "opnsense.nvram"'
    ;;
*)
    echo "Unsupported Vagrant architecture: ${PRODUCT_ARCH}" >&2
    exit 1
    ;;
esac

rm -rf "${BOX_STAGE}"
mkdir -p "${BOX_STAGE}" "${VAGRANTBOXESDIR}"

for FILE in Vagrantfile info.json opnsense.vmsd opnsense.vmxf; do
    if [ ! -f "${ASSETS}/${FILE}" ]; then
        echo "Missing Vagrant asset: ${ASSETS}/${FILE}" >&2
        exit 1
    fi
    cp "${ASSETS}/${FILE}" "${BOX_STAGE}/${FILE}"
done
cp "${VMIMG}" "${BOX_STAGE}/opnsense.vmdk"
if [ "${PRODUCT_ARCH}" = "aarch64" ]; then
    cp "${ASSETS}/opnsense-aarch64.nvram" "${BOX_STAGE}/opnsense.nvram"
else
    : > "${BOX_STAGE}/opnsense.nvram"
fi
sed -e "s|%%GUEST_OS%%|${GUEST_OS}|g" \
    -e "s|%%FIRMWARE%%|${FIRMWARE}|g" \
    -e "s|%%FIRMWARE_OPTIONS%%|${FIRMWARE_OPTIONS}|g" \
    -e "s|%%NVRAM_OPTION%%|${NVRAM_OPTION}|g" \
    "${ASSETS}/opnsense.vmx.in" > "${BOX_STAGE}/opnsense.vmx"
cat > "${BOX_STAGE}/metadata.json" <<EOF_METADATA
{
  "provider": "${PROVIDER}",
  "architecture": "${BOX_ARCH}"
}
EOF_METADATA

chmod 0644 "${BOX_STAGE}"/*
find "${BOX_STAGE}" -type f -exec touch -t 202001010000 {} +
rm -f "${BOX}"

echo ">>> Building Vagrant VMware box..."
bsdtar --uid 0 --gid 0 --numeric-owner -C "${BOX_STAGE}" -czf "${BOX}" \
    Vagrantfile info.json metadata.json opnsense.nvram opnsense.vmsd \
    opnsense.vmx opnsense.vmxf opnsense.vmdk

echo ">>> Vagrant box: ${BOX}"
