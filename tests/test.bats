#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=ddev/ddev-varnish

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"

  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --additional-hostnames=extrahostname --additional-fqdns=extrafqdn.ddev.site
  assert_success

  printf "<?php\nphpinfo();\n" >index.php
  assert_file_exists index.php

  run ddev start -y
  assert_success
}

health_checks() {
  for url in http://${PROJNAME}.ddev.site:${ROUTER_HTTP_PORT}/ http://extrahostname.ddev.site:${ROUTER_HTTP_PORT}/ http://extrafqdn.ddev.site:${ROUTER_HTTP_PORT}/ https://${PROJNAME}.ddev.site:${ROUTER_HTTPS_PORT}/ https://extrahostname.ddev.site:${ROUTER_HTTPS_PORT}/ https://extrafqdn.ddev.site:${ROUTER_HTTPS_PORT}/ ; do
    # It's "Via:" with http and "via:" with https. Tell me why.
    echo "# test $url for via:.*varnish header" >&3
    curl -sfI $url | grep -i "Via:.*varnish" >/dev/null || (echo "# varnish headers not shown for $url" >&3 && exit 1);
    echo "# test $url for phpinfo content" >&3
    curl -sf $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done

  for url in http://novarnish.${PROJNAME}.ddev.site:${ROUTER_HTTP_PORT}/ http://novarnish.extrahostname.ddev.site:${ROUTER_HTTP_PORT}/ http://novarnish.extrafqdn.ddev.site:${ROUTER_HTTP_PORT}/ https://novarnish.${PROJNAME}.ddev.site:${ROUTER_HTTPS_PORT}/ https://novarnish.extrahostname.ddev.site:${ROUTER_HTTPS_PORT}/ https://novarnish.extrafqdn.ddev.site:${ROUTER_HTTPS_PORT}/ ; do
    echo "# test $url for phpinfo content" >&3
    curl -sf $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done

  echo "# test http://${PROJNAME}.ddev.site:${MAILPIT_HTTP_PORT}/ for http novarnish redirect" >&3
  curl -sfI "http://${PROJNAME}.ddev.site:${MAILPIT_HTTP_PORT}/" | grep -i "http://novarnish.${PROJNAME}.ddev.site:${MAILPIT_HTTP_PORT}/" >/dev/null || (echo "# http://${PROJNAME}.ddev.site:${MAILPIT_HTTP_PORT} did not redirect" >&3 && exit 1);
  echo "# test https://${PROJNAME}.ddev.site:${MAILPIT_HTTPS_PORT}/ for https novarnish redirect" >&3
  curl -sfI "https://${PROJNAME}.ddev.site:${MAILPIT_HTTPS_PORT}/" | grep -i "https://novarnish.${PROJNAME}.ddev.site:${MAILPIT_HTTPS_PORT}/" >/dev/null || (echo "# https://${PROJNAME}.ddev.site:${MAILPIT_HTTPS_PORT} did not redirect" >&3 && exit 1);
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  export ROUTER_HTTP_PORT=80 ROUTER_HTTPS_PORT=443 MAILPIT_HTTP_PORT=8025 MAILPIT_HTTPS_PORT=8026
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  export ROUTER_HTTP_PORT=80 ROUTER_HTTPS_PORT=443 MAILPIT_HTTP_PORT=8025 MAILPIT_HTTPS_PORT=8026
  health_checks
}

@test "install from directory with nonstandard port" {
  set -eu -o pipefail
  run ddev config --router-http-port=8080 --router-https-port=8443 --mailpit-http-port=18025 --mailpit-https-port=18026
  assert_success
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  export ROUTER_HTTP_PORT=8080 ROUTER_HTTPS_PORT=8443 MAILPIT_HTTP_PORT=18025 MAILPIT_HTTPS_PORT=18026
  health_checks
}
