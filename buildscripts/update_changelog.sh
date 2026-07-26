#!/bin/bash -e
#
# Cuts the `## Unreleased` section of CHANGELOG.md into a `## v<version>`
# section and starts a fresh, empty `## Unreleased` section.
#
# Usage: buildscripts/update_changelog.sh 0.1.0

version=${1:-${VERSION:-}}
version=${version#v}

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: $0 <major.minor.patch>" >&2
  exit 1
fi

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
changelog="$root/CHANGELOG.md"

if grep -q "^## v${version}$" "$changelog"; then
  echo "CHANGELOG.md already contains a section for v${version}" >&2
  exit 1
fi

unreleased=$(awk '/^## Unreleased$/ { found = 1; next } /^## / { found = 0 } found' "$changelog")
if [[ -z "${unreleased//[[:space:]]/}" ]]; then
  echo "the Unreleased section of CHANGELOG.md is empty, nothing to release" >&2
  exit 1
fi

awk -v version="$version" '
  /^## Unreleased$/ && !done {
    print "## Unreleased"
    print ""
    print "## v" version
    done = 1
    next
  }
  { print }
' "$changelog" > "$changelog.tmp"

mv "$changelog.tmp" "$changelog"
echo "CHANGELOG.md updated for v${version}"
