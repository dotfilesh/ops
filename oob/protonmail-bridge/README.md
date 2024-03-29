# ProtonMail for OOB cluster email

To facilitate cluster email (i.e. NOREPLY email for things such as password resets or notifications), `protonmail-bridge` is installed on a machine outside the cluster. 

ProtonMail is encrypted email and does not provide a public host for SMTP or IMAP to be hooked into. Instead, paying customers are provided a multi-platform [bridge](https://proton.me/mail/bridge) which by default runs an IMAP and SMTP server on the local machine for clients like Thunderbird to use. The bridge generates unique credentials in a way difficult to be consumed as secrets, and can only be logged into interactively; therefore it is not advisable to run within the cluster.

# ProtonMail Bridgeish

By default, the `bridge` is a GUI tool and makes the server only available on 127.0.0.1. Instead, [an unofficial docker version](https://hub.docker.com/r/shenxn/protonmail-bridge) is used which runs without a GUI (but integrates the `secret-service` kit) and can be exposed to the local network.

I cloned [the GitHub repo](https://github.com/shenxn/protonmail-bridge-docker#build) and built the `deb` image

Then to initialize:

> The image created did not have a name.

```
docker run --rm -it -v protonmail:/root ${TAG} init
```

I logged in with the CLI using the ProtonMail username and password (+ TOTP). I also scraped the generated username and password for SMTP (IMAP will not be exposed). These were set aside for later.

To start the bridge, I ran:

```
docker run -d --name=protonmail-bridge -v protonmail:/root -p 1025:25/tcp --restart=unless-stopped ${TAG}
```

# Cluster integration

The credentials generated by the bridge were stored within the cluster secrets

```yaml
SECRET__PROTONMAIL_FROM: # From address, e.g. "noreply@domain.tld"
SECRET__PROTONMAIL_HOST: # IP of node bridge is running
SECRET__PROTONMAIL_PORT: "1025"
SECRET__PROTONMAIL_USER: # Bridge **LOGIN** address
SECRET__PROTONMAIL_PASSWORD: # Bridge password
```

> Note that the address must be one set up for the corresponding ProtonMail account. Yes, that does mean all NOREPLY emails come from the same inbox as my personal email.

This could be passed to workloads which required it (e.g. authentik)