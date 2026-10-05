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

usage(){ cat <<'HELP'
Uso: bash personalize-aurora-terminal.sh [opções]
  --dry-run       diagnóstico, sem downloads ou alterações
  --offline       não usa Homebrew nem rede
  --yes           aceita confirmações padrão
  --change-shell  pergunta se Zsh deve virar shell de login
  --help          mostra esta ajuda

Pré-requisitos manuais: Aurora DX/Developer Mode, Homebrew e, de preferência,
Aurora CLI já ativados. Este script não ativa essas etapas.
HELP
}
for arg in "$@"; do case "$arg" in
  --dry-run) DRY_RUN=1;; --offline) OFFLINE=1;; --yes) ASSUME_YES=1;;
  --change-shell) CHANGE_SHELL=1;; --help|-h) usage; exit 0;;
  *) printf 'Opção desconhecida: %s\n' "$arg" >&2; exit 2;; esac; done
[[ $(id -u) -ne 0 ]] || { printf 'Execute como usuário comum, sem sudo.\n' >&2; exit 1; }

info(){ printf '[INFO] %s\n' "$*"; }
warn(){ printf '[AVISO] %s\n' "$*" >&2; }
die(){ printf '[ERRO] %s\n' "$*" >&2; exit 1; }
has_cmd(){ command -v "$1" >/dev/null 2>&1; }
cleanup(){ [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]] && rm -rf -- "$TMP_ROOT"; }
trap cleanup EXIT
trap 'printf "[ERRO] linha %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

ask_yes_no(){
  local q="$1" default="${2:-N}" answer=''
  if (( ASSUME_YES )); then [[ "$default" == S ]]; return; fi
  if [[ "$default" == S ]]; then read -r -p "$q [S/n] " answer || true; answer="${answer:-S}";
  else read -r -p "$q [s/N] " answer || true; answer="${answer:-N}"; fi
  [[ "$answer" =~ ^[SsYy]$ ]]
}
retry(){
  local attempts="$1" delay="$2"; shift 2; local n
  for ((n=1;n<=attempts;n++)); do
    if "$@"; then return 0; fi
    if (( n < attempts )); then warn "Tentativa $n/$attempts falhou; aguardando ${delay}s."; sleep "$delay"; fi
  done
  return 1
}

if (( ! DRY_RUN )); then mkdir -p "$LOG_DIR"; exec > >(tee -a "$LOG_FILE") 2>&1; fi

show_environment(){
  if [[ -r /etc/os-release ]]; then . /etc/os-release; info "Distribuição: ${PRETTY_NAME:-desconhecida}"; info "ID: ${ID:-desconhecido}"; fi
  info "Kernel: $(uname -srmo)"; info "Usuário: $(id -un)"; info "Shell: ${SHELL:-não definido}"
  info "Projeto: $PROJECT_NAME"; info "Script: $SCRIPT_DIR"
  if (( DRY_RUN )); then info 'Modo: dry-run'; elif (( OFFLINE )); then info 'Modo: offline'; else info 'Modo: normal'; fi
}
check_aurora(){
  local ok=0
  if [[ -r /etc/os-release ]]; then . /etc/os-release; [[ "${ID:-}" == aurora || "${VARIANT_ID:-}" == aurora* || "${PRETTY_NAME:-}" == *Aurora* ]] && ok=1; fi
  if (( ! ok )); then warn 'Sistema não identificado claramente como Aurora.'; ask_yes_no 'Continuar mesmo assim?' N || die 'Cancelado.'; fi
}
check_aurora_tools(){
  if has_cmd ujust; then ujust --list 2>/dev/null | grep -E 'devmode|dx-group|aurora-cli|update' || true; else warn 'ujust ausente.'; fi
  if has_cmd brew; then info "Homebrew: $(brew --version | head -n1)"; else warn 'Homebrew ausente.'; fi
}
show_commands(){ local c; for c in brew zsh git starship zoxide fzf rg fd bat eza yazi; do if has_cmd "$c"; then info "$c: $(command -v "$c")"; else info "$c: ausente"; fi; done; }

required=(zsh starship zoxide fzf ripgrep fd bat eza git yazi)
missing=(); failed=()
formula_command(){ [[ "$1" == ripgrep ]] && printf rg || printf '%s' "$1"; }
find_missing(){ local f c; for f in "${required[@]}"; do c="$(formula_command "$f")"; has_cmd "$c" || missing+=("$f"); done; }
run_with_timeout(){ if has_cmd timeout; then timeout "$@"; else shift; "$@"; fi; }
install_formulae(){
  ((${#missing[@]}==0)) && { info 'Nenhuma fórmula ausente.'; return; }
  info "Fórmulas ausentes: ${missing[*]}"
  if (( OFFLINE )); then warn 'Offline: não instalarei fórmulas.'; failed+=("${missing[@]}"); return; fi
  has_cmd brew || { warn 'Homebrew ausente; não será instalado automaticamente.'; failed+=("${missing[@]}"); return; }
  ask_yes_no 'Instalar fórmulas ausentes pelo Homebrew?' S || { warn 'Instalação ignorada.'; failed+=("${missing[@]}"); return; }
  local f
  for f in "${missing[@]}"; do
    if retry 2 5 run_with_timeout 600 brew install "$f"; then info "Disponível após Brew: $f"; else warn "Falha no Brew: $f"; failed+=("$f"); fi
  done
}

clone_plugins(){
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins" repo name target
  local repos=(zsh-users/zsh-autosuggestions zdharma-continuum/fast-syntax-highlighting zsh-users/zsh-history-substring-search jeffreytse/zsh-vi-mode)
  (( OFFLINE )) && { warn 'Offline: plugins não serão baixados.'; return; }
  has_cmd git || { warn 'Git ausente: plugins ignorados.'; return; }
  for repo in "${repos[@]}"; do
    name="${repo##*/}"; target="$dir/$name"
    if [[ -d "$target/.git" ]]; then info "Plugin já existe: $name"; continue; fi
    [[ ! -e "$target" ]] || { warn "Destino incompleto/ocupado: $target"; continue; }
    if (( DRY_RUN )); then printf '[SIMULAÇÃO] clone %s -> %s\n' "$repo" "$target"; continue; fi
    mkdir -p "$dir"
    if retry 3 5 run_with_timeout 300 git clone --quiet --depth=1 --single-branch "https://github.com/$repo.git" "$target"; then info "Plugin instalado: $name"; else rm -rf -- "$target"; warn "Falha ao baixar: $repo"; fi
  done
}

backup_file(){ local src="$1" rel="$2"; [[ -e "$src" ]] || return 0; mkdir -p "$(dirname -- "$BACKUP_DIR/$rel")"; cp -a -- "$src" "$BACKUP_DIR/$rel"; printf '%s\n' "$rel" >> "$BACKUP_DIR/manifest.txt"; }
write_configs(){
  local zd="${XDG_CONFIG_HOME:-$HOME/.config}/zsh" sd="${XDG_CONFIG_HOME:-$HOME/.config}/starship"
  TMP_ROOT="$(mktemp -d)"; mkdir -p "$TMP_ROOT/zsh" "$TMP_ROOT/starship"
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
if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; fi
EOF
  cat > "$TMP_ROOT/zsh/aliases.zsh" <<'EOF'
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'; alias ll='eza --icons --group-directories-first -lh'; alias la='eza --icons --group-directories-first -la'
else
  alias ll='ls -lh'; alias la='ls -la'
fi
(( $+commands[bat] )) && alias cat='bat'
(( $+commands[fd] )) && alias ff='fd'
(( $+commands[rg] )) && alias rgg='rg'
alias gs='git status --short --branch'; alias y='yazi'; alias ..='cd ..'; alias ...='cd ../..'
EOF
  cat > "$TMP_ROOT/zsh/yazi.zsh" <<'EOF'
if (( $+commands[yazi] )); then alias y='yazi'; fi
EOF
  cat > "$TMP_ROOT/zsh/prompt.zsh" <<'EOF'
if (( $+commands[starship] )); then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship/starship.toml}"
  eval "$(starship init zsh)"
fi
EOF
  cat > "$TMP_ROOT/zsh/plugins.zsh" <<'EOF'
PLUGIN_DIR="$ZDOTDIR/plugins"
load_zsh_plugin(){ local repo="$1" name="${1##*/}" target="$PLUGIN_DIR/${1##*/}"; [[ -d "$target" ]] || return 0; if [[ -r "$target/$name.plugin.zsh" ]]; then source "$target/$name.plugin.zsh"; elif [[ -r "$target/$name.zsh" ]]; then source "$target/$name.zsh"; fi; }
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
  if ! has_cmd zsh; then die 'Zsh é necessário para validar e configurar os arquivos.'; fi
  zsh -n "$TMP_ROOT/.zshenv" "$TMP_ROOT/zsh/.zshrc" "$TMP_ROOT/zsh/aliases.zsh" "$TMP_ROOT/zsh/yazi.zsh" "$TMP_ROOT/zsh/prompt.zsh" "$TMP_ROOT/zsh/plugins.zsh"
  if (( DRY_RUN )); then info '[SIMULAÇÃO] Configuração validada; não será aplicada.'; return; fi
  mkdir -p "$BACKUP_DIR"; : > "$BACKUP_DIR/manifest.txt"
  backup_file "$HOME/.zshenv" '.zshenv'; backup_file "$zd/.zshrc" '.config/zsh/.zshrc'; backup_file "$zd/aliases.zsh" '.config/zsh/aliases.zsh'; backup_file "$zd/plugins.zsh" '.config/zsh/plugins.zsh'; backup_file "$zd/yazi.zsh" '.config/zsh/yazi.zsh'; backup_file "$zd/prompt.zsh" '.config/zsh/prompt.zsh'; backup_file "$sd/starship.toml" '.config/starship/starship.toml'
  mkdir -p "$zd" "$sd"
  [[ -e "$HOME/.zshenv" ]] || install -m 0644 "$TMP_ROOT/.zshenv" "$HOME/.zshenv"
  [[ -e "$zd/.zshrc" ]] || install -m 0644 "$TMP_ROOT/zsh/.zshrc" "$zd/.zshrc"
  [[ -e "$zd/aliases.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/aliases.zsh" "$zd/aliases.zsh"
  [[ -e "$zd/plugins.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/plugins.zsh" "$zd/plugins.zsh"
  [[ -e "$zd/yazi.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/yazi.zsh" "$zd/yazi.zsh"
  [[ -e "$zd/prompt.zsh" ]] || install -m 0644 "$TMP_ROOT/zsh/prompt.zsh" "$zd/prompt.zsh"
  [[ -e "$sd/starship.toml" ]] || install -m 0644 "$TMP_ROOT/starship/starship.toml" "$sd/starship.toml"
}
change_shell(){ (( CHANGE_SHELL )) || { info 'Shell padrão preservado.'; return; }; has_cmd zsh || { warn 'Zsh ausente.'; return; }; ask_yes_no 'Tornar Zsh o shell padrão?' N && chsh -s "$(command -v zsh)"; }
main(){ show_environment; check_aurora; check_aurora_tools; show_commands; find_missing; if (( DRY_RUN )); then info "Ausentes: ${missing[*]:-nenhuma}"; info 'Dry-run concluído sem alterações.'; return 0; fi; install_formulae; clone_plugins; write_configs; change_shell; local elapsed=$((SECONDS-START_TIME)); info "Tempo total: $((elapsed/60))m $((elapsed%60))s"; info "Log: $LOG_FILE"; ((${#failed[@]}==0)) || { warn "Falhas: ${failed[*]}"; return 4; }; }
main
