#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"

# Unfortunately tflint is quite useless on non-AWS. Anyway...
echo "Formatting..."
cd ${BASE_DIR}
terraform fmt -recursive
