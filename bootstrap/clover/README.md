# Clover

> Convey: 
>
> 1. Clover was a fix to a "solve once" problem.
> 2. Get version of clover used. Docs provided are known to be functional only with said version. Any API changes since then are not accounted for.

[Clover](https://github.com/CloverHackyColor/CloverBootloader) is a bootloader originally developed for the purpose of tricking machines into thinking they're macintoshes. It comes with a variety of EFI drivers to preload modules which macOS expects to be provided by the T2 security chip and iBoot (or however Apple Silicon works now-a-days).

Clover is used in this project to provide NVMe boot support to hardware which otherwise does not provide it, such as the 13th generation Dell PowerEdge servers originally used in kclt-01.

NVMe disks are used as the primary storage device for talos due to the necessary disk performance for the ephemeral data (i.e. etcd). 

# Summary Config

1. Clover provides its own NVMe driver, `NvmExpressDxe.efi`, this was enabled 