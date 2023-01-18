setup() {
  set -eu -o pipefail
  export DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)/.."
  export TESTDIR=~/tmp/testvarnish
  mkdir -p $TESTDIR
  export PROJNAME=test-varnish
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --additional-hostnames=extrahostname --additional-fqdns=extrafqdn.ddev.site --omit-containers=dba,db >/dev/null
  printf "<?php\nphpinfo();\n" >index.php
  ddev start >/dev/null
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || (printf "unable to cd to ${TESTDIR}\n" && exit 1)
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR} >/dev/null
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

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get drud/ddev-varnish with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get drud/ddev-varnish >/dev/null
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
