#!/bin/bash
# deploy.sh - run Ansible playbooks by stage, with optional targets and extra args.
#
# Usage:
#   ./deploy.sh <vm_install|os_config|postgresql|pg_replication|all> [targets] [-- <extra ansible-playbook args>]
#
# Examples:
#   ./deploy.sh os_config db_local
#   ./deploy.sh postgresql db01-local,db02-local
#   ./deploy.sh all db_local -- -e some_var=1 -v
#
set -euo pipefail

PLAYBOOK_DIR="playbooks"
INVENTORY="inventory"

usage() {
  echo "Usage: $0 <vm_install|os_config|postgresql|pg_replication|all> [targets] [-- <extra ansible-playbook args>]"
  exit 1
}

[[ $# -ge 1 ]] || usage

stage="$1"; shift

targets=""
extra_args=()

if [[ $# -gt 0 && "$1" != "--" ]]; then
  targets="$1"
  shift
fi

if [[ $# -gt 0 && "$1" == "--" ]]; then
  shift
  extra_args=("$@")
fi

run_playbook() {
  local pb="$1"
  local args=( -i "$INVENTORY" "$PLAYBOOK_DIR/$pb" --become )
  if [[ -n "$targets" ]]; then
    args+=( --limit "$targets" -e "playbook_target=$targets" )
  fi
  # Append any user-provided extra args
  if [[ ${#extra_args[@]} -gt 0 ]]; then
    args+=( "${extra_args[@]}" )
  fi

  echo ">>> Running ${pb}  (targets: ${targets:-<default>})"
  ansible-playbook "${args[@]}"
}

case "$stage" in
  vm_install)
    run_playbook "vm_install.yml"
    ;;
  os_config)
    run_playbook "os_config.yml"
    ;;
  postgresql)
    run_playbook "postgresql.yml"
    ;;
  pg_replication)
    run_playbook "pg_replication.yml"
    ;;
  all)
    run_playbook "vm_install.yml"
    run_playbook "os_config.yml"
    run_playbook "postgresql.yml"
    run_playbook "pg_replication.yml"
    ;;
  *)
    echo "Invalid: $stage"
    usage
    ;;
esac

