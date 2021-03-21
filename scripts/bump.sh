#!/usr/bin/env bash

set -eo pipefail

CURRENT_VERSION=$(cat VERSION)
BUMP_VERSION=${1}

if [ -n "${BUMP_VERSION}" ]; then
    echo "Checking version ${BUMP_VERSION} of Terraform...\n"
    tmp_file=$(mktemp /tmp/tf-make.XXX)
    if curl -s -o "${tmp_file}" -L "https://releases.hashicorp.com/terraform/${BUMP_VERSION}"; then
        printf "\\033[32mOK\\033[0m ✔️\\n"
        echo "Bumping version from ${CURRENT_VERSION} to ${BUMP_VERSION}...\n"
        find . -maxdepth 1 -type f -exec sed -i "s|${CURRENT_VERSION}|${BUMP_VERSION}|" "{}" \;
        printf "\\033[32mDONE!\\033[0m ✔️\\n"
        echo "Bye 👋"
    else
        printf "\\033[31mFAILED!\\033[0m ❌\\n"
        echo "Version ${BUMP_VERSION} does not seem to exist."
        echo "Exiting 👋"
        exit 1
    fi
else
    log_e "Usage: ${0} <terraform_version>"
    exit 1
fi
