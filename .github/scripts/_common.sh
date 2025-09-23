# _common.sh
# shellcheck shell=bash
#
# Common helpers for validation and sync scripts
#
# Usage
#   # Source from sibling scripts
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
#   . "${SCRIPT_DIR}/_common.sh"

###############################################################################
# logging
###############################################################################
# If the message already contains a GitHub annotation prefix (::level::),
# print as-is. Otherwise, prefix with the requested level.
common::__emit() {
  local level=$1
  shift || true
  local msg="$*"

  if [[ "$msg" == *"::"* ]]; then
    printf '%s\n' "$msg"
  elif [[ -n "$level" ]]; then
    printf '::%s::%s\n' "$level" "$msg"
  else
    printf '%s\n' "$msg"
  fi
}

common::log()    { common::__emit ""        "$@"; }
common::notice() { common::__emit "notice"  "$@"; }
common::debug()  { common::__emit "debug"   "$@"; }
common::warn()   { common::__emit "warning" "$@"; }
common::error()  { common::__emit "error"   "$@"; }
common::die()    { common::error "$@"; exit 1; }

###############################################################################
# guards
###############################################################################
common::require_tools() {
  # Usage: common::require_tools git jq ...
  local missing=() t
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  (( ${#missing[@]} == 0 )) || common::die "missing required tools: ${missing[*]}"
}

common::ensure_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || common::die "not a git repository"
}

###############################################################################
# path/id helpers
###############################################################################
common::relpath() {
  # Strip leading ./ for stable ids
  local p=$1
  case "$p" in
  ./*) printf '%s\n' "${p#./}" ;;
  *)   printf '%s\n' "$p" ;;
  esac
}

common::strip_json_ext() {
  # Remove .json suffix if present
  local p=$1
  printf '%s\n' "${p%.json}"
}

common::preset_id_from_rel_noext() {
  # Example: prefix=Kong/public-shared-renovate// rel=security/incidents/foo
  local prefix=$1 rel_no_ext=$2
  printf '%s%s\n' "$prefix" "$rel_no_ext"
}

###############################################################################
# git helpers
###############################################################################
# Use GitHub Actions envs when available to pick a sensible base for diffs
# Resolution order
# 1) first positional arg
# 2) pull_request base SHA from GITHUB_EVENT_PATH
# 3) GITHUB_BASE_REF branch on origin
# 4) origin/main
common::resolve_base_ref() {
  local arg_base=${1:-}
  local base=""

  if [[ -n "$arg_base" ]]; then
    base=$arg_base
  elif [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" && -n "${GITHUB_EVENT_PATH:-}" && -f "${GITHUB_EVENT_PATH}" ]]; then
    base="$(jq -r '.pull_request.base.sha // empty' < "$GITHUB_EVENT_PATH")"
  elif [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    base="origin/${GITHUB_BASE_REF}"
    git fetch --no-tags --depth=1 origin "${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
  else
    base="origin/main"
    git fetch --no-tags --depth=1 origin main >/dev/null 2>&1 || true
  fi

  # Ensure the base commit is available locally; fetch if necessary
  if ! git cat-file -e "${base}^{commit}" >/dev/null 2>&1; then
    if [[ "$base" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
      git fetch --no-tags --depth=1 origin "$base" >/dev/null 2>&1 || true
    elif [[ "$base" == origin/* ]]; then
      git fetch --no-tags --depth=1 origin "${base#origin/}" >/dev/null 2>&1 || true
    else
      git fetch --no-tags --depth=1 origin "$base" >/dev/null 2>&1 || true
    fi
  fi

  # Resolve to a merge-base with HEAD when possible
  local head merge_base
  head=$(git rev-parse HEAD)

  # If still not available, fallback to the base branch or main
  if ! git cat-file -e "${base}^{commit}" >/dev/null 2>&1; then
    if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
      base="origin/${GITHUB_BASE_REF}"
      git fetch --no-tags --depth=1 origin "${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
    else
      base="origin/main"
      git fetch --no-tags --depth=1 origin main >/dev/null 2>&1 || true
    fi
  fi

  merge_base=$(git merge-base "$base" "$head" 2>/dev/null || true)

  if [[ -n "$merge_base" ]]; then
    printf '%s\n' "$merge_base"
  else
    if git rev-parse "$base^{commit}" >/dev/null 2>&1; then
      git rev-parse "$base^{commit}"
    else
      # Last resort to avoid invalid symmetric diff errors
      git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD
    fi
  fi
}

common::list_changed_files() {
  # Args: <base-commit-ish>
  # Prints NUL-delimited list of changed paths for A, C, M, R statuses
  local base=$1
  git diff --name-only --diff-filter=ACMR -z "${base}..HEAD"
}

common::has_json5_suffix() {
  # case-insensitive check for .json5
  local path=$1
  local lower=${path,,}
  [[ "$lower" == *.json5 ]]
}
