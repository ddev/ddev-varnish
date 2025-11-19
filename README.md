[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ddev/ddev-varnish/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ddev/ddev-varnish/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ddev/ddev-varnish)](https://github.com/ddev/ddev-varnish/commits)
[![release](https://img.shields.io/github/v/release/ddev/ddev-varnish)](https://github.com/ddev/ddev-varnish/releases/latest)

# DDEV Varnish

## Overview

[Varnish Cache](https://varnish-cache.org/) is a web application accelerator also known as a caching HTTP reverse proxy. You install it in front of any server that speaks HTTP and configure it to cache the contents. Varnish Cache is really, really fast. It typically speeds up delivery with a factor of 300 - 1000x, depending on your architecture.

This add-on integrates Varnish into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get ddev/ddev-varnish
ddev restart
```

> [!NOTE]
> Run `ddev add-on get ddev/ddev-varnish` after changes in the Mailpit ports or `web_extra_exposed_ports` in `.ddev/config.yaml` so that `.ddev/docker-compose.varnish_extras.yaml` is regenerated.

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

The Varnish service inserts itself between ddev-router and the web container, so that calls to the web container are routed through Varnish first. The [docker-compose.varnish.yaml](docker-compose.varnish.yaml) installs Varnish and uses the default domain as its own host name.

A `docker-compose.varnish_extras.yaml` file is generated on install which replaces the `HTTP_EXPOSE` and `HTTPS_EXPOSE` variables of the web container to exclude non-webserver ports from Varnish.

## Helper Commands

This add-on also providers several helper commands. These helpers allow developers to run Varnish commands from the host, however, the commands are actually run inside the Varnish container.

| Command                      | Description                                               |
|------------------------------|-----------------------------------------------------------|
| `ddev varnishd`              | Varnish-cli                                               |
| `ddev varnishadm`            | Control a running Varnish instance                        |
| `ddev varnishhist`           | Display Varnish request histogram                         |
| `ddev varnishlog`            | Display Varnish logs                                      |
| `ddev varnishncsa`           | Display Varnish logs in Apache / NCSA combined log format |
| `ddev varnishstat`           | Display Varnish Cache statistics                          |
| `ddev varnishtest`           | Test program for Varnish                                  |
| `ddev varnishtop`            | Display Varnish log entry ranking                         |
| `ddev logs -s varnish`       | Check Varnish logs                                        |
| `ddev varnish-config-reload` | Reloads the varnish current config to apply changes       |

See [The Varnish Reference Manual](https://varnish-cache.org/docs/6.0/reference/index.html) for more information about the commands, their flags, and their arguments.

## Advanced Customization

You may want to edit the `.ddev/varnish/default.vcl` to meet your needs. Remember to remove `#ddev-generated` from the file if you want your changes to the file preserved.

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.varnish --varnish-docker-image=varnish:6.0
ddev add-on get ddev/ddev-varnish
ddev restart
```

Make sure to commit the `.ddev/.env.varnish` file to version control.

All customization options (use with caution):

| Variable                  | Flag                        | Default                                                                                                            |
|---------------------------|-----------------------------|--------------------------------------------------------------------------------------------------------------------|
| `VARNISH_DOCKER_IMAGE`    | `--varnish-docker-image`    | `varnish:6.0`                                                                                                      |
| `VARNISH_VARNISHD_PARAMS` | `--varnish-varnishd-params` | `-p http_max_hdr=1000 -p http_resp_hdr_len=1M -p http_resp_size=2M -p workspace_backend=3M -p workspace_client=3M` |

### VARNISH_VARNISHD_PARAMS

Allows modifying the varnish [startup parameters](https://varnish-cache.org/docs/6.0/reference/varnishd.html).

The provided defaults are set deliberately higher than what varnish usually defines.
The reason for this is that in development environments it is not uncommon to
have larger payloads either in HTML or HTTP-Headers. E.g. Drupals theme debugging
or cache tag handling.
Without increasing these limits, one might encounter hard to isolate errors like the following form nginx:
```
2025/07/15 09:01:01 [info] 1549#1549: *259 writev() failed (32: Broken pipe) while sending to client, client: 172.20.0.6, server: , request: "GET /en HTTP/1.1", upstream: "fastcgi://unix:/run/php-fpm.sock:", host: "myproject.ddev.site"
```

## Credits

**Maintained by [@jedubois](https://github.com/jedubois) and the [DDEV team](https://ddev.com/support-ddev/)**

**Based on the original [ddev-contrib recipe](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/varnish) pioneered by [rikwillems](https://github.com/rikwillems)**
