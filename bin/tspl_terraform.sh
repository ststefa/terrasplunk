#!/bin/bash
# $Id: 2020-04-26 ssteine2 $
# shell wrapper to perform administrative commands with the terrasplunk module

BASEDIR="$(dirname "$(dirname "$(readlink -f "${0}")")")" || exit 1

list_targets() {
    if (( $# < 2 )) ; then
        echo "list: wrong number of arguments" >&2
        return 1
    fi

    TENANT=${1}
    STAGE=${2}
    shift;shift
    FILTER="${*}"

    set -x
    # shellcheck disable=SC2086
    "${BASEDIR}/bin/serverlist.py" ${FILTER} "${TENANT}" "${STAGE}" || return 1
    { set +x; } 2> /dev/null
}

do_terraform() {
    if (( $# < 3 )) ; then
        echo "${1}: wrong number of arguments" >&2
        return 1
    fi

    OPERATION=${1}
    TENANT=${2}
    STAGE=${3}
    shift;shift;shift
    FILTER=${*}

    # figure out proper terraform workspace
    if [ "${TENANT}" == "tsch_rz_t_001" ] ; then
        WORKSPACE="default"
    elif [ "${TENANT}" == "tsch_rz_p_001" ] ; then
        WORKSPACE="production"
        echo "WARNING! You're about to make changes to the production hardware layer. This is a"
        echo "dangerous operation. Please confirm that this is really what you want to do and"
        echo "you understand the possible consequences by answering 'KEN SENT ME'"
        read -rp "Who sent you? " ANSWER
        if [[ ${ANSWER} != "KEN SENT ME" ]] ; then
            echo "Aborting"
            return 1
        fi
    else
        echo "No such tenant \"${TENANT}\". Choose between tsch_rz_t_001 or tsch_rz_p_001" >&2
        return 1
    fi

    # change to terraform directory
    if [ "${STAGE}" == "shared" ] ; then
        cd "${BASEDIR}/shared" || return 1
    else
        if [ -d "${BASEDIR}/stages/${STAGE}" ] ; then
            cd "${BASEDIR}/stages/${STAGE}" || return 1
        else
            echo "No such stage \"${STAGE}\"" >&2
            return 1
        fi
    fi

    # switch to requested terraform workspace
    set -x
    terraform workspace select ${WORKSPACE} 2>/dev/null
    RC=${?}
    { set +x; } 2> /dev/null
    if (( RC != 0 )) ; then
        set -x
        terraform workspace new ${WORKSPACE} || return 1
        { set +x; } 2> /dev/null
    fi

    case "${OPERATION}" in
    init)
        set -x
        terraform init -upgrade=true || return 1
        { set +x; } 2> /dev/null
        ;;
    apply|destroy)
        if [ "${STAGE}" == "shared" ] ; then
            # there are no vms in shared so just do operation
            set -x
            terraform "${OPERATION}" "${PARALLELISM}" || return 1
            { set +x; } 2> /dev/null
        else
            PARALLELISM="-parallelism=20"
            if [ -n "${FILTER}" ] ; then
                if [[ "${FILTER}" =~ ^--target  ]]; then
                    # strip off first "-"
                    SERVERLIST="${FILTER:1}"
                else
                    # Generate target list by querying terraform state data.
                    # Beware that this is only possible for *already existing*
                    # servers.
                    # shellcheck disable=SC2086
                    SERVERLIST="$("${BASEDIR}/bin/serverlist.py" ${FILTER} --format=-target=module.server-%type%num | paste -sd' ')"
                    { set +x; } 2> /dev/null
                    if [ -z "${SERVERLIST}" ] ; then
                        echo "Could not compile serverlist for filter \"${FILTER}\". Either there is no such instance or the filter was specified wrongly." >&2
                        return 1
                    fi
                fi
            fi
            set -x
            # shellcheck disable=SC2086
            terraform "${OPERATION}" "${PARALLELISM}" ${SERVERLIST} || return 1
            { set +x; } 2> /dev/null
        fi
        ;;
    *)
        echo "Unknown operation ${1}, error in callers case statement" >&2
        return 1
        ;;
   esac
}

do_lock() {
    if (( $# < 2 )) ; then
        echo "lock: wrong number of arguments" >&2
        return 1
    fi

    TENANT=${1}
    STAGE=${2}

    set -x
    "${BASEDIR}/bin/lock_s3_state.py" "${TENANT}" "${STAGE}" || return 1
    { set +x; } 2> /dev/null
}

usage() {
    echo "Usage: $(basename "$0") (<operation> <tenant> <stage> (<filter>)) | (-h|--help)"
}

case $1 in
    list)
        shift
        list_targets "$@"
        ;;
    apply|destroy|init)
        OP=$1
        shift
        do_terraform "$OP" "$@"
        ;;
    lock)
        shift
        do_lock "$@"
        ;;
    -h|--help)
        echo 'Execute terraform activities'
        usage
        echo 'where:'
        echo '  operation: an terraform operation, one of:'
        echo '      list     list of targeted VMs. Useful for testing filters.'
        echo '      apply    apply terraform model'
        echo '      destroy  destroy terraform model. Use with caution!'
        echo '      init     install missing providers and modules into terraform workspace'
        echo '      lock     lock terraform state. Safety net to prevent errors.'
        echo '  tenant: target tenant, one of:'
        echo '      tsch_rz_t_001   test tenant'
        echo '      tsch_rz_p_001   production tenant'
        echo '  stage:  target stage, one of:'
        echo '      g0       global'
        echo '      h0       historic'
        echo '      p0       production'
        echo '      t0       test'
        echo '      w0       spielwiese'
        echo '      shared   shared state, e.g. networking and security groups'
        echo '  filter: optional filters to narrow down the operation to a subset of target'
        echo '          instances. If multiple filters are used they will be logically'
        echo '          and-ed. Filters accept regex expressions, e.g. "--type '\''(ix|sh)'\''"'
        echo '          Available filters are:'
        echo '      --az     Only instances in this availability zone, one of 1 or 2'
        echo '      --type   Only instances of this type/these types, one or more of'
        echo '               ix : indexers'
        echo '               sh : searchheads'
        echo '               (more types exist, please see http://admin.splunk.sbb.ch/topology)'
        echo '      --num    Only instances with this number (last three digits). The number'
        echo '               is compared using regex so make sure to always specify all three'
        echo '               digits (e.g. "--num 001")'
        echo '      --target Specify a single terraform server module. This is the only'
        echo '               possible filter for non-existing servers, i.e. if a new server is'
        echo '               added. Specify the module as "module.server-<type><num>", e.g.'
        echo '               "--target=module.server-ix005"'

        ;;
    *)
        echo "Unknown operation ${1}" >&2
        usage >&2
        exit 1
        ;;
esac

exit ${?}
