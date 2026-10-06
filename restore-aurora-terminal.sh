#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_NAME='aurora-terminal-personalization'
DRY_RUN=0
OFFLINE=0
ASSUME_YES=0
CHANGE_SHELL=0
START_TIME=$SECONDS
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
LOG_DIR="$SCRIPT_DIR/logs"
BACKUP_ROOT="$SCRIPT_DIR/backups"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/personalize-$TIMESTAMP.log"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
TMP_ROOT=''

usage(){ printf '%s\n' 'Uso: bash personalize-aurora-terminal.sh [--dry-run] [--offline] [--yes] [--change-shell]'; }
for arg in "$@"; do case "$arg" in --dry-run) DRY_RUN=1;; --offline) OFFLINE=1;; --yes) ASSUME_YES=1;; --change-shell) CHANGE_SHELL=1;; --help|-h) usage; exit 0;; *) printf 'Opção desconhecida: %s\n' "$arg" >&2; exit 2;; esac; done
[[ $(id -u) -ne 0 ]] || { printf 'Execute como usuário comum, sem sudo.\n' >&2; exit 1; }
info(){ printf '[INFO] %s\n' "$*"; }; warn(){ printf '[AVISO] %s\n' "$*" >&2; }; die(){ printf '[ERRO] %s\n' "$*" >&2; exit 1; }; has_cmd(){ command -v "$1" >/dev/null 2>&1; }
cleanup(){ [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]] && rm -rf -- "$TMP_ROOT"; }; trap cleanup EXIT
trap 'printf "[ERRO] linha %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
ask_yes_no(){ local q="$1" default="${2:-N}" answer=''; (( ASSUME_YES )) && { [[ "$default" == S ]]; return; }; if [[ "$default" == S ]]; then read -r -p "$q [S/n] " answer || true; answer="${answer:-S}"; else read -r -p "$q [s/N] " answer || true; answer="${answer:-N}"; fi; [[ "$answer" =~ ^[SsYy]$ ]]; }
if (( ! DRY_RUN )); then mkdir -p "$LOG_DIR"; exec > >(tee -a "$LOG_FILE") 2>&1; fi
show_environment(){ if [[ -r /etc/os-release ]]; then . /etc/os-release; info "Distribuição: ${PRETTY_NAME:-desconhecida}"; info "ID: ${ID:-desconhecido}"; fi; info "Kernel: $(uname -srmo)"; info "Usuário: $(id -un)"; info "Shell: ${SHELL:-não definido}"; info "Projeto: $PROJECT_NAME"; info "Script: $SCRIPT_DIR"; (( DRY_RUN )) && info 'Modo: dry-run' || { (( OFFLINE )) && info 'Modo: offline' || info 'Modo: normal'; }; }
check_aurora(){ local ok=0; if [[ -r /etc/os-release ]]; then . /etc/os-release; [[ "${ID:-}" == aurora || "${VARIANT_ID:-}" == aurora* || "${PRETTY_NAME:-}" == *Aurora* ]] && ok=1; fi; (( ok )) || { warn 'Sistema não identificado claramente como Aurora.'; ask_yes_no 'Continuar mesmo assim?' N || die 'Cancelado.'; }; }
check_aurora_tools(){ if has_cmd ujust; then ujust --list 2>/dev/null | grep -E 'devmode|dx-group|aurora-cli|update' || true; else warn 'ujust ausente.'; fi; has_cmd brew && info "Homebrew: $(brew --version | head -n1)" || warn 'Homebrew ausente.'; }
show_commands(){ local c; for c in brew zsh git starship zoxide fzf rg fd bat eza yazi; do if has_cmd "$c"; then info "$c: $(command -v "$c")"; else info "$c: ausente"; fi; done; }
required=(zsh starship zoxide fzf ripgrep fd bat eza git yazi); missing=(); failed=()
formula_command(){ [[ "$1" == ripgrep ]] && printf rg || printf '%s' "$1"; }
find_missing(){ local f c; for f in "${required[@]}"; do c="$(formula_command "$f")"; has_cmd "$c" || missing+=("$f"); done; }
main(){ show_environment; check_aurora; check_aurora_tools; show_commands; find_missing; if (( DRY_RUN )); then info "Ausentes: ${missing[*]:-nenhuma}"; info 'Dry-run concluído sem downloads, backups ou alterações.'; return 0; fi; die 'A aplicação ainda não foi habilitada nesta versão de teste.'; }
main
