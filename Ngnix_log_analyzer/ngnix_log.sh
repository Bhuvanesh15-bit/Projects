#!/usr/bin/env bash

set -euo pipefail

log_url='https://gist.githubusercontent.com/nilbuild/e66c3b9ea89a1a030d3b739eeeef22d0/raw/77fb3ac837a73c4f0206e78a236d885590b7ae35/nginx-access.log'
temporary_log=''

if [[ $# -gt 1 ]]; then
	printf 'Usage: %s [nginx-access-log]\n' "$0" >&2
	exit 1
fi

if [[ $# -eq 1 ]]; then
	log_file=$1
else
	temporary_log=$(mktemp)
	trap 'rm -f "$temporary_log"' EXIT
	curl --fail --location --silent --show-error "$log_url" --output "$temporary_log"
	log_file=$temporary_log
fi

if [[ ! -f "$log_file" || ! -r "$log_file" ]]; then
	printf 'Error: cannot read log file: %s\n' "$log_file" >&2
	exit 1
fi

printf 'Top 5 IP addresses with the most requests:\n'
awk '{ ip[$1]++ } END { for (value in ip) print value, ip[value] }' "$log_file" \
	| sort -k2,2nr -k1,1 | awk 'NR <= 5' \
	| awk '{ printf "%s - %s requests\n", $1, $2 }'

printf '\n'
printf 'Top 5 most requested paths:\n'
awk '
{
	request = $0
	sub(/^[^\"]*\"/, "", request)
	sub(/\".*$/, "", request)
	split(request, request_fields, " ")
	if (request_fields[2] ~ /^\//) {
		path[request_fields[2]]++
	}
}
END {
	for (value in path) print value, path[value]
}
' "$log_file" \
	| sort -k2,2nr -k1,1 | awk 'NR <= 5' \
	| awk '{ printf "%s - %s requests\n", $1, $2 }'

printf '\n'
printf 'Top 5 response status codes:\n'
awk '
{
	if (match($0, /\"[[:space:]]*[0-9][0-9][0-9][[:space:]]/)) {
		response = substr($0, RSTART, RLENGTH)
		gsub(/[^0-9]/, "", response)
		status[response]++
	}
}
END {
	for (value in status) print value, status[value]
}
' "$log_file" \
	| sort -k2,2nr -k1,1 | awk 'NR <= 5' \
	| awk '{ printf "%s - %s requests\n", $1, $2 }'

printf '\n'
printf 'Top 5 user agents:\n'
awk '
{
	user_agent = $0
	sub(/^.*"[^"]*" "/, "", user_agent)
	sub(/"[[:space:]]*$/, "", user_agent)
	agents[user_agent]++
}
END {
	for (value in agents) print value "\t" agents[value]
}
' "$log_file" \
	| sort -k2,2nr -k1,1 | awk 'NR <= 5' \
	| awk -F '\t' '{ printf "%s - %s requests\n", $1, $2 }'
