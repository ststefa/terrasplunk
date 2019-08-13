#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(cd "$(dirname "$0")"/.. && pwd)" || exit "$(false)"
CODE_DIRS="${BASE_DIR}/modules ${BASE_DIR}/shared ${BASE_DIR}/stages"

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
