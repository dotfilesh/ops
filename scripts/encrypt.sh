#!/usr/bin/env bash
# scripts/encrypt.sh
#
# SOPS encrypt/decrypt helpers for the kubernetes/ tree.
# Uses age-only keys as configured in .sops.yaml.
#
# Usage:
#   # Encrypt a file in-place:
#   ./scripts/encrypt.sh encrypt kubernetes/apps/auth/authentik/secret.sops.yaml
#
#   # Decrypt a file to stdout:
#   ./scripts/encrypt.sh decrypt kubernetes/apps/auth/authentik/secret.sops.yaml
#
#   # Edit a file (decrypt → edit → re-encrypt):
#   ./scripts/encrypt.sh edit kubernetes/apps/auth/authentik/secret.sops.yaml
#
#   # Encrypt all .sops.yaml files found under a directory:
#   ./scripts/encrypt.sh encrypt-all kubernetes/apps/
#
# Requirements:
#   - SOPS_AGE_KEY_FILE must be set and point to the age private key
#   - sops must be installed
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

command -v sops &>/dev/null || die "sops is not installed"
[[ -n "${SOPS_AGE_KEY_FILE:-}" ]] || die "SOPS_AGE_KEY_FILE is not set"
[[ -f "${SOPS_AGE_KEY_FILE}" ]]   || die "Age key file not found: ${SOPS_AGE_KEY_FILE}"

ACTION="${1:-}"
FILE="${2:-}"

case "${ACTION}" in
  encrypt)
    [[ -n "${FILE}" ]] || die "Usage: $0 encrypt <file>"
    [[ -f "${FILE}" ]] || die "File not found: ${FILE}"
    info "Encrypting: ${FILE}"
    sops --encrypt --in-place "${FILE}"
    info "Encrypted: ${FILE}"
    ;;

  decrypt)
    [[ -n "${FILE}" ]] || die "Usage: $0 decrypt <file>"
    [[ -f "${FILE}" ]] || die "File not found: ${FILE}"
    info "Decrypting to stdout: ${FILE}"
    sops --decrypt "${FILE}"
    ;;

  edit)
    [[ -n "${FILE}" ]] || die "Usage: $0 edit <file>"
    [[ -f "${FILE}" ]] || die "File not found: ${FILE}"
    info "Opening for editing: ${FILE}"
    sops "${FILE}"
    info "Saved (re-encrypted): ${FILE}"
    ;;

  encrypt-all)
    [[ -n "${FILE}" ]] || die "Usage: $0 encrypt-all <directory>"
    [[ -d "${FILE}" ]] || die "Directory not found: ${FILE}"
    info "Finding and encrypting all *.sops.yaml files under: ${FILE}"
    count=0
    while IFS= read -r -d '' f; do
      # Skip files that are already encrypted (sops metadata header present)
      if grep -q 'sops:' "${f}" 2>/dev/null; then
        warn "  Already encrypted (skipping): ${f}"
      else
        info "  Encrypting: ${f}"
        sops --encrypt --in-place "${f}" && ((count++)) || warn "  Failed: ${f}"
      fi
    done < <(find "${FILE}" -name '*.sops.yaml' -print0)
    info "Encrypted ${count} file(s)."
    ;;

  *)
    echo "Usage: $0 {encrypt|decrypt|edit|encrypt-all} <file|directory>"
    exit 1
    ;;
esac
