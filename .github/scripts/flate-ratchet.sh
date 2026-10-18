#!/usr/bin/env bash
# Render the whole Flux tree offline with flate and compare failures against
# .github/flate-known-failures.txt. Fails on any new failure, and on any
# known failure that now passes (so the list only ever shrinks).
#
# Usage: .github/scripts/flate-ratchet.sh [flate-binary]
set -euo pipefail

flate="${1:-flate}"
root="$(git rev-parse --show-toplevel)"
known="${root}/.github/flate-known-failures.txt"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

cd "${root}"
"${flate}" test all \
  --path ./k8s/clusters/kclt-01/flux \
  --allow-missing-secrets \
  --no-progress >"${work}/flate.log" 2>&1 || true
cat "${work}/flate.log"

if ! grep -Eq '[0-9]+ passed' "${work}/flate.log"; then
  echo "::error::flate did not produce a test summary"
  exit 1
fi

# Failure lines look like: "  ✗  HelmRelease     default/jellyfin  <reason>"
awk '$1 == "✗" && $2 ~ /^[A-Z]/ { print $2, $3 }' "${work}/flate.log" | sort -u >"${work}/actual"
grep -Ev '^\s*(#|$)' "${known}" | sort -u >"${work}/known"

comm -13 "${work}/known" "${work}/actual" >"${work}/new"
comm -23 "${work}/known" "${work}/actual" >"${work}/fixed"

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
{
  echo "## flate"
  echo
  echo "$(grep -E '[0-9]+ passed' "${work}/flate.log" | tail -1 | sed 's/^ *//')"
  echo
  echo "Known failures still failing: $(comm -12 "${work}/known" "${work}/actual" | wc -l)"
} >>"${summary}"

rc=0
if [[ -s "${work}/new" ]]; then
  echo "::error::New flate failures (fix them, do not add them to the known list):"
  sed 's/^/  /' "${work}/new"
  { echo; echo "### New failures"; sed 's/^/- /' "${work}/new"; } >>"${summary}"
  rc=1
fi
if [[ -s "${work}/fixed" ]]; then
  echo "::error::These now pass; remove them from .github/flate-known-failures.txt:"
  sed 's/^/  /' "${work}/fixed"
  { echo; echo "### Fixed (remove from known list)"; sed 's/^/- /' "${work}/fixed"; } >>"${summary}"
  rc=1
fi
exit "${rc}"
