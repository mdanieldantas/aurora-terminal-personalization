#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_NAME='aurora-terminal-personalization'
DRY_RUN=0
ASSUME_YES=0
TARGET_SHELL=''

usage() {
    cat <<'HELP'
Uso: bash switch-to-zsh.sh [opções]

  --dry-run    mostra o que seria feito, sem alterar arquivos
  --yes        aceita a confirmação sem perguntar
  --help       mostra esta ajuda

Este script não usa chsh e não edita /etc/passwd.
Ele cria um arquivo de configuração do Bash para iniciar Zsh em
sessões interativas, preservando o Bash para uso manual.
HELP
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes) ASSUME_YES=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf '[ERRO] Opção desconhecida: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

ask_yes_no() {
    local question="$1" answer=''
    if (( ASSUME_YES )); then
        return 0
    fi
    read -r -p "$question [s/N] " answer || true
    [[ "$answer" =~ ^[SsYy]$ ]]
}

[[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum, sem sudo.'

has_cmd zsh || die 'Zsh não foi encontrado no PATH.'
TARGET_SHELL="$(command -v zsh)"
[[ -x "$TARGET_SHELL" ]] || die "Zsh não é executável: $TARGET_SHELL"

[[ -n "${HOME:-}" && "$HOME" != '/' ]] || die 'HOME inválido.'

if [[ -f "$HOME/.zshenv" && -f "$HOME/.config/zsh/.zshrc" ]]; then
    info 'Configuração do Zsh encontrada.'
else
    warn 'A configuração do Zsh não foi localizada completamente.'
    warn 'Execute primeiro personalize-aurora-terminal.sh.'
fi

BASH_STARTUP=''
for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    if [[ -f "$candidate" ]]; then
        BASH_STARTUP="$candidate"
        break
    fi
done
if [[ -z "$BASH_STARTUP" ]]; then
    BASH_STARTUP="$HOME/.bash_profile"
fi

MARKER_BEGIN='# >>> aurora-terminal-personalization: zsh >>>'
MARKER_END='# <<< aurora-terminal-personalization: zsh <<<'

if [[ -f "$BASH_STARTUP" ]] && grep -Fq "$MARKER_BEGIN" "$BASH_STARTUP"; then
    info "A integração já existe em $BASH_STARTUP"
    exit 0
fi

printf '\n'
info "Arquivo de inicialização selecionado: $BASH_STARTUP"
info "Zsh será iniciado automaticamente apenas em sessões Bash interativas."
warn 'Esta alteração é reversível e não modifica /etc/passwd.'

if ! ask_yes_no 'Deseja configurar o Zsh como shell automático das sessões interativas?' && (( ! DRY_RUN )); then
    info 'Operação cancelada.'
    exit 0
fi

stamp="$(date +%Y%m%d-%H%M%S)"
backup="$BASH_STARTUP.backup-$stamp"
block="
$MARKER_BEGIN
if [[ $- == *i* ]] && [[ "$0" != */zsh && "$SHELL" != "$TARGET_SHELL" ]]; then
    exec "$TARGET_SHELL" -l
fi
$MARKER_END
"

if (( DRY_RUN )); then
    info '[SIMULAÇÃO] Criaria backup e adicionaria o bloco:'
    printf '%s\n' "$block"
    info "[SIMULAÇÃO] Backup: $backup"
    exit 0
fi

cp -a -- "$BASH_STARTUP" "$backup" 2>/dev/null || :
touch "$BASH_STARTUP"
printf '%s\n' "$block" >> "$BASH_STARTUP"

info "Configuração adicionada a: $BASH_STARTUP"
[[ -e "$backup" ]] && info "Backup criado em: $backup"
info 'Abra uma nova janela de terminal para testar.'
info "Para testar nesta sessão sem abrir nova janela: exec $TARGET_SHELL -l"
info "Para desfazer: bash restore-zsh-shell.sh"
