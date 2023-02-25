# Clover

**TL;DR**: Image used is `clover.img`, the uncompressed data is in `cloverdata/`.

---

> Notes: 
>
> 1. Clover is a fix to a "solve once" problem. Pending no major breaking changes elsewhere, there is little to no reason to change it.
> 2. The clover version used here is `v0000`, and as stated above not had reason to be updated; this setup may be incompatible with newer versions of Clover.

[Clover](https://github.com/CloverHackyColor/CloverBootloader) is a bootloader originally developed for the purpose of tricking machines into thinking they're macintoshes. It comes with a variety of EFI drivers to preload modules which macOS expects to be provided by the T2 security chip and iBoot (or however Apple Silicon works now-a-days).

Clover is used in this project to provide NVMe boot support to hardware which otherwise does not provide it, such as the 13th generation Dell PowerEdge servers originally used in kclt-01.

NVMe disks are used as the primary storage device for talos due to the necessity of disk performance for the `EPHEMERAL` data (i.e. etc.d). 

# Summary Config

At the highest level, the config circumvents lack of NVMe boot support by: booting to a known medium (in all cases at time of writing that is a USB flash device[^1]) which provides a driver for NVMe booting -> boot Talos GRUB as normal -> boot Talos

1. Clover provides an NVMe driver, `NvmExpressDxe.efi`, but it is disabled by default. To enable it, it must be moved:
  - `/EFI/CLOVER/drivers/{off => UEFI}/NvmExpressDxe.efi`
  - `/EFI/CLOVER/drivers/{off => BIOS}/NvmExpressDxe.efi`
2. Set config.plist
3. Discuss talos naming

[^1]: Sorry for an informal unverified claim here, but there's something in the back of my head that says this configuration will not work on a read-only medium, which is why it's configured as a kinda janky `.img` rather than an ISO-9660 `.iso`. I will try and verify this and edit the docs to match but if you're reading this... sorry I forgot.

# Issues

This is a bodge. It's a clever bodge, but it is a bodge. It depends on a handful of external factors to work.

- If Talos ever changes the label of the `EFI:\EFI\BOOT\BOOTX64.efi`