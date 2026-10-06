#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Importa AppImages pelo Gear Lever no Aurora Linux.
# Entrada: ~/Downloads
# Destino configurado no Gear Lever: ~/Applications/AppImages
# Não baixa aplicativos, não usa sudo e não apaga arquivos automaticamente.
# Uso: ./install-appimage-aurora.sh [--dry-run]

DRY_RUN=0
LOG_DIR="$HOME/.local/state/aurora-appimage"
LOG_FILE=""
DOWNLOAD_DIR="$HOME/Downloads"
APPIMAGE_DIR="$HOME/Applications/AppImages"
GEARLEVER_ID='it.mijorus.gearlever'
GEARLEVER_CMD=()

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

info(){ printf '[INFO] %s\n' "$*"; }
warn(){ printf '[AVISO] %s\n' "$*" >&2; }
die(){ printf '[ERRO] %s\n' "$*" >&2; exit 1; }

on_error(){
  local code=$?
  warn "Falha na linha ${1:-desconhecida}; código $code."
  [[ -n "$LOG_FILE" ]] && warn "Log: $LOG_FILE"
  exit "$code"
}
trap 'on_error "$LINENO"' ERR
trap 'die "Operação interrompida pelo usuário."' INT TERM

run(){
  if (( DRY_RUN )); then
    printf '[SIMULAÇÃO]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

command_exists(){ command -v "$1" >/dev/null 2>&1; }

confirm(){
  local answer
  (( DRY_RUN )) && return 1
  read -r -p "$1 [s/N] " answer || return 1
  [[ "$answer" =~ ^[SsYy]$ ]]
}

setup_log(){
  if (( DRY_RUN )); then return; fi
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/import-$(date +%Y-%m-%d_%H%M%S).log"
  exec > >(tee -a "$LOG_FILE") 2>&1
}

require_user(){
  [[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum; não use sudo.'
}

check_environment(){
  [[ -d "$DOWNLOAD_DIR" ]] || die "Pasta de Downloads não encontrada: $DOWNLOAD_DIR"
  if [[ -e "$APPIMAGE_DIR" && ! -d "$APPIMAGE_DIR" ]]; then
    die "O destino existe, mas não é uma pasta: $APPIMAGE_DIR"
  fi
  if (( ! DRY_RUN )); then
    mkdir -p "$APPIMAGE_DIR" || die "Não foi possível criar: $APPIMAGE_DIR"
    [[ -w "$APPIMAGE_DIR" ]] || die "Sem permissão de escrita: $APPIMAGE_DIR"
  fi
}

find_gearlever(){
  if command_exists gearlever; then
    GEARLEVER_CMD=(gearlever)
  elif command_exists flatpak && flatpak info "$GEARLEVER_ID" >/dev/null 2>&1; then
    GEARLEVER_CMD=(flatpak run "$GEARLEVER_ID")
  else
    GEARLEVER_CMD=()
  fi
}

ensure_gearlever(){
  find_gearlever
  ((${#GEARLEVER_CMD[@]})) && return 0

  command_exists flatpak || die 'Flatpak não foi encontrado. Instale o Gear Lever pelo Bazaar/Flathub.'
  confirm 'Gear Lever não foi encontrado. Instalar pelo Flathub agora?' ||
    die 'Operação cancelada: o Gear Lever é necessário.'

  run flatpak install --user flathub "$GEARLEVER_ID" ||
    die 'Falha ao instalar o Gear Lever pelo Flathub.'

  find_gearlever
  ((${#GEARLEVER_CMD[@]})) || die 'Gear Lever não foi encontrado após a instalação.'
}

list_candidates(){
  find "$DOWNLOAD_DIR" -maxdepth 1 -type f \( -iname '*.AppImage' -o -iname '*.appimage' \) -print 2>/dev/null | sort
}

choose_file(){
  local -n output_ref="$1"
  local -a candidates=()
  mapfile -t candidates < <(list_candidates)

  ((${#candidates[@]})) || {
    warn "Nenhum AppImage encontrado em $DOWNLOAD_DIR"
    info 'Baixe um AppImage de fonte confiável e execute o script novamente.'
    exit 0
  }

  printf '\nAppImages disponíveis:\n'
  local i
  for i in "${!candidates[@]}"; do
    printf '  %d) %s\n' "$((i+1))" "${candidates[i]##*/}"
  done
  printf '\n'

  if (( DRY_RUN )); then
    output_ref="${candidates[0]}"
    info "[SIMULAÇÃO] Primeiro arquivo selecionado: ${candidates[0]##*/}"
    return 0
  fi

  local choice
  read -r -p 'Escolha o número do AppImage: ' choice || die 'Entrada cancelada.'
  [[ "$choice" =~ ^[0-9]+$ ]] || die 'Escolha inválida.'
  (( choice >= 1 && choice <= ${#candidates[@]} )) || die 'Escolha fora da lista.'
  output_ref="${candidates[choice-1]}"
}

validate_file(){
  local file="$1"
  [[ -f "$file" ]] || die "Arquivo não encontrado: $file"
  [[ -r "$file" ]] || die "Arquivo sem permissão de leitura: $file"
  [[ -s "$file" ]] || die "Arquivo vazio: $file"
  [[ "$file" == *.AppImage || "$file" == *.appimage ]] || die 'Extensão inválida.'
}

make_executable(){
  local file="$1"
  validate_file "$file"
  run chmod u+x "$file" || die "Não foi possível tornar executável: $file"
  if (( ! DRY_RUN )) && [[ ! -x "$file" ]]; then
    die "O arquivo continua sem permissão de execução: $file"
  fi
}

open_in_gearlever(){
  local file="$1"
  info "Abrindo no Gear Lever: ${file##*/}"
  info 'A movimentação será controlada pela opção configurada no Gear Lever.'
  "${GEARLEVER_CMD[@]}" "$file" || {
    warn 'O Gear Lever não conseguiu abrir o arquivo pela linha de comando.'
    warn 'Abra o Gear Lever pelo menu e importe o arquivo manualmente:'
    warn "$file"
    return 1
  }
}

verify_destination(){
  local source_file="$1"
  local filename="${source_file##*/}"
  local destination="$APPIMAGE_DIR/$filename"

  if [[ -e "$destination" ]]; then
    info "AppImage encontrado no destino: $destination"
    return 0
  fi

  warn 'O arquivo ainda não apareceu na pasta de destino.'
  warn "Destino esperado: $APPIMAGE_DIR"
  warn 'Não apagarei o arquivo original de Downloads.'
  warn 'Confirme a opção Mover AppImages para a pasta de destino no Gear Lever.'
  return 1
}

main(){
  require_user
  setup_log
  check_environment

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    info "Sistema: ${PRETTY_NAME:-desconhecido}"
  fi
  info "Entrada: $DOWNLOAD_DIR"
  info "Destino configurado: $APPIMAGE_DIR"

  ensure_gearlever

  local selected
  choose_file selected
  make_executable "$selected"

  if (( DRY_RUN )); then
    info '[SIMULAÇÃO] O arquivo seria aberto pelo Gear Lever.'
    info '[SIMULAÇÃO] O original não seria apagado.'
    exit 0
  fi

  open_in_gearlever "$selected" || exit 1
  sleep 2
  verify_destination "$selected" || exit 2
  info 'Importação concluída.'
  info 'O aplicativo pode ser aberto pelo menu do KDE.'
  [[ -n "$LOG_FILE" ]] && info "Log salvo em: $LOG_FILE"
}

main "$@"
