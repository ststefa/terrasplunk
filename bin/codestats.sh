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

# Unfortunately tflint is quite useless on non-AWS. Anyway...
echo "Linting..."
# https://stackoverflow.com/questions/91368/checking-from-shell-script-if-a-directory-contains-files
shopt -s nullglob dotglob
for D in $(find ${CODE_DIRS} -type d |grep -v "\..*") ; do
    FILES=($D/*.tf)
    if [ ${#FILES[@]} -gt 0 ] ; then
        echo $D
        cd $D
        tflint --module --deep
        cd - > /dev/null
    fi
done
