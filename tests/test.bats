setup() {
  set -eu -o pipefail
  export DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)/.."
  export TESTDIR=~/tmp/testvarnish
  mkdir -p $TESTDIR
  export PROJNAME=test-varnish
  export DDEV_NONINTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --additional-hostnames=extrahostname --additional-fqdns=extrafqdn.ddev.site --omit-containers=db
  printf "<?php\nphpinfo();\n" >index.php
  ddev start -y >/dev/null
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR} >/dev/null
  ddev restart >/dev/null 2>&1
  for url in http://${PROJNAME}.ddev.site/ http://extrahostname.ddev.site/ http://extrafqdn.ddev.site/ https://${PROJNAME}.ddev.site/ https://extrahostname.ddev.site/ https://extrafqdn.ddev.site/ ; do
    # It's "Via:" with http and "via:" with https. Tell me why.
    echo "# test $url for via:.*varnish header" >&3
    curl -sI $url | grep -i "Via:.*varnish" >/dev/null || (echo "# varnish headers not shown for $url"  >&3 && exit 1);
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  for url in http://novarnish.${PROJNAME}.ddev.site/ http://novarnish.extrahostname.ddev.site/ http://novarnish.extrafqdn.ddev.site/ https://novarnish.${PROJNAME}.ddev.site/ https://novarnish.extrahostname.ddev.site/ https://novarnish.extrafqdn.ddev.site/ ; do
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  echo "# test http://${PROJNAME}.ddev.site:8025 for http novarnish redirect" >&3
  curl -sI "http://${PROJNAME}.ddev.site:8025" | grep -i "http://novarnish.${PROJNAME}.ddev.site:8025/" >/dev/null || (echo "# http://${PROJNAME}.ddev.site:8025 did not redirect" >&3 && exit 1);
  echo "# test https://${PROJNAME}.ddev.site:8026 for https novarnish redirect" >&3
  curl -sI "https://${PROJNAME}.ddev.site:8026" | grep -i "https://novarnish.${PROJNAME}.ddev.site:8026/" >/dev/null || (echo "# https://${PROJNAME}.ddev.site:8026 did not redirect" >&3 && exit 1);
}

@test "install from directory with nonstandard port" {
  set -eu -o pipefail
  cd ${TESTDIR}
  ddev config --router-http-port 8080 --router-https-port 8443 --mailpit-http-port 18025 --mailpit-https-port 18026
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR} >/dev/null
  ddev restart >/dev/null 2>&1
  for url in http://${PROJNAME}.ddev.site:8080/ http://extrahostname.ddev.site:8080/ http://extrafqdn.ddev.site:8080/ https://${PROJNAME}.ddev.site:8443/ https://extrahostname.ddev.site:8443/ https://extrafqdn.ddev.site:8443/ ; do
    # It's "Via:" with http and "via:" with https. Tell me why.
    echo "# test $url for via:.*varnish header" >&3
    curl -sI $url | grep -i "Via:.*varnish" >/dev/null || (echo "# varnish headers not shown for $url"  >&3 && exit 1);
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  for url in http://novarnish.${PROJNAME}.ddev.site:8080/ http://novarnish.extrahostname.ddev.site:8080/ http://novarnish.extrafqdn.ddev.site:8080/ https://novarnish.${PROJNAME}.ddev.site:8443/ https://novarnish.extrahostname.ddev.site:8443/ https://novarnish.extrafqdn.ddev.site:8443/ ; do
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  echo "# test http://${PROJNAME}.ddev.site:18025 for http novarnish redirect" >&3
  curl -sI "http://${PROJNAME}.ddev.site:18025" | grep -i "http://novarnish.${PROJNAME}.ddev.site:18025/" >/dev/null || (echo "# http://${PROJNAME}.ddev.site:18025 did not redirect" >&3 && exit 1);
  echo "# test https://${PROJNAME}.ddev.site:18026 for https novarnish redirect" >&3
  curl -sI "https://${PROJNAME}.ddev.site:18026" | grep -i "https://novarnish.${PROJNAME}.ddev.site:18026/" >/dev/null || (echo "# https://${PROJNAME}.ddev.site:18026 did not redirect" >&3 && exit 1);
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get ddev/ddev-varnish with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ddev/ddev-varnish >/dev/null
  ddev restart >/dev/null 2>&1
  for url in http://${PROJNAME}.ddev.site/ http://extrahostname.ddev.site/ http://extrafqdn.ddev.site/ https://${PROJNAME}.ddev.site/ https://extrahostname.ddev.site/ https://extrafqdn.ddev.site/ ; do
    # It's "Via:" with http and "via:" with https. Tell me why.
    echo "# test $url for via:.*varnish header" >&3
    curl -sI $url | grep -i "Via:.*varnish" >/dev/null || (echo "# varnish headers not shown for $url"  >&3 && exit 1);
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  for url in http://novarnish.${PROJNAME}.ddev.site/ http://novarnish.extrahostname.ddev.site/ http://novarnish.extrafqdn.ddev.site/ https://novarnish.${PROJNAME}.ddev.site/ https://novarnish.extrahostname.ddev.site/ https://novarnish.extrafqdn.ddev.site/ ; do
    echo "# test $url for phpinfo content" >&3
    curl -s $url | grep "allow_url_fopen" >/dev/null || (echo "# phpinfo information not shown in curl for $url" >&3 && exit 1);
  done
  echo "# test http://${PROJNAME}.ddev.site:8025 for http novarnish redirect" >&3
  curl -sI "http://${PROJNAME}.ddev.site:8025" | grep -i "http://novarnish.${PROJNAME}.ddev.site:8025/" >/dev/null || (echo "# http://${PROJNAME}.ddev.site:8025 did not redirect" >&3 && exit 1);
  echo "# test https://${PROJNAME}.ddev.site:8026 for https novarnish redirect" >&3
  curl -sI "https://${PROJNAME}.ddev.site:8026" | grep -i "https://novarnish.${PROJNAME}.ddev.site:8026/" >/dev/null || (echo "# https://${PROJNAME}.ddev.site:8026 did not redirect" >&3 && exit 1);
}
