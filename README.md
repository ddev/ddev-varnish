[![tests](https://github.com/drud/ddev-varnish/actions/workflows/tests.yml/badge.svg)](https://github.com/drud/ddev-varnish/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2022.svg)

# ddev-varnish

This repository allows you to quickly install the Varnish reverse proxy into a [DDEV](https://ddev.readthedocs.io) project using just `ddev get drud/ddev-varnish`.

## Installation

1. `ddev get drud/ddev-varnish`
2. `ddev restart`

## Explanation

The Varnish service inserts itself between ddev-router and the web container, so that calls
to the web container are routed through Varnish first. The [docker-compose.varnish.yaml](https://github.com/drud/ddev-contrib/blob/master/docker-compose-services/varnish/docker-compose.varnish.yml)
installs Varnish and uses the default domain as its own host name. A docker-compose.varnish-extras.yaml file is generated on install which replaces the ```VIRTUAL_HOST``` variable of the web container with a sub-domain of the website URL. For example, mysite.ddev.site, would be accessible via Varnish on mysite.ddev.site and directly on novarnish.mysite.ddev.site.

If you use a project_tld other than ddev.site or additional_fqdns DDEV will help add hosts entries for the hostnames automagically; however, you'll need to add entries for the novarnish.* sub-domains yourself, e.g. `ddev hostname novarnish.testaddfqdn.random.tld 127.0.0.1`.

Run `ddev get drud/ddev-varnish` after changes to name, additional_hostnames, additional_fqdns, or project_tld in .ddev/config.yml so that .ddev/docker-compose.varnish-extras.yaml is regenerated.

## Additional Configuration

* You may want to edit the `.ddev/varnish/default.vcl` to meet your needs. Remember to remove '#ddev-generated' from the file if you want your changes to the file preserved.

**Maintained by [@rfay](https://github.com/rfay)**

**Based on the original [ddev-contrib recipe](https://github.com/drud/ddev-contrib/tree/master/docker-compose-services/varnish) pioneered by [rikwillems](https://github.com/rikwillems)**
