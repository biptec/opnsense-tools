#!/bin/sh

# Copyright (c) 2026 Biptec
# All rights reserved.

set -eu

ROOTDIR=${1:-}
TOOLSDIR=${TOOLSDIR:-$(dirname $(dirname ${0}))}
CONFIG_XML=${CONFIG_XML:-/usr/local/etc/config.xml}
VAGRANT_KEY=${TOOLSDIR}/assets/vagrant/vagrant.pub

if [ -z "${ROOTDIR}" -o ! -d "${ROOTDIR}" ]; then
    echo "Usage: ${0##*/} rootdir" >&2
    exit 1
fi
if [ ! -f "${ROOTDIR}${CONFIG_XML}" ]; then
    echo "Missing ${ROOTDIR}${CONFIG_XML}" >&2
    exit 1
fi
if [ ! -f "${VAGRANT_KEY}" ]; then
    echo "Missing ${VAGRANT_KEY}" >&2
    exit 1
fi
if [ ! -x "${ROOTDIR}/usr/local/bin/sudo" ]; then
    echo "The sudo package is required for the Vagrant profile" >&2
    exit 1
fi
if [ ! -x "${ROOTDIR}/usr/local/bin/vmware-checkvm" ]; then
    echo "The open-vm-tools-nox11 package is required for the Vagrant profile" >&2
    exit 1
fi
if ! pw -R "${ROOTDIR}" groupshow vagrant >/dev/null 2>&1; then
    pw -R "${ROOTDIR}" groupadd vagrant
fi
if pw -R "${ROOTDIR}" usershow vagrant >/dev/null 2>&1; then
    pw -R "${ROOTDIR}" usermod vagrant -u 1000 -g vagrant -G wheel \
        -d /home/vagrant -s /bin/sh -w no
else
    pw -R "${ROOTDIR}" useradd vagrant -u 1000 -m -g vagrant -G wheel \
        -d /home/vagrant -s /bin/sh -c "Vagrant user" -w no
fi

USER_RECORD=$(pw -R "${ROOTDIR}" usershow vagrant)
USER_UID=$(echo "${USER_RECORD}" | cut -d: -f3)
USER_GID=$(echo "${USER_RECORD}" | cut -d: -f4)

install -d -m 0700 "${ROOTDIR}/home/vagrant/.ssh"
install -m 0600 "${VAGRANT_KEY}" \
    "${ROOTDIR}/home/vagrant/.ssh/authorized_keys"
touch "${ROOTDIR}/home/vagrant/.hushlogin"
chown -R "${USER_UID}:${USER_GID}" "${ROOTDIR}/home/vagrant"

install -d -m 0750 "${ROOTDIR}/usr/local/etc/sudoers.d"
printf '%s\n' 'vagrant ALL=(ALL) NOPASSWD: ALL' \
    > "${ROOTDIR}/usr/local/etc/sudoers.d/vagrant"
chmod 0440 "${ROOTDIR}/usr/local/etc/sudoers.d/vagrant"
RC_CONF=${ROOTDIR}/etc/rc.conf.local
LOADER_CONF=${ROOTDIR}/boot/loader.conf
mkdir -p "${ROOTDIR}/etc" "${ROOTDIR}/boot"
touch "${RC_CONF}" "${LOADER_CONF}"

sed -i '' \
    -e '/^vmware_guestd_enable=/d' \
    -e '/^vmware_guest_kmod_enable=/d' \
    "${RC_CONF}"
cat >> "${RC_CONF}" <<'EOF_RC'
vmware_guestd_enable="YES"
vmware_guest_kmod_enable="YES"
EOF_RC

sed -i '' -e '/^kern.hz=/d' "${LOADER_CONF}"
printf '%s\n' 'kern.hz="100"' >> "${LOADER_CONF}"

/usr/local/bin/php "${TOOLSDIR}/build/profile-vagrant.php" \
    "${ROOTDIR}${CONFIG_XML}"
