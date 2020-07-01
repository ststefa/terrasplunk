#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(dirname "$(dirname "$(readlink -f "${0}")")")" || exit 1
STAGE_DIRS="${BASE_DIR}/shared ${BASE_DIR}/stages"
MODULE_DIRS="${BASE_DIR}/modules"

# Unfortunately tflint is quite useless on non-AWS. Anyway...
echo "Linting modules ..."

# shellcheck disable=SC2086
while read -r DIR ; do
    shopt -s nullglob dotglob
    # https://stackoverflow.com/questions/91368/checking-from-shell-script-if-a-directory-contains-files
    FILES=("${DIR}"/*.tf)
    if [ ${#FILES[@]} -gt 0 ] ; then
        echo "${DIR}"
        cd "${DIR}" || exit 1
        tflint
        cd - > /dev/null || exit 1
    fi
done < <(find ${MODULE_DIRS} -type d)

echo "Linting stages ..."
# shellcheck disable=SC2086
while read -r DIR ; do
    shopt -s nullglob dotglob
    # https://stackoverflow.com/questions/91368/checking-from-shell-script-if-a-directory-contains-files
    FILES=("${DIR}"/*.tf)
    if [ ${#FILES[@]} -gt 0 ] ; then
        echo "${DIR}"
        cd "${DIR}" || exit 1
        tflint --module
        cd - > /dev/null || exit 1
    fi
done < <(find ${STAGE_DIRS} -type d)

echo "Terraform-validating stages ..."
# shellcheck disable=SC2086
while read -r DIR ; do
    FILES=("${DIR}"/*.tf)
    if [ ${#FILES[@]} -gt 0 ] ; then
        echo "${DIR}"
        cd "${DIR}" || exit 1
        terraform validate
        cd - > /dev/null || exit 1
    fi
done < <(find ${STAGE_DIRS} -type d)
