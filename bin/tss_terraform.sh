#!/bin/bash
# $Id: 2020-04-26 ssteine2 $
# shell wrapper to perform administrative commands with the terrasplunk module

BASEDIR="$(cd "$(dirname "$0")" && cd .. && pwd)" || exit 1

if [ -z "${TF_VAR_username}" ] || [ -z "${TF_VAR_password}" ] ; then
    echo "Your terraform credentials are not exported. Please export them like so:" >&2
    echo "    export TF_VAR_username=<your-otc-tenant-username>" >&2
    echo "    export TF_VAR_password=<your-otc-tenant-password>" >&2
    exit 1
fi

do_terraform() {
    if (( $# < 3 )) ; then
        echo "${FUNCNAME[0]}: wrong number of arguments" >&2
        return 1
    fi

    TENANT=${1}
    STAGE=${2}
    OPERATION=${3}
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

    echo terraform workspace select ${WORKSPACE}
    if [ -z "${FILTER}" ] ; then
        terraform "${OPERATION}"
    else
        if [ "${STAGE}" == "shared" ] ; then
            terraform "${OPERATION}"
        else
            SERVERLIST=$("${BASEDIR}/bin/serverlist.py" ${FILTER} --format=-target=module.server-%type%num | paste -sd" ")
            if [ -z "${SERVERLIST}" ] ; then
                echo "could not compile serverlist for filter \"${FILTER}\". Either there is no such instance or the filter was specified wrongly." >&2
                return 1
            else
                terraform "${OPERATION}" ${SERVERLIST}
            fi
        fi
    fi
}

usage() {
    echo "Usage: $(basename "$0") (<tenant> <stage> <operation> (<filter>)) | (-h|--help)"
}

case $3 in
    apply)
        OP=$1
        shift 1
        do_terraform $OP "$@"
        ;;
    -h|--help)
        echo 'Execute terraform activities'
        usage
        echo 'where:'
        echo '  tenant: target tenant, one of:'
        echo '      tsch_rz_t_001: test tenant'
        echo '      tsch_rz_p_001: production tenant'
        echo '  stage:  target stage, one of:'
        echo '      g0:     global'
        echo '      h0:     historic'
        echo '      p0:     production'
        echo '      t0:     test'
        echo '      w0:     spielwiese'
        echo '      shared: shared state, e.g. networking and security groups'
        echo '  operation: an terraform operation, one of:'
        echo '      apply:   apply terraform model'
        echo '      destroy: destroy terraform model. Use with caution!'
        echo '  filter: optional filters to narrow down the operation to a subset of instances.'
        echo '          If multiple filters are used they will be logically and-ed. Available'
        echo '          filters are:'
        echo '      --az:   Only instances in this availability zone, one of 1 or 2'
        echo '      --type: Only instances in this availability zone, one of'
        echo '              ix: indexers'
        echo '              sh: searchheads'
        ;;
    *)
        usage >&2
        false
        ;;
esac

exit $?
