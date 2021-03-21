#!/usr/bin/env bash

set -eo pipefail

echo "Checking difference between README.md and make help output...\n"
README_HELP="$(awk '/> make/{f=1;next} /~~~/{f=0} f' README.md)"
MAKE_HELP="$(make | sed 's,\x1B\[[0-9;]*[a-zA-Z],,g')"
diff <(echo "$README_HELP") <(echo "$MAKE_HELP") || (printf "\033[31mFAILED!\033[0m\n" && exit 1)
printf "\033[32mOK\033[0m\n"

echo "Checking version...\n"
[ "$(git grep $(cat VERSION) | wc -l)" -eq 6 ] || (printf "\033[31mFAILED!\033[0m\n" && exit 1)
printf "\033[32mOK\033[0m\n"
