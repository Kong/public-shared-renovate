#!/usr/bin/env bash
# validate-no-json5.sh
# shellcheck shell=bash
#
# Validate that a pull request does not introduce any *.json5 files
#
# Usage
#   ./validate-no-json5.sh [<base-ref-or-sha>]

set -euo pipefail
IFS=$'\n\t'

# shellcheck source=_common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
. "${SCRIPT_DIR}/_common.sh"

###############################################################################
# validation
###############################################################################
validate_no_json5() {
  local -a offenders=()
  local f
  while IFS= read -r -d '' f; do
    if common::has_json5_suffix "$f"; then
      offenders+=("$f")
    fi
  done

  if ((${#offenders[@]} > 0)); then
    common::error "The PR includes files with the .json5 extension, which are not allowed"

    local p
    for p in "${offenders[@]}"; do
      common::error "  - $p"
    done
    exit 1
  fi

  common::notice "no .json5 files detected in the PR"
}

main() {
  common::require_tools git
  common::ensure_repo

  local base; base="$(common::resolve_base_ref "${1:-}")"

  common::debug "using base ref: $base"

  local -a changed
  mapfile -d '' -t changed < <(common::list_changed_files "$base")

  if ((${#changed[@]} == 0)); then
    common::log "no changed files to validate"
    exit 0
  fi

  printf '%s\0' "${changed[@]}" | validate_no_json5
}

# allow sourcing in potential tests
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
