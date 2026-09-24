#!/usr/bin/env bash

set -euo pipefail

usage() {
	printf 'Usage: %s <log-directory>\n' "$0" >&2
}

if [[ $# -ne 1 ]]; then
	usage
	exit 1
fi

log_directory=$1

if [[ ! -d "$log_directory" ]]; then
	printf 'Error: log directory does not exist: %s\n' "$log_directory" >&2
	exit 1
fi

archive_directory="$PWD/archives"
mkdir -p "$archive_directory"

timestamp=$(date '+%Y%m%d_%H%M%S')
archive_file="$archive_directory/logs_archive_${timestamp}.tar.gz"
log_file="$archive_directory/archive.log"

log_directory=$(cd "$log_directory" && pwd -P)
tar -czf "$archive_file" -C "$(dirname "$log_directory")" "$(basename "$log_directory")"

printf '%s - Archived %s to %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$log_directory" "$archive_file" >> "$log_file"
printf 'Archive created: %s\n' "$archive_file"
