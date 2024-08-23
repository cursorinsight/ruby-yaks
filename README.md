YAKS
====

Yet Another Key Server (YAKS) is lightweight keyserver to manage GPG keys for a
single organization. It is meant to work behind a firewall where users are
considered well-intentioned.

# Installation

1.  Build and install service using Docker Compose:

    ```
    $ docker compose build
    ```

2.  Start container:

    ```
    $ docker compose up -d
    ```

3.  Set up permissions on data directory:

    ```
    $ docker compose exec -it --user=root backend sh
    ...
    > chown -Rh nobody:root /mnt/data
    ```

4.  Set up web load balancer (e.g. Traefik) to publish the service on a TLS/SSL
    endpoint.

    !!! IMPORTANT !!!

    This service does not employ any authentication, so it is advised to
    install it with additional security measures -- e.g. behind a firewall with
    only VPN access and no public access from the Internet.

# Usage

YAKS is intended to store and make GPG keys available on request for everyone
who has access to its interface.  Since `gpg` is the goto tool to manage GPG
keys on Linux, the most common way to manage keys with YAKS is the following:

*   Upload a key to the keyserver:

    ```
    $ gpg --keyserver hkps://yaks.address.com --send-key 0x70FFAE70E9E1CC81
    ```

*   To search for a specific key, use:

    ```
    $ gpg --keyserver hkps://yaks.address.com --search-key bence@cursorinsight.com
    ```

    If it founds a key (or multiple keys) on the server `gpg` will download the
    selected keys for you automagically.

*   To fetch and merge a selected key:

    ```
    $ gpg --keyserver hkps://yaks.address.com --recv-key 0x70FFAE70E9E1CC81
    ```

## Thunderbird

As of release 115, Thunderbird's internal tool to manage GPG keys supports the
HKP protocol, that this server implements. To use your server you have to set
the  `mail.openpgp.keyserver_list` configuration parameter in Thunderbird to the
server address, e.g.: hkps://yaks.address.com.

Earlier versions of Thunderbird only support servers using the
[WKD/WKS protocol][wkd-wks-protocol]. In this case you have to manually download
the desired key from the YAKS server, export it and then import it into
Thunderbird, e.g.:

```
$ gpg --keyserver hkps://yaks.address.com --export --armor --output bence.asc \
      0x70FFAE70E9E1CC81
```

Future releases of YAKS may support WKD/WKS.

[wkd-wks-protocol]: https://wiki.gnupg.org/WKD
