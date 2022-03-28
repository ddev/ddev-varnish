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

## Additional Configuration
* You may want to edit the `.ddev/varnish/default.vcl` to meet your needs.


**Maintained by [@rfay](https://github.com/rfay)**

**Based on the original [ddev-contrib recipe](https://github.com/drud/ddev-contrib/tree/master/docker-compose-services/varnish) pioneered by [rikwillems](https://github.com/rikwillems)**


