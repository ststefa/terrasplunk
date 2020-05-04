#!/bin/bash
# $Id: 2020-04-26 ssteine2 $
# shell wrapper to perform administrative commands with the terrasplunk module

BASEDIR="$(cd "$(dirname "$0")" && cd .. && pwd)" || exit 1

if [ -z "${TF_VAR_username}" ] || [ -z "${TF_VAR_password}" ] ; then
    echo "Your terraform credentials are not exported to the shell. Please export them like so:" >&2
    echo "    export TF_VAR_username=<your-otc-tenant-username>" >&2
    echo "    export TF_VAR_password=<your-otc-tenant-password>" >&2
    exit 1
fi

list_targets() {
    TENANT=${1}
    STAGE=${2}
    shift;shift
    FILTER="${*}"

    # shellcheck disable=SC2086
    "${BASEDIR}/bin/serverlist.py" ${FILTER} "${TENANT}" "${STAGE}"
}

do_terraform() {
    if (( $# < 3 )) ; then
        echo "${FUNCNAME[0]}: wrong number of arguments" >&2
        return 1
    fi

    OPERATION=${1}
    TENANT=${2}
    STAGE=${3}
    shift;shift;shift
    FILTER=${*}

    if [ "${TENANT}" == "tsch_rz_t_001" ] ; then
        WORKSPACE="default"
    elif [ "${TENANT}" == "tsch_rz_p_001" ] ; then
        WORKSPACE="production"
        echo "WARNING! You're about to make changes to the production hardware layer. This is a"
        echo "dangerous operation. Please confirm that this is really what you want to do and"
        echo "you understand the possible consequuences by answering 'KEN SENT ME'"
        read -rp "Who sent you? " ANSWER
        if [[ ${ANSWER} != "KEN SENT ME" ]] ; then
            echo "Aborting"
            return 1
        fi
    else
        echo "No such tenant \"${TENANT}\". Choose between tsch_rz_t_001 or tsch_rz_p_001" >&2
        return 1
    fi

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

    terraform workspace select ${WORKSPACE} 2>/dev/null
    # shellcheck disable=SC2181
    if (( $? != 0 )) ; then
        terraform workspace new ${WORKSPACE} || return 1
    fi
    if [ -z "${FILTER}" ] ; then
        terraform "${OPERATION}"
    else
        if [ "${STAGE}" == "shared" ] ; then
            terraform "${OPERATION}"
        else
            # shellcheck disable=SC2086
            SERVERLIST=$("${BASEDIR}/bin/serverlist.py" ${FILTER} --format=-target=module.server-%type%num | paste -sd" ")
            if [ -z "${SERVERLIST}" ] ; then
                echo "Could not compile serverlist for filter \"${FILTER}\". Either there is no such instance or the filter was specified wrongly." >&2
                return 1
            else
                # shellcheck disable=SC2086
                terraform "${OPERATION}" ${SERVERLIST}
            fi
        fi
    fi
}

do_lock() {
    if (( $# < 2 )) ; then
        echo "${FUNCNAME[0]}: wrong number of arguments" >&2
        return 1
    fi

    TENANT=${1}
    STAGE=${2}
    "${BASEDIR}/bin/lock_s3_state.py" "${TENANT}" "${STAGE}"
}

usage() {
    echo "Usage: $(basename "$0") (<operation> <tenant> <stage> (<filter>)) | (-h|--help)"
}

case $1 in
    list)
        shift
        list_targets "$@"
        ;;
    apply|destroy)
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
        echo '      lock     lock terraform state.Safety net to prevent errors.'
        echo '  tenant: target tenant, one of:'
        echo '      tsch_rz_t_001   test tenant'
        echo '      tsch_rz_p_001   production tenant'
        echo '  stage:  target stage, one of:'
        echo '      g0       global'
        echo '      h0       historic'
        echo '      p0       production'
        echo '      t0       test'
        echo '      w0       spielwiese'
        echo '      shared : shared state, e.g. networking and security groups'
        echo '  filter: optional filters to narrow down the operation to a subset of target instances.'
        echo '          If multiple filters are used they will be logically and-ed. Filters accept'
        echo '          regex expressions, e.g. "--type '\''(ix|sh)'\''" Available filters are:'
        echo '      --az    Only instances in this availability zone, one of 1 or 2'
        echo '      --type  Only instances of this type/these types, one or more of'
        echo '              ix : indexers'
        echo '              sh : searchheads'
        echo '              (more types exist, please see http://admin.splunk.sbb.ch/topology)'
        echo '      --num   Only instances with this number (last three digits). The number is compared'
        echo '              using regex so make sure to always specify all three digits'
        ;;
    *)
        usage >&2
        false
        ;;
esac

exit ${?}
