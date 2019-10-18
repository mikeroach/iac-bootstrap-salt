# mgmt-docker-ce/volumes.sls
#
# Manage a persistent disk attached to this instance as a Docker volume store.

# This state will format a block device if it's unable to run blkid,
# so let's make a good faith effort to ensure the correct package is
# installed and we can get a clean exit code before we get to that
# point. As much as I hate cmd.run, I hate inadvertently wiping out
# my persistent data even more.

install util-linux package:
  pkg.installed:
    - name: util-linux

ensure blkid executes:
  cmd.run:
    - name: blkid
    - require:
        - install util-linux package

ensure /dev/sdb belongs to Docker LVM physical volume:
  lvm.pv_present:
    - name: /dev/sdb
    - require:
        - ensure blkid executes

ensure Docker LVM volume group exists:
  lvm.vg_present:
    - name: docker_vg
    - devices: /dev/sdb
    - require:
        - ensure /dev/sdb belongs to Docker LVM physical volume

ensure Docker LVM logical volume exists:
  lvm.lv_present:
    - name: docker
    - vgname: docker_vg
    - extents: +100%FREE
    - require:
        - ensure Docker LVM volume group exists

# Note the requisites here: Salt will format a new filesystem
# on the LV *unless* one already exists (blkid exits with a 0
# if it can ID the filesystem type and 2 when it can't).
format filesystem after creating new Docker LVM logical volume:
  module.run:
    - name: disk.format
    - device: /dev/docker_vg/docker
    - fs_type: ext4
    - require:
        - ensure Docker LVM logical volume exists
    - unless:
        - blkid /dev/docker_vg/docker

ensure Docker LVM logical volume mounted:
  mount.mounted:
    - name: /mnt/docker_volumes
    - device: /dev/docker_vg/docker
    - fstype: ext4
    - mkmnt: true
    - persist: true
    - mount: true
    - require:
        - format filesystem after creating new Docker LVM logical volume
