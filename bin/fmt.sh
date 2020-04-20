#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit

echo "Formatting..."
cd "${BASE_DIR}" || exit
terraform fmt -recursive
