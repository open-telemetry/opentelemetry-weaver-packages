#!/bin/bash -e
#
# Prints the CHANGELOG.md section for a given version. Used as release notes.
#
# Usage: buildscripts/extract_changelog.sh 0.1.0

version=${1:-${VERSION:-}}
version=${version#v}

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: $0 <major.minor.patch>" >&2
  exit 1
fi

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)

section=$(awk -v heading="## v${version}" '
  $0 == heading { found = 1; next }
  /^## / { found = 0 }
  found
' "$root/CHANGELOG.md")

if [[ -z "${section//[[:space:]]/}" ]]; then
  echo "no CHANGELOG.md section found for v${version}" >&2
  exit 1
fi

# Trim leading and trailing blank lines.
echo "$section" | sed -e '/./,$!d' | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }'
