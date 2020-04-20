#!/bin/bash
# $Id: 20191101 ssteine2 $

# Upgrade terraform modules/plugins

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"
TF_DIRS="${BASE_DIR}/shared ${BASE_DIR}/stages/??"

for DIR in ${TF_DIRS} ; do
    echo "Upgrading ${DIR}"
    cd ${DIR} && \
    terraform init --upgrade ; \
    cd - > /dev/null || exit
done
