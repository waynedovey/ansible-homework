#!/bin/bash
# CloudForms Retire Services - Guillaume Coré <gucore@redhat.com>
# this script is for automation only, be careful!
# because this script reads stdin, you have to set those environment variables:
# - username
# - password
# - uri

# safety options
set -e -o pipefail

ORIG="$(cd "$(dirname "$0")" || exit; pwd)"

# shellcheck source=common.sh
. "${ORIG}/common.sh"


usage() {
    echo "Error: Usage $0 [-u <username>] [ -w <uri> ]"
    echo
    echo "This script reads the input from STDIN. Each line should be ID NAME of service to retire."
    echo "ex:   . credentials.rc; ./get_svc.sh | grep 'OCP'| ./delete_svc.sh"
}

while getopts hu:w: FLAG; do
    case $FLAG in
        u) username="$OPTARG"
           export username
           ;;
        w) uri="$OPTARG"
           export uri
           ;;
        h) usage;exit;;
        *) usage;exit;;
    esac
done

if ! which jq > /dev/null; then
    echo >&2 "please install jq"
    exit 2
fi


while read -r itemID name; do
    # ensure (itemID name) couple makes sense
    remoteName=$(cfget "${uri}/api/services/${itemID}?attributes=name\&expand=resources" \
                     | jq -r '.name')

    if [ "${name}" != "${remoteName}" ]; then
        echo >&2 "name provided with id does not match remote name: ${name} != ${remoteName}"
        exit 2
    fi

    PAYLOAD="{ \"action\": \"retire\" }"

    cfpost \
        -d "${PAYLOAD}" \
        "${uri}/api/services/${itemID}" \
        | jq -r '(.id|tostring) + " " + .name'
done
