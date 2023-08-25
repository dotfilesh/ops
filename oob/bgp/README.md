# Additional Notes on KCLT-01 Router

The router used in KCLT-01 is a UniFi UDM Pro, which does not support
BGP. However, there are tools to expand functionality outside Ubiquiti's support. This is done to install [FRR](https://frrouting.org/) to provide BGPd. The configuration files in this dir enumerate 

---

# Not-Walkthrough

> In an attempt to document everything, even things which cannot be listed as config files, Here I have included what steps taken during the process of configuring the UDMP.

1. [Followed this guide](https://github.com/unifi-utilities/unifios-utilities/tree/main/nspawn-container) to the letter; which installed nspawn-container and set it to persist across firmware updates.
2. [installed frr](https://deb.frrouting.org/). Some minor modifications had to be made:
  - The container doesn't have `sudo` and runs as root
  - `lsb_release` doesn't... exist either. My `/etc/apt/sources.list.d/frr.list` ends up looking like `deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr bullseye frr-stable` for what it's worth.

[With reference to Steve Saunder's blog post](https://www.map59.com/ubiquiti-udm-running-bgp/)
