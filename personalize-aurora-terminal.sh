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

usage() {
    cat <<'HELP'
Uso: bash personalize-aurora-terminal.sh [opções]

  --dry-run       apenas diagnostica; não altera, instala ou baixa nada
  --offline       não usa Homebrew nem rede
  --yes           aceita confirmações padrão
  --change-shell  pergunta se Zsh deve virar o shell de login
  --help          mostra esta ajuda

Pré-requisitos manuais:
Aurora DX/Developer Mode, Homebrew e, preferencialmente, Aurora CLI já ativados.
Este script não ativa essas etapas.
HELP
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --offline) OFFLINE=1 ;;
        --yes) ASSUME_YES=1 ;;
        --change-shell) CHANGE_SHELL=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Opção desconhecida: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

[[ "$(id -u)" -ne 0 ]] || {
    printf 'Execute como usuário comum, sem sudo.\n' >&2
    exit 1
}

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

cleanup() {
    if [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]]; then
        rm -rf -- "$TMP_ROOT"
    fi
}
trap cleanup EXIT

ask_yes_no() {
    local question="$1" default="${2:-N}" answer=''
    if (( ASSUME_YES )); then
        [[ "$default" == S ]]
        return
    fi
    if [[ "$default" == S ]]; then
        read -r -p "$question [S/n] " answer || true
        answer="${answer:-S}"
    else
        read -r -p "$question [s/N] " answer || true
        answer="${answer:-N}"
    fi
    [[ "$answer" =~ ^[SsYy]$ ]]
}

retry() {
    local attempts="$1" delay="$2"
    shift 2
    local attempt
    for ((attempt = 1; attempt <= attempts; attempt++)); do
        if "$@"; then
            return 0
        fi
        if (( attempt < attempts )); then
            warn "Tentativa $attempt/$attempts falhou; aguardando ${delay}s."
            sleep "$delay"
        fi
    done
    return 1
}

run_with_timeout() {
    if has_cmd timeout; then
        timeout "$@"
    else
        shift
        "$@"
    fi
}

if (( ! DRY_RUN )); then
    mkdir -p "$LOG_DIR"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

show_environment() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        info "Distribuição: ${PRETTY_NAME:-desconhecida}"
        info "ID: ${ID:-desconhecido}"
    fi
    info "Kernel: $(uname -srmo)"
    info "Usuário: $(id -un)"
    info "Shell: ${SHELL:-não definido}"
    info "Projeto: $PROJECT_NAME"
    info "Script: $SCRIPT_DIR"
    if (( DRY_RUN )); then
        info 'Modo: dry-run'
    elif (( OFFLINE )); then
        info 'Modo: offline'
    else
        info 'Modo: normal'
    fi
}

check_aurora() {
    local is_aurora=0
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [[ "${ID:-}" == aurora || "${VARIANT_ID:-}" == aurora* || "${PRETTY_NAME:-}" == *Aurora* ]]; then
            is_aurora=1
        fi
    fi
    if (( ! is_aurora )); then
        warn 'O sistema não foi identificado claramente como Aurora.'
        ask_yes_no 'Continuar mesmo assim?' N || die 'Execução cancelada.'
    fi
}

check_aurora_tools() {
    if has_cmd ujust; then
        ujust --list 2>/dev/null | grep -E 'devmode|dx-group|aurora-cli|update' || true
    else
        warn 'ujust ausente; não foi possível verificar as receitas Aurora.'
    fi
    if has_cmd brew; then
        info "Homebrew: $(brew --version | head -n1)"
    else
        warn 'Homebrew ausente.'
    fi
}

show_commands() {
    local command_name
    for command_name in brew zsh git starship zoxide fzf rg fd bat eza yazi; do
        if has_cmd "$command_name"; then
            info "$command_name: $(command -v "$command_name")"
        else
            info "$command_name: ausente"
        fi
    done
}

required=(zsh starship zoxide fzf ripgrep fd bat eza git)
optional=(yazi)
missing=()
missing_optional=()
failed=()

formula_command() {
    [[ "$1" == ripgrep ]] && printf 'rg' || printf '%s' "$1"
}

find_missing() {
    local formula command_name
    missing=()
    missing_optional=()
    for formula in "${required[@]}"; do
        command_name="$(formula_command "$formula")"
        has_cmd "$command_name" || missing+=("$formula")
    done
    for formula in "${optional[@]}"; do
        command_name="$(formula_command "$formula")"
        has_cmd "$command_name" || missing_optional+=("$formula")
    done
}

install_one_formula() {
    local formula="$1"
    (( OFFLINE )) && { warn "Modo offline: $formula não será instalado."; return 1; }
    has_cmd brew || { warn 'Homebrew ausente; não será instalado automaticamente.'; return 1; }
    if retry 2 5 run_with_timeout 600 brew install "$formula"; then
        info "Disponível após Brew: $formula"
        return 0
    fi
    warn "Falha no Brew: $formula"
    return 1
}

install_one_formula() {
    local formula="$1"
    (( OFFLINE )) && { warn "Modo offline: $formula não será instalado."; return 1; }
    has_cmd brew || { warn 'Homebrew ausente; não será instalado automaticamente.'; return 1; }
    if retry 2 5 run_with_timeout 600 brew install "$formula"; then
        info "Disponível após Brew: $formula"
        return 0
    fi
    warn "Falha no Brew: $formula"
    return 1
}

install_formulae() {
    local formula
    if ((${#missing[@]} > 0)); then
        info "Fórmulas essenciais ausentes: ${missing[*]}"
        if ask_yes_no 'Instalar as fórmulas essenciais ausentes pelo Homebrew?' S; then
            for formula in "${missing[@]}"; do
                has_cmd "$(formula_command "$formula")" || install_one_formula "$formula" || failed+=("$formula")
            done
        else
            warn 'Instalação das fórmulas essenciais ignorada.'
            failed+=("${missing[@]}")
        fi
    else
        info 'Nenhuma fórmula essencial ausente.'
    fi
    if ((${#missing_optional[@]} > 0)); then
        info "Fórmulas opcionais ausentes: ${missing_optional[*]}"
        if ask_yes_no 'Deseja instalar o Yazi pelo Homebrew?' N; then
            for formula in "${missing_optional[@]}"; do
                install_one_formula "$formula" || warn "$formula não foi instalado; continuando."
            done
        else
            info 'Yazi não será instalado; a configuração continuará sem o alias y.'
        fi
    fi
}

clone_plugins() {
    local plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins"
    local repository plugin_name target
    local repositories=(
        zsh-users/zsh-autosuggestions
        zdharma-continuum/fast-syntax-highlighting
        zsh-users/zsh-history-substring-search
        jeffreytse/zsh-vi-mode
    )

    if (( OFFLINE )); then
        warn 'Modo offline: plugins não serão baixados.'
        return 0
    fi
    if ! has_cmd git; then
        warn 'Git ausente: plugins ignorados.'
        return 0
    fi

    for repository in "${repositories[@]}"; do
        plugin_name="${repository##*/}"
        target="$plugin_dir/$plugin_name"
        if [[ -d "$target/.git" ]]; then
            info "Plugin já existe: $plugin_name"
            continue
        fi
        if [[ -e "$target" ]]; then
            warn "Destino incompleto ou ocupado: $target"
            continue
        fi
        if (( DRY_RUN )); then
            printf '[SIMULAÇÃO] clone %s -> %s\n' "$repository" "$target"
            continue
        fi
        mkdir -p "$plugin_dir"
        if retry 3 5 run_with_timeout 300 git clone --quiet --depth=1 --single-branch "https://github.com/$repository.git" "$target"; then
            info "Plugin instalado: $plugin_name"
        else
            rm -rf -- "$target"
            warn "Falha ao baixar: $repository"
        fi
    done
}

backup_file() {
    local source="$1" relative="$2"
    [[ -e "$source" ]] || return 0
    mkdir -p "$(dirname -- "$BACKUP_DIR/$relative")"
    cp -a -- "$source" "$BACKUP_DIR/$relative"
    printf '%s\n' "$relative" >> "$BACKUP_DIR/manifest.txt"
}

write_configs() {
    local zsh_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    local starship_dir="${XDG_CONFIG_HOME:-$HOME/.config}/starship"

    TMP_ROOT="$(mktemp -d)"
    mkdir -p "$TMP_ROOT/zsh" "$TMP_ROOT/starship"

    cat > "$TMP_ROOT/.zshenv" <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-$EDITOR}"
EOF

    cat > "$TMP_ROOT/zsh/.zshrc" <<'EOF'
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST AUTO_CD NO_BEEP
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
for module in aliases plugins yazi prompt; do
    [[ -r "$ZDOTDIR/$module.zsh" ]] && source "$ZDOTDIR/$module.zsh"
done
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi
EOF

    cat > "$TMP_ROOT/zsh/aliases.zsh" <<'EOF'
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons --group-directories-first -lh'
    alias la='eza --icons --group-directories-first -la'
else
    alias ll='ls -lh'
    alias la='ls -la'
fi
(( $+commands[bat] )) && alias cat='bat'
(( $+commands[fd] )) && alias ff='fd'
(( $+commands[rg] )) && alias rgg='rg'
alias gs='git status --short --branch'
alias y='yazi'
alias ..='cd ..'
alias ...='cd ../..'
EOF

    cat > "$TMP_ROOT/zsh/yazi.zsh" <<'EOF'
if (( $+commands[yazi] )); then
    alias y='yazi'
fi
EOF

    cat > "$TMP_ROOT/zsh/prompt.zsh" <<'EOF'
if (( $+commands[starship] )); then
    export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship/starship.toml}"
    eval "$(starship init zsh)"
fi
EOF

    cat > "$TMP_ROOT/zsh/plugins.zsh" <<'EOF'
PLUGIN_DIR="$ZDOTDIR/plugins"
load_zsh_plugin() {
    local repository="$1" plugin_name="${1##*/}" target="$PLUGIN_DIR/${1##*/}"
    [[ -d "$target" ]] || return 0
    if [[ -r "$target/$plugin_name.plugin.zsh" ]]; then
        source "$target/$plugin_name.plugin.zsh"
    elif [[ -r "$target/$plugin_name.zsh" ]]; then
        source "$target/$plugin_name.zsh"
    fi
}
load_zsh_plugin zsh-users/zsh-autosuggestions
load_zsh_plugin zdharma-continuum/fast-syntax-highlighting
load_zsh_plugin zsh-users/zsh-history-substring-search
load_zsh_plugin jeffreytse/zsh-vi-mode
EOF

    cat > "$TMP_ROOT/starship/starship.toml" <<'EOF'
add_newline = false
command_timeout = 1000
[character]
success_symbol = '[➜](bold green) '
error_symbol = '[✗](bold red) '
[directory]
truncation_length = 3
truncate_to_repo = true
[git_branch]
symbol = ' '
EOF

    has_cmd zsh || die 'Zsh é necessário para validar e configurar os arquivos.'
    zsh -n "$TMP_ROOT/.zshenv" "$TMP_ROOT/zsh/.zshrc" "$TMP_ROOT/zsh/aliases.zsh" "$TMP_ROOT/zsh/yazi.zsh" "$TMP_ROOT/zsh/prompt.zsh" "$TMP_ROOT/zsh/plugins.zsh"

    if (( DRY_RUN )); then
        info '[SIMULAÇÃO] Configuração validada; não será aplicada.'
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    : > "$BACKUP_DIR/manifest.txt"
    backup_file "$HOME/.zshenv" '.zshenv'
    backup_file "$zsh_dir/.zshrc" '.config/zsh/.zshrc'
    backup_file "$zsh_dir/aliases.zsh" '.config/zsh/aliases.zsh'
    backup_file "$zsh_dir/plugins.zsh" '.config/zsh/plugins.zsh'
    backup_file "$zsh_dir/yazi.zsh" '.config/zsh/yazi.zsh'
    backup_file "$zsh_dir/prompt.zsh" '.config/zsh/prompt.zsh'
    backup_file "$starship_dir/starship.toml" '.config/starship/starship.toml'

    mkdir -p "$zsh_dir" "$starship_dir"
    [[ -e "$HOME/.zshenv" ]] || install -m 0644 "$TMP_ROOT/.zshenv" "$HOME/.zshenv"
    [[ -e "$zsh_dir/.zshrc" ]] || install -m 0644 "$TMP_ROOT/zsh/.zshrc" "$zsh_dir/.zshrc"
    [[ -e "$zsh_dir/aliases.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/aliases.zsh" "$zsh_dir/aliases.zsh"
    [[ -e "$zsh_dir/plugins.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/plugins.zsh" "$zsh_dir/plugins.zsh"
    [[ -e "$zsh_dir/yazi.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/yazi.zsh" "$zsh_dir/yazi.zsh"
    [[ -e "$zsh_dir/prompt.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/prompt.zsh" "$zsh_dir/prompt.zsh"
    [[ -e "$starship_dir/starship.toml" ]] || install -m 0644 "$TMP_ROOT/starship/starship.toml" "$starship_dir/starship.toml"
}

show_zsh_instructions() {
    if ! has_cmd zsh; then
        warn 'Zsh não está disponível; nenhuma sessão foi alterada.'
        return 0
    fi
    printf '\n'
    info 'Configuração do Zsh, Starship, aliases e plugins concluída.'
    info 'O shell padrão do sistema não foi alterado nesta etapa.'
    info 'Para usar o ambiente configurado nesta sessão, execute:'
    printf '  exec %q\n' "$(command -v zsh)"
}

main() {
    show_environment
    check_aurora
    check_aurora_tools
    show_commands
    find_missing

    if (( DRY_RUN )); then
        info "Ausentes: ${missing[*]:-nenhuma}"
        info "Opcionais ausentes: ${missing_optional[*]:-nenhuma}"
        info 'Dry-run concluído sem downloads, backups ou alterações.'
        return 0
    fi

    install_formulae
    clone_plugins
    write_configs
    show_zsh_instructions

    local elapsed=$((SECONDS - START_TIME))
    info "Tempo total: $((elapsed / 60))m $((elapsed % 60))s"
    info "Log: $LOG_FILE"
    if ((${#failed[@]} > 0)); then
        warn "Falhas: ${failed[*]}"
        return 4
    fi
}

main
