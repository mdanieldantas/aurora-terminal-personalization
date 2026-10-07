#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

MARKER_BEGIN='# >>> aurora-terminal-personalization: zsh >>>'
MARKER_END='# <<< aurora-terminal-personalization: zsh <<<'

info() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum, sem sudo.'

for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    [[ -f "$candidate" ]] || continue
    if grep -Fq "$MARKER_BEGIN" "$candidate"; then
        tmp="$(mktemp)"
        awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
            $0 == begin { inside=1; next }
            $0 == end { inside=0; next }
            !inside { print }
        ' "$candidate" > "$tmp"
        cp -a -- "$candidate" "$candidate.before-restore-$(date +%Y%m%d-%H%M%S)"
        mv -- "$tmp" "$candidate"
        info "Bloco removido de $candidate"
        exit 0
    fi
done

info 'Nenhum bloco da configuração Aurora-Zsh foi encontrado.'
