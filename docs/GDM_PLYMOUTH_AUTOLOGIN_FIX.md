# GDM, Plymouth, and Live Autologin Fix

## Problem

The OBLinux live ISO intermittently stopped at the GDM login screen instead
of automatically entering the GNOME desktop as `liveuser`.

Debug logging confirmed that GDM successfully started the complete liveuser
GNOME session on `tty2`. Plymouth later completed its shutdown and the active
VT switched back to `tty1`, causing GDM to create and display its greeter.

This was an upstream GDM/Plymouth VT race exposed by boot-time autologin. It
was not caused by the additional applications, liveuser configuration, or
font packages.

## Permanent changes

### 1. End Plymouth before GDM starts

Created:

`airootfs/etc/systemd/system/gdm.service.d/10-plymouth.conf`

```ini
[Service]
ExecStartPre=-/usr/bin/plymouth quit --retain-splash
```

This retains the branded splash until GDM takes over, while ensuring that
Plymouth cannot perform its delayed VT switch after autologin begins.

### 2. Mask the tty1 getty

Created this symbolic link:

```text
airootfs/etc/systemd/system/getty@tty1.service -> /dev/null
```

This prevents the console getty from competing with GDM for `tty1`.

### 3. Mask automatic tty1 getty creation

Created this symbolic link:

```text
airootfs/etc/systemd/system/autovt@tty1.service -> /dev/null
```

This prevents systemd-logind from automatically creating another getty on
`tty1`.

## Existing Plymouth settings retained

Plymouth remains listed in `packages.x86_64`:

```text
plymouth
```

The Plymouth hook remains in
`airootfs/etc/mkinitcpio.conf.d/archiso.conf`:

```bash
HOOKS=(base udev microcode modconf kms plymouth memdisk archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs block filesystems keyboard)
```

The normal BIOS boot entry in `syslinux/archiso_sys-linux.cfg` retains:

```text
quiet splash
```

## Debug cleanup

GDM debugging was enabled temporarily during diagnosis. The final
`airootfs/etc/gdm/custom.conf` should end with an empty debug section:

```ini
[debug]
```

`Enable=true` should not remain in the final configuration.

## Validation

With Plymouth branding restored and the GDM pre-start drop-in active, the
live ISO successfully reached the GNOME desktop through `liveuser` autologin
on **11 out of 11 consecutive VirtualBox boots**.

A fresh ISO built independently from the pushed `main` branch subsequently
passed **10 out of 10 boots** and completed a full Calamares installation.
The installed system booted successfully, and root console authentication was
verified on `tty3` using the password configured during installation.
