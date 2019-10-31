#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"

echo "Formatting..."
cd ${BASE_DIR}
terraform fmt -recursive
