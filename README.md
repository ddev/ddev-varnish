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
> Run `ddev add-on get ddev/ddev-varnish` after changes to `name`, `additional_hostnames`, `additional_fqdns`, or `project_tld` in `.ddev/config.yaml` so that `.ddev/docker-compose.varnish_extras.yaml` is regenerated.

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

The Varnish service inserts itself between ddev-router and the web container, so that calls to the web container are routed through Varnish first. The [docker-compose.varnish.yaml](docker-compose.varnish.yaml) installs Varnish and uses the default domain as its own host name.

A `docker-compose.varnish_extras.yaml` file is generated on install which replaces the `VIRTUAL_HOST` variable of the web container with a sub-domain of the website URL. For example, `mysite.ddev.site`, would be accessible via Varnish on `mysite.ddev.site` and directly on `novarnish.mysite.ddev.site`.

If you use a `project_tld` other than `ddev.site` or `additional_fqdns` DDEV will help add hosts entries for the hostnames automagically; however, you'll need to add entries for the `novarnish.*` sub-domains yourself, e.g. `ddev hostname novarnish.testaddfqdn.random.tld 127.0.0.1`. You can also use `ddev create-novarnish-hosts` which will call the `ddev hostname` command for all domains without a `novarnish.*` host entry. 

## Helper Commands

This add-on also providers several helper commands. These helpers allow developers to run Varnish commands from the host, however, the commands are actually run inside the Varnish container.

| Command | Description |
| --- | --- |
| `ddev varnishd` | Varnish-cli |
| `ddev varnishadm` | Control a running Varnish instance |
| `ddev varnishhist` | Display Varnish request histogram |
| `ddev varnishlog` | Display Varnish logs |
| `ddev varnishncsa` | Display Varnish logs in Apache / NCSA combined log format |
| `ddev varnishstat` | Display Varnish Cache statistics |
| `ddev varnishtest` | Test program for Varnish |
| `ddev varnishtop` | Display Varnish log entry ranking |
| `ddev logs -s varnish` | Check Varnish logs |

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

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `VARNISH_DOCKER_IMAGE` | `--varnish-docker-image` | `varnish:6.0` |

## Credits

**Maintained by [@jedubois](https://github.com/jedubois) and the [DDEV team](https://ddev.com/support-ddev/)**

**Based on the original [ddev-contrib recipe](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/varnish) pioneered by [rikwillems](https://github.com/rikwillems)**
