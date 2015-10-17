#!/bin/bash

function rebuild-openshift-image() {
  source "$(dirname ${BASH_SOURCE})/../common.sh"

  set -e

  image="$1"

  tmpdir="$(mktemp -d)"
  openshiftbin="$(which openshift)"

  info "Copying openshift binary to temporary work directory ..."
  cp -av "${openshiftbin}" "${tmpdir}"

  # Find parent image id to avoid stacking multiple COPY layers
  parent=$(docker history --no-trunc ${image} | \
           grep -v 'COPY file.*in /usr/bin/openshift' | \
           awk 'NR==2 {print $1}')

  # Write Dockerfile
  set +e
  read -d '' Dockerfile <<EOF
  FROM ${parent}

  COPY openshift /usr/bin/openshift
EOF
  set -e
  echo "${Dockerfile}" > ${tmpdir}/Dockerfile

  info "Building Docker image ${image} ..."
  docker build -t "${image}" "${tmpdir}"

  # Cleanup
  rm -vrf "${tmpdir}"

  info "Done."
}
