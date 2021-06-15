#!/bin/bash

REPO="${1}"
USER="${2}"
EMAIL="${3}"
TOKEN="${4}"

map="_exts.txt"
header="Authorization: token ${TOKEN}"

git=$( command -v git )
date=$( command -v date )
curl=$( command -v curl )
jq=$( command -v jq )

${git} config --global user.email "${EMAIL}"
${git} config --global user.name "${USER}"

REPO_AUTH="https://${USER}:${TOKEN}@${REPO#https://}"

${git} clone "${REPO_AUTH}" '/root/git/source' && cd '/root/git/source' || exit 1
${git} remote add 'l10n' "${REPO_AUTH}"

mapfile -t exts < "${map}"

_timestamp() {
  timestamp=$( ${date} -u '+%Y-%m-%d %T' )
  echo "${timestamp}"
}

_getAPI() {
  ${curl} -s -X GET -H "${header}" "${1}"
}

_getFile() {
  ${curl} -s -X GET -H "${header}" "${1}" -o "${2}"
}

getL10N() {
  for ext in "${exts[@]}"; do
    url=$( _getAPI "https://api.github.com/repos/${ext}/contents/resources/locale/en.yml" | ${jq} -r '.download_url' )
    name=$( _getAPI "${url}" | sed -n 1p | sed "s/://g" )
    _getFile "${url}" "${name}.yml"
  done
}

getL10N

${git} add .                                      \
  && ${git} commit -a -m "L10N: $( _timestamp )"  \
  && ${git} push 'l10n'

exit 0