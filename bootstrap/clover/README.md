# Clover

**TL;DR**: Image used is `clover.img`, the uncompressed data is in `cloverfs/`.

---

> Notes: 
>
> 1. Clover is a fix to a "solve once" problem. Pending no major breaking changes elsewhere, there is little to no reason to change it.
> 2. This setup was made with Clover revision 5147, and as stated above not had reason to be updated; this setup may be incompatible with newer versions of Clover.

[Clover](https://github.com/CloverHackyColor/CloverBootloader) is a bootloader originally developed for the purpose of tricking machines into thinking they're macintoshes. It provides a variety of EFI drivers and preload modules which macOS expects in it's boot sequence.

Clover is used in this project to provide NVMe boot support to hardware which is otherwise incompatible, such as the 13th generation Dell PowerEdge servers originally used in kclt-01.

NVMe disks are used as the primary storage device for Talos due to the necessity of disk performance for the `EPHEMERAL` data (i.e. etc.d). 

# Summary Config

At the highest level, the config circumvents lack of NVMe boot support by booting to a known medium (in all cases at time of writing that is a USB flash device[^1]) which provides an capability for NVMe booting, this then boots Talos's grub as normal.

1. Clover provides an NVMe driver, `NvmExpressDxe.efi`, but it is disabled by default. To enable it, it must be moved:
  - `/EFI/CLOVER/drivers/{off => UEFI}/NvmExpressDxe.efi`
  - `/EFI/CLOVER/drivers/{off => BIOS}/NvmExpressDxe.efi`
2. Clover provides 2 relevant keys used to determine which device should be booted.
  - [`DefaultVolume`](https://github.com/CloverHackyColor/CloverBootloader/wiki/Configuration#defaultvolume) is the name of the partition Clover should attempt to boot by default. This can be set to partition GUID, device path, referential "last booted disk", or based on partition label.
  - [`DefaultLoader`](https://github.com/CloverHackyColor/CloverBootloader/wiki/Configuration#defaultloader) is the path to the `.efi` binary on the `DefaultVolume`.
3. [Talos's disk](https://www.talos.dev/v1.3/learn-more/architecture/#file-system-partitions) is setup with 6 partitions, the most relevant one here is the first one, which contains EFI information. The partition is labeled `EFI` and the boot executable is `EFI/BOOT/BOOTX64.efi`.

Enabling the EFI drivers, setting the default volume to Talos's `EFI` partition (based on label), default loader to `EFI\BOOT\BOOTX64.efi`, and making necessary modifications within the Clover GUI config, Talos on NVMe can be automatically booted by setting the Clover install as each machine's highest boot priority in BIOS.

The reason the partition labels are used is that it makes the configuration generic enough to be used on all machines; GUID values, while more specific, would have to be updated for every node every time the EFI partition changes (which is recreated when Talos is upgraded)

[^1]: Sorry for an informal unverified claim here, but there's something in the back of my head that says this configuration will not work on a read-only medium, which is why it's configured as a kinda janky `.img` rather than an ISO-9660 `.iso`. I will try and verify this and edit the docs to match but if you're reading this... sorry I forgot.

## Changed config

The full configuration file can be viewed in `cloverfs/EFI/CLOVER/config.plist`. This just lists the relevant changes alluded to above.

```plist
<key>Boot</key>
<dict>
  <!-- Other keys have been omitted for brevity -->
  <key>DefaultLoader</key>
  <string>EFI\BOOT\BOOTX64.efi</string>
  <key>DefaultVolume</key>
  <string>EFI</string>
  <key>Timeout</key>
  <integer>0</integer>
</dict>
<!-- Other keys have been omitted for brevity -->
<key>GUI</key>
<dict>
  <key>Custom</key>
  <dict>
      <key>Entries</key>
      <array>
        <dict>
          <key>Hidden</key>
          <false/>
          <key>Volume</key>
          <string>EFI</string>
          <key>Disabled</key>
          <false/>
          <key>Type</key>
          <string>Linux</string>
          <key>Title</key>
          <string>TALOS</string>
        </dict>
      </array>
    <!-- Other keys have been omitted for brevity -->
  </dict>
  <!-- Other keys have been omitted for brevity -->
</dict>
```

# Issues

This is a bodge. It is a clever bodge, but a bodge nonetheless. It depends on a handful of external factors to work and potentially creates issues which, while definitely edge-cases, are not completely implausible.

- If Talos ever changes the label on the EFI partition or the location of the boot `.efi`, that is to say if the boot configuration is ever moved from `EFI:\EFI\BOOT\BOOTX64.efi`, this solution will break.
  - It is difficult to conceptualize a reason this would happen, however.
- Multiple partitions on the node with the `EFI` label could cause the solution to break. How Clover discriminates the partitions in this case is unclear.
  - Each node is a dedicated Talos box, why a second EFI partition would be present in the first place (implying a second permanently installed OS *also* reliant on Clover) is unclear.
- The solution involves an entirely discrete system; this introduces a small, but nonzero, avenue for exploitation.
  - Potential risks are mitigated by the fact that Clover never connects to the internet; therefore taking advantage of any potential exploit in Clover would presuppose an attack which either gains physical access to the machines (manually changing the boot USB or similar) or breaks Talos (which would be able to modify Clover), both of these however are issues with or without Clover.