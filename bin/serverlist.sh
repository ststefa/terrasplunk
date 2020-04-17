#!/bin/bash
# produce a list of hostnames based on terraform state

declare -a EVEN_INSTANCES
declare -a ODD_INSTANCES

for MOD in $(terraform state list | grep opentelekomcloud_compute_instance_v2 | grep -o 'server-[^.]*') ; do
    INSTANCE_NUM=${MOD: -3}
    HOSTNAME="spl$(basename "$(pwd)")${MOD##*-}"
    if [ $(( ${INSTANCE_NUM} % 2 )) == 0 ] ; then
        EVEN_INSTANCES+=("${HOSTNAME}")
    else
        ODD_INSTANCES+=("${HOSTNAME}")
    fi
done

if (( ${#EVEN_INSTANCES[@]} > 0 )) ; then
    echo "even"
    for HOSTNAME in "${EVEN_INSTANCES[@]}" ; do
        echo "${HOSTNAME}"
    done
fi

if (( ${#ODD_INSTANCES[@]} > 0 )) ; then
    echo "odd"
    for HOSTNAME in "${ODD_INSTANCES[@]}" ; do
        echo "${HOSTNAME}"
    done
fi
