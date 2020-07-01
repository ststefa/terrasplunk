#!/bin/bash
# $Id: 20190726 ssteine2 $

#set -x

BASE_DIR="$(dirname "$(dirname "$(readlink -f "${0}")")")" || exit 1

CODE_DIRS="${BASE_DIR}/shared ${BASE_DIR}/stages ${BASE_DIR}/modules"

case $1 in
    check)
        TERRAFORM_ARGS="-check -diff"
        ;;
    apply)
        TERRAFORM_ARGS=""
        ;;
    *)
        echo "usage: $(basename ${0}) check | apply" >&2
        echo "where:" >&2
        echo "   check: show diffs, do not change files" >&2
        echo "   apply: apply formatting, changing files" >&2
        exit 1
        ;;
esac

while read -r DIR ; do
    shopt -s nullglob dotglob
    # https://stackoverflow.com/questions/91368/checking-from-shell-script-if-a-directory-contains-files
    FILES=("${DIR}"/*.tf)
    if [ ${#FILES[@]} -gt 0 ] ; then
        cd "${DIR}" || exit 1
        echo "Formatting terraform code in ${DIR} ..."
        terraform fmt ${TERRAFORM_ARGS}
        cd - > /dev/null || exit 1
    fi
done < <(find ${CODE_DIRS} -type d)
