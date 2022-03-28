[![tests](https://github.com/drud/ddev-varnish/actions/workflows/tests.yml/badge.svg)](https://github.com/drud/ddev-varnish/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2022.svg)

# ddev-varnish

This repository allows you to quickly install the varnish reverse proxy into a [Ddev](https://ddev.readthedocs.io) project using just `ddev get drud/ddev-varnish`.

## Installation

1. `ddev get drud/ddev-varnish`
2. `ddev restart`

## Explanation 

The Varnish service inserts itself between ddev-router and the web container, so that calls
to the web container are routed through Varnish first. The [docker-compose.varnish.yaml](https://github.com/drud/ddev-contrib/blob/master/docker-compose-services/varnish/docker-compose.varnish.yml)
replaces the ```VIRTUAL_HOST``` variable of the web container with a subdomain of
the website URL (see below) and uses the default domain as its own host name.

To enable Varnish in your project follow these steps:

1. Copy [docker-compose.varnish.yaml](https://github.com/drud/ddev-contrib/blob/master/docker-compose-services/varnish/docker-compose.varnish.yml) into your project's .ddev directory.
2. Create a directory named _varnish_ in your project's .ddev directory.
3. Copy the [default.vcl](default.vcl) in this directoy.
4. Run `ddev start`.
5. From now on calls to the web container (e.g. `https://example.ddev.site`) are
   routed through Varnish. If you would like to access the site without Varnish,
   simply prepend the URL with _novarnish._ (e.g. `https://novarnish.example.ddev.site`).

---

**Based on the work of [rikwillems](https://github.com/rikwillems)**

**Contributed and maintained by [@CONTRIBUTOR](https://github.com/CONTRIBUTOR) based on the original [ddev-contrib recipe](https://github.com/drud/ddev-contrib/tree/master/docker-compose-services/RECIPE) by [@CONTRIBUTOR](https://github.com/CONTRIBUTOR)**

**Originally Contributed by [somebody](https://github.com/somebody) in https://github.com/drud/ddev-contrib/...)


