#!/bin/bash
# Usage: config_jira_notifier.sh
 
# Usage: check_env
function check_env()
{
    which curl || return 1
    rc=0
    [[ -z ${DCS_URL} ]] && {
        echo "DCS_URL is empty"
        rc=1
    }
    [[ -z ${DCS_USER} ]] && {
        echo "DCS_USER is empty"
        rc=1
    }
    [[ -z ${DCS_PASSWD} ]] && {
        echo "DCS_PASSWD is empty"
        rc=1
    }
    [[ -z ${DCS_USERNAMESPACE} ]] && {
        echo "DCS_USERNAMESPACE is empty"
        rc=1
    }
    [[ -z ${JIRA_NOTIFIER_URL} ]] && {
        echo "JIRA_NOTIFIER_URL is empty"
        rc=1
    }
    return $rc
}
 
# Usage: get_dcs_authorization ${DCS_URL} ${DCS_USER} ${DCS_PASSWD}
function get_dcs_authorization()
{
    dcs_url=$1
    dcs_user=$2
    dcs_passwd=$3
    echo -n "Get DCS access authorization ... " 1>&2
    output=$(
        curl -s ${dcs_url}/api/crew/v2/access-token \
        -H 'Accept:application/json' \
        -H 'Content-Type:application/json' \
        -d "{\"username_or_email\":\"${dcs_user}\",\"password\":\"${dcs_passwd}\"}"
    )
    (( $? == 0 )) || {
        echo -e "\033[31;40;1m [ FAIL ] \033[0m"
        echo "Failed to get DCS authorization"
        echo "$output"
        return 1
    }
    token=$(echo "$output"| grep access_token | awk -F'"' '{print $4}')
    echo -e "\033[32;40;1m [ PASS ] \033[0m" 1>&2
    echo "$token"
    return 0
}
 
# Usage: create_webhook ${DCS_URL} ${DCS_AUTHORIZATION} ${DCS_USERNAMESPACE} ${JIRA_NOTIFIER_URL}
function create_webhook()
{
    dcs_url=$1
    dcs_auth=$2
    dcs_namespace=$3
    jira_notifier_url=$4
    echo -n "Create JIRA notifier webhook ... " 1>&2
    output=$(
        curl -s ${dcs_url}/api/journal/v1/notify/webhook \
        -H 'Accept:application/json' \
        -H 'Content-Type:application/json' \
        -H "Authorization:${dcs_auth}" \
        -H "UserNameSpace:${dcs_namespace}" \
        -d "{\"url\":\"${JIRA_NOTIFIER_URL}/v1/webhook\"}"
    )
    echo "$output" | grep "\"webhook_url\"" | grep -q "\"${JIRA_NOTIFIER_URL}/v1/webhook\""
    rc=$?
    (( $rc == 0 )) || {
        echo -e "\033[31;40;1m [ FAIL ] \033[0m" 1>&2
        echo "Failed to create webhook"
        echo "$output"     
        return 1
    }
    echo -e "\033[32;40;1m [ PASS ] \033[0m" 1>&2
    echo "$output"
    return 0
}
 
# Main
check_env || exit 1
DCS_AUTHORIZATION=$(get_dcs_authorization ${DCS_URL} ${DCS_USER} ${DCS_PASSWD}) || exit 1
create_webhook ${DCS_URL} ${DCS_AUTHORIZATION} ${DCS_USERNAMESPACE} ${JIRA_NOTIFIER_URL} || exit 1
