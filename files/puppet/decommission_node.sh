#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "certname of node to decommission needed"

NODE=$1

# Deactivate in puppetdb to cause exported resources to expire out
curl -X POST \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d "{\"certname\":\"${NODE}\"}" \
"http://localhost:8080/pdb/cmd/v1?certname=${NODE}&command=deactivate_node&version=3"

# Clean up the node certificate so that it can't be used anymore
/opt/puppetlabs/bin/puppet node clean ${NODE}
