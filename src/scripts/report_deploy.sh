#!/bin/bash

# this substitution allows us to accept a string value, or an environment variable in parameters.sha
SHA1=$(circleci env subst "${FAROS_SHA}")
JQ_PATH=/usr/local/bin/jq

CheckEnvVars() {
    if [ -z "${HASURA_ADMIN_SECRET_DEFAULT:-}" ]; then
        echo "In order to use the Faros Event Orb, the secret must be present via the HASURA_ADMIN_SECRET_DEFAULT env var."
        exit 1
    fi
    if [ -z "${HASURA_URL_DEFAULT:-}" ]; then
       echo "In order to use the Faros Event Orb, the URL must be present via the HASURA_URL_DEFAULT env var."
       exit 1
    fi
}

InstallJq() {
    echo "Checking For JQ + CURL"
    if command -v curl >/dev/null 2>&1 && ! command -v jq >/dev/null 2>&1; then
        uname -a | grep Darwin > /dev/null 2>&1 && JQ_VERSION=jq-osx-amd64 || JQ_VERSION=jq-linux32
        curl -Ls -o "$JQ_PATH" https://github.com/stedolan/jq/releases/download/jq-1.6/"${JQ_VERSION}"
        chmod +x "$JQ_PATH"
        command -v jq >/dev/null 2>&1
        return $?
    else
        command -v curl >/dev/null 2>&1 || { echo >&2 "ORB ERROR: CURL is required. Please install."; exit 1; }
        command -v jq >/dev/null 2>&1 || { echo >&2 "ORB ERROR: JQ is required. Please install"; exit 1; }
        return $?
    fi
}

SendEvent() {
    bash <(curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.6.9/faros_event.sh) CD \
      --community_edition \
      --commit "github://$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$SHA1" \
      --deploy "$FAROS_SOURCE://$FAROS_APPLICATION/$FAROS_ENVIRONMENT/$CIRCLE_BUILD_NUM" \
      --deploy_status "$FAROS_STATUS" \
      --deploy_start_time "$FAROS_START_TIME" \
      --deploy_end_time "$FAROS_END_TIME"
}


# Will not run if sourced from another script.
# This is done so this script may be tested.
ORB_TEST_ENV="bats-core"
if [ "${0#*"$ORB_TEST_ENV"}" = "$0" ]; then
    CheckEnvVars
    InstallJq
    SendEvent
fi
