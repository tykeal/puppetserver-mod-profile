#!/bin/bash

# vi: ts=4 sw=4 sts=4 et

# grab a lock against ourselves
# shellcheck disable=SC2015
[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

if [ $# -lt 2 ]; then
    echo 1>&2 "$0: not enough arguments"
    exit 2
fi

DPKG=/bin/dpkg-scanpackages
TREE=$1; shift

# Switch to the repo and execute our package scan against the tree and compress
# the resultant Packages file
for REPO in "$@"
do
    pushd "${REPO}"
    $DPKG -m "${TREE}" > Packages
    cp Packages Packages.bak
    gzip --force Packages
    mv Packages.bak Packages
    popd
done
