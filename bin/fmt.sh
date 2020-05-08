#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(dirname "$(dirname "$(readlink -f "${0}")")")" || exit 1

echo "Formatting..."
cd "${BASE_DIR}" || exit
terraform fmt -recursive
