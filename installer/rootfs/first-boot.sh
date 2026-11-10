#!/usr/bin/env bash
#
# Reference copy of the first-boot script.
#
# The authoritative file installed in the rootfs is:
#   archlinux/rootfs/firstboot/omarchyswitch-firstboot.sh
#
# This copy exists so the installer directory is self-describing, and so a
# reviewer can read what runs on the console's first boot without navigating
# the Arch layer. Keep both files identical.
#
# It is not executed from here: scripts/build-rootfs.sh installs the archlinux/
# version as /usr/local/sbin/omarchyswitch-firstboot.

set -uo pipefail

cat >&2 <<'EOF'
This is a reference copy. The script that actually runs on the console is
installed from archlinux/rootfs/firstboot/omarchyswitch-firstboot.sh.

Read that file (or /usr/local/sbin/omarchyswitch-firstboot on a built rootfs)
for the executable version.
EOF

exit 0
