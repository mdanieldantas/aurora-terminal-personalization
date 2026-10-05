#!/usr/bin/env bash
set -Eeuo pipefail
DRY_RUN=0
usage(){ printf '%s
' 'Uso: bash personalize-aurora-terminal.sh --dry-run'; }
for arg in "$@"; do case "$arg" in --dry-run) DRY_RUN=1;; --help|-h) usage; exit 0;; *) printf 'Opção desconhecida: %s
' "$arg" >&2; exit 1;; esac; done
[[ $DRY_RUN -eq 1 ]] || { printf 'Nesta fase, use --dry-run; nenhuma personalização foi implementada.
'; exit 0; }
[[ $(id -u) -ne 0 ]] || { printf 'Execute como usuário comum, sem sudo.
' >&2; exit 1; }
printf 'Diagnóstico Aurora: nenhuma alteração será feita.
'
if [[ -r /etc/os-release ]]; then . /etc/os-release; printf 'Distribuição: %s
' "${PRETTY_NAME:-desconhecida}"; fi
printf 'Kernel: %s
' "$(uname -srmo)"
printf 'Usuário: %s
' "$(id -un)"
printf 'Shell: %s
' "${SHELL:-não definido}"
for c in brew zsh git starship zoxide fzf rg fd bat eza yazi ujust; do if command -v "$c" >/dev/null 2>&1; then printf '%-10s %s
' "$c" "$(command -v "$c")"; else printf '%-10s ausente
' "$c"; fi; done
if command -v ujust >/dev/null 2>&1; then ujust --list 2>/dev/null | grep -E 'devmode|dx-group|aurora-cli|update' || true; fi
printf 'Fim do diagnóstico.
'
