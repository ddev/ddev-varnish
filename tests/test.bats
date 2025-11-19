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
  export CUSTOM_VARNISH_VARNISHD_PARAMS=false
  export ROUTER_HTTP_PORT=80
  export ROUTER_HTTPS_PORT=443
  export MAILPIT_HTTP_PORT=8025
  export MAILPIT_HTTPS_PORT=8026
  export PHP_EXTRA_HTTP_PORT=
  export PHP_EXTRA_HTTPS_PORT=
}

health_checks() {
  # Check that bash is available in the varnish container
  run ddev exec -s varnish command -v bash
  assert_success
  assert_output --partial "bash"

  # Test that .ddev/docker-compose.varnish_extra.yaml created correct env vars
  run ddev exec echo "\$HTTP_EXPOSE"
  assert_success
  if [[ ${PHP_EXTRA_HTTP_PORT} != "" ]]; then
    assert_output "${MAILPIT_HTTP_PORT}:8025,${PHP_EXTRA_HTTP_PORT}:20080"
  else
    assert_output "${MAILPIT_HTTP_PORT}:8025"
  fi

  run ddev exec echo "\$HTTPS_EXPOSE"
  assert_success
  if [[ ${PHP_EXTRA_HTTPS_PORT} != "" ]]; then
    assert_output "${MAILPIT_HTTPS_PORT}:8025,${PHP_EXTRA_HTTPS_PORT}:20080"
  else
    assert_output "${MAILPIT_HTTPS_PORT}:8025"
  fi

  local varnish_urls=(
    "http://${PROJNAME}.ddev.site:${ROUTER_HTTP_PORT}"
    "http://extrahostname.ddev.site:${ROUTER_HTTP_PORT}"
    "http://extrafqdn.ddev.site:${ROUTER_HTTP_PORT}"
    "https://${PROJNAME}.ddev.site:${ROUTER_HTTPS_PORT}"
    "https://extrahostname.ddev.site:${ROUTER_HTTPS_PORT}"
    "https://extrafqdn.ddev.site:${ROUTER_HTTPS_PORT}"
  )

  for url in "${varnish_urls[@]}"; do
    # Test for Varnish headers (case-sensitive: "Via:" for HTTP, "via:" for HTTPS)
    run curl -sfI "$url"
    assert_success
    if [[ "$url" == https://* ]]; then
      assert_output --partial "via: 1.1 varnish (Varnish/6.0)"
      assert_output --partial "x-varnish:"
    else
      assert_output --partial "Via: 1.1 varnish (Varnish/6.0)"
      assert_output --partial "X-Varnish:"
    fi

    # Test for phpinfo content
    run curl -sf "$url"
    assert_success
    assert_output --partial "allow_url_fopen"
  done

  local mailpit_urls=(
    "http://${PROJNAME}.ddev.site:${MAILPIT_HTTP_PORT}"
    "http://extrahostname.ddev.site:${MAILPIT_HTTP_PORT}"
    "http://extrafqdn.ddev.site:${MAILPIT_HTTP_PORT}"
    "https://${PROJNAME}.ddev.site:${MAILPIT_HTTPS_PORT}"
    "https://extrahostname.ddev.site:${MAILPIT_HTTPS_PORT}"
    "https://extrafqdn.ddev.site:${MAILPIT_HTTPS_PORT}"
  )

  for url in "${mailpit_urls[@]}"; do
    # Test that there are no Varnish headers for Mailpit
    run curl -sfI "$url"
    assert_failure
    if [[ "$url" == https://* ]]; then
      assert_output --partial "HTTP/2 405"
      refute_output --partial "via: 1.1 varnish (Varnish/6.0)"
      refute_output --partial "x-varnish:"
    else
      assert_output --partial "HTTP/1.1 405"
      refute_output --partial "Via: 1.1 varnish (Varnish/6.0)"
      refute_output --partial "X-Varnish:"
    fi

    run curl -sf "$url"
    assert_success
    assert_output --partial "You need a browser with JavaScript enabled to use Mailpit"

    run curl -sf "$url/api/v1/info"
    assert_success
    assert_output --partial "Messages"
    assert_output --partial "Unread"
    assert_output --partial "RuntimeStats"
  done

  if [[ ${PHP_EXTRA_HTTP_PORT} != "" && ${PHP_EXTRA_HTTPS_PORT} != "" ]]; then
    local php_extra_urls=(
      "http://${PROJNAME}.ddev.site:${PHP_EXTRA_HTTP_PORT}"
      "http://extrahostname.ddev.site:${PHP_EXTRA_HTTP_PORT}"
      "http://extrafqdn.ddev.site:${PHP_EXTRA_HTTP_PORT}"
      "https://${PROJNAME}.ddev.site:${PHP_EXTRA_HTTPS_PORT}"
      "https://extrahostname.ddev.site:${PHP_EXTRA_HTTPS_PORT}"
      "https://extrafqdn.ddev.site:${PHP_EXTRA_HTTPS_PORT}"
    )

    for url in "${php_extra_urls[@]}"; do
      # Test that there are no Varnish headers for web_extra_exposed_ports
      run curl -sfI "$url"
      assert_success
      if [[ "$url" == https://* ]]; then
        refute_output --partial "via: 1.1 varnish (Varnish/6.0)"
        refute_output --partial "x-varnish:"
      else
        refute_output --partial "Via: 1.1 varnish (Varnish/6.0)"
        refute_output --partial "X-Varnish:"
      fi

      run curl -sf "$url"
      assert_output "php-extra"
    done
  fi

  if [ "${CUSTOM_VARNISH_VARNISHD_PARAMS}" = "true" ]; then
    run ddev varnishadm param.show http_max_hdr
    assert_success
    assert_output --partial 'Value is: 123 [header lines]'

    run ddev varnishadm param.show http_resp_hdr_len
    assert_success
    assert_output --partial 'Value is: 16k [bytes]'
  else
    run ddev varnishadm param.show http_max_hdr
    assert_success
    assert_output --partial 'Value is: 1000 [header lines]'

    run ddev varnishadm param.show http_resp_hdr_len
    assert_success
    assert_output --partial 'Value is: 1M [bytes]'

    run ddev varnishadm param.show http_resp_size
    assert_success
    assert_output --partial 'Value is: 2M [bytes]'

    run ddev varnishadm param.show workspace_backend
    assert_success
    assert_output --partial 'Value is: 3M [bytes]'

    run ddev varnishadm param.show workspace_client
    assert_success
    assert_output --partial 'Value is: 3M [bytes]'
  fi
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
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
  health_checks
}

@test "install from directory with nonstandard port" {
  set -eu -o pipefail
  export ROUTER_HTTP_PORT=8080
  export ROUTER_HTTPS_PORT=8443
  export MAILPIT_HTTP_PORT=18025
  export MAILPIT_HTTPS_PORT=18026
  export PHP_EXTRA_HTTP_PORT=20080
  export PHP_EXTRA_HTTPS_PORT=20443

  run ddev config --router-http-port="${ROUTER_HTTP_PORT}" --router-https-port="${ROUTER_HTTPS_PORT}" --mailpit-http-port="${MAILPIT_HTTP_PORT}" --mailpit-https-port="${MAILPIT_HTTPS_PORT}"
  assert_success

  mkdir -p php-extra
  assert_dir_exist php-extra

  printf "<?php\necho 'php-extra' . PHP_EOL;\n" >php-extra/index.php
  assert_file_exists php-extra/index.php

  cat >>.ddev/config.yaml <<'EOF'
web_extra_daemons:
    - name: "php-extra"
      command: "php -S 0.0.0.0:20080"
      directory: /var/www/html/php-extra
web_extra_exposed_ports:
    - name: "php-extra"
      container_port: 20080
      http_port: 20080
      https_port: 20443
EOF

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "customize varnishd startup parameters" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev dotenv set .ddev/.env.varnish --varnish-varnishd-params='-p http_max_hdr=123 -p http_resp_hdr_len=16k'
  assert_success
  run cat .ddev/.env.varnish
  assert_success
  assert_output 'VARNISH_VARNISHD_PARAMS="-p http_max_hdr=123 -p http_resp_hdr_len=16k"'
  run ddev restart -y
  assert_success
  export CUSTOM_VARNISH_VARNISHD_PARAMS=true
  health_checks
}

@test "test varnish config reload" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  run ddev varnish-config-reload
  assert_success
  assert_output --partial 'Loading vcl from /etc/varnish/default.vcl'
  assert_output --partial 'VCL compiled'
  assert_output --partial 'now active'
  health_checks
}