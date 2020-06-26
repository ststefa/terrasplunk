#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"
CODE_DIRS="${BASE_DIR}/modules ${BASE_DIR}/shared ${BASE_DIR}/stages"

echo "Lines of terraform code (excluding comments and empty lines)"
while read -r FILE ; do
    cat "${FILE}" | grep -v '^\ *#' | grep -v '^\ *$'
done < <(find ${CODE_DIRS} -name "*.tf") | wc -l

echo "Lines of comments in terraform code"
while read -r FILE ; do
    cat "${FILE}" | grep '^\ *#'
done < <(find ${CODE_DIRS} -name "*.tf") | wc -l
