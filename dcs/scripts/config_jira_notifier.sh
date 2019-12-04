#!/bin/bash
# Usage: config_jira_notifier.sh

CURL='curl -s '
DCS_AUTH=""

function exit_no_input
{
    echo -e "\n\033[31;40;1m [ ERROR ] \033[0m No input. Please try again.\n"
    exit 1
}

function exit_no_http
{
    echo -e "\n\033[31;40;1m [ ERROR ] \033[0m Please check URL. And try again.\n"
    exit 1
}

# Usage: exit_fail <msg>
function exit_fail
{
    echo -e "\n\033[31;40;1m [ FAIL ] \033[0m $@\n"
    exit 1
}

function log_succeed
{
    echo -e "\n\033[32;40;1m [ SUCCEED ] \033[0m $@"
    return 0
}

function check_env()
{
    which curl > /dev/null || exit 1
    which read > /dev/null || exit 1
}
 
# Usage: login_dcs_to_get_authorization ${DCS_URL} ${DCS_USER} ${DCS_PASSWORD}
function login_dcs_to_get_authorization()
{
    dcs_url=$1
    dcs_user=$2
    dcs_passwd=$3
    echo "${dcs_url}" | grep 'https://' && CURL='curl -s -v -k'
    output=$(
        ${CURL} ${dcs_url}/api/crew/v2/access-token \
            -H 'Accept:application/json' \
            -H 'Content-Type:application/json' \
            -d "{\"username_or_email\":\"${dcs_user}\",\"password\":\"${dcs_passwd}\"}"
    )
    (( $? == 0 )) || exit_fail "$output"
    echo "$output" | grep -q '"access_token"' && {
        DCS_AUTH=$(echo "$output"| grep '"access_token"' | awk -F '"' '{print $4}')
        log_succeed "Login Succeed"
        return 0
    }
    echo "$output" | grep -q '"err_msg"' && {
        err_msg=$(echo "$output"| grep '"err_msg"' | awk -F '"' '{print $4}')
        exit_fail "$err_msg"
    }
    exit_fail "$output"
}
 
# Usage: create_webhook ${DCS_URL} ${DCS_AUTH} ${DCS_ORG} ${JIRA_NOTIFIER_URL}
function create_webhook()
{
    dcs_url=$1
    dcs_auth=$2
    dcs_org=$3
    jira_notifier_url=$4
    output=$(
        ${CURL} ${dcs_url}/api/journal/v1/notify/webhook \
            -H 'Accept:application/json' \
            -H 'Content-Type:application/json' \
            -H "Authorization:${dcs_auth}" \
            -H "UserNameSpace:${dcs_org}" \
            -d "{\"url\":\"${jira_notifier_url}/v1/webhook\"}"
    )
    (( $? == 0 )) || exit_fail "$output"
    echo "$output" | grep '"webhook_url"' | grep -q "\"${jira_notifier_url}/v1/webhook\"" && {
        webhook=$(echo "$output" | grep '"webhook_url"' | awk -F '"' '{print $4}')
        log_succeed "Create WebHook $webhook Succeed"
        return 0
    }
    echo "$output" | grep -q '"err_msg"' && {
        err_msg=$(echo "$output"| grep '"err_msg"' | awk -F '"' '{print $4}')
        exit_fail "$err_msg"
    }
    exit_fail "$output"
    return 0
}
 

# Main
check_env

echo -e "Please login DCS:"
read -p " ├── DCS Access URL: " DCS_URL
[[ -z "$DCS_URL" ]] && exit_no_input
echo "${DCS_URL}" | grep -q 'http' || exit_no_http
read -p " ├── DCS Username: " DCS_USER
[[ -z "$DCS_USER" ]] && exit_no_input
read -p " └── DCS Password: " -s DCS_PASSWORD
[[ -z "$DCS_PASSWORD" ]] && exit_no_input
login_dcs_to_get_authorization "$DCS_URL" "$DCS_USER" "$DCS_PASSWORD"

echo -e "\nConfig WebHook for JIRA notifier:"
read -p " ├── JIRA Notifier URL: " JIRA_NOTIFIER_URL
[[ -z "$JIRA_NOTIFIER_URL" ]] && exit_no_input
echo "${JIRA_NOTIFIER_URL}" | grep -q 'http' || exit_no_http
read -p " └── DCS Org Name: " DCS_ORG
[[ -z "$DCS_ORG" ]] && exit_no_input
create_webhook "${DCS_URL}" "${DCS_AUTH}" "${DCS_ORG}" "${JIRA_NOTIFIER_URL}"
