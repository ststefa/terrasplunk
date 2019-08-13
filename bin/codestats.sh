#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"
CODE_DIRS="${BASE_DIR}/modules ${BASE_DIR}/shared ${BASE_DIR}/stages"

echo "Lines of terraform code"
for F in $(find ${CODE_DIRS} -name "*.tf") ; do
    cat $F
done | wc -l

echo "Lines of terraform code excluding comments"
for F in $(find ${CODE_DIRS} -name "*.tf") ; do
    cat $F | grep -v '^\ *#'
done | wc -l

echo "Lines of terraform code excluding comments and empty lines"
for F in $(find ${CODE_DIRS} -name "*.tf") ; do
    cat $F | grep -v '^\ *#' | grep -v '^\ *$'
done | wc -l
