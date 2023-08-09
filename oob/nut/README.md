# Network Utility Tools

> The primary goal of the Network UPS Tools (NUT) project is to provide support for Power Devices, such as Uninterruptible Power Supplies, Power Distribution Units, Automatic Transfer Switches, Power Supply Units and Solar Controllers. NUT provides a common protocol and set of tools to monitor and manage such devices, and to consistently name equivalent features and data points, across a vast range of vendor-specific protocols and connection media types.
>
> NUT provides many control and monitoring features, with a uniform control and management interface.

NUT is used in this project to cleanly shut down servers in the event of an unexpected loss of power. It is run on a server out of band to minimize shooting itself in the foot.

Currently, all out of band tools must be installed and maintained manually (no Ansible or Terraform).

## KCLT-01

All OOB tools are run on a router-thing. If NUT detects any change in state of the UPS, it will call `scripts/notify.sh` with the environment variable `NOTIFYTYPE` set with [one of 9 possible values](https://networkupstools.org/docs/man/upsmon.conf.html).

```
TODO: How do you want to handle this actually?
elaborate in #51
```