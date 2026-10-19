#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly CONFIG_FILE="${FLATPAKS_CONFIG:-$PROJECT_DIR/config/flatpaks.list}"
readonly LOG_DIR="$PROJECT_DIR/logs"
readonly REMOTE_NAME="flathub"
readonly FORCE_SCOPE="${FLATPAK_SCOPE:-auto}"
readonly LOG_FILE="$LOG_DIR/flatpaks-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

declare -a CATEGORIES=() ALL_ENTRIES=() SELECTED_ENTRIES=()
declare -A CATEGORY_LABEL=()
declare -A ENTRY_BY_KEY=()
TOTAL=0 INSTALLED=0 ABSENT=0 FAILED=0 SKIPPED=0

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE"; }
warn() { log "AVISO: $*" >&2; }
fail() { log "ERRO: $*" >&2; }
cleanup() { local status=$?; if (( status == 130 )); then log "Execução interrompida; itens já concluídos foram preservados."; fi; exit "$status"; }
trap cleanup INT TERM

usage() {
    cat <<EOF
Uso: $(basename "$0") [opção]

Sem opção: abre o menu interativo.
--check       verifica todo o catálogo sem alterar o sistema.
--install     abre o menu interativo de instalação.
--status      mostra o status de todo o catálogo.
--all         seleciona todos os blocos e pede confirmação.
--help        mostra esta ajuda.

Variáveis:
  FLATPAKS_CONFIG=/caminho/flatpaks.list
  FLATPAK_SCOPE=auto|user|system
EOF
}

require_command() { command -v "$1" >/dev/null 2>&1 || { fail "Comando obrigatório ausente: $1"; exit 1; }; }
check_aurora() {
    [[ -r /usr/lib/os-release ]] || { warn "Não foi possível ler /usr/lib/os-release."; return; }
    # shellcheck disable=SC1091
    source /usr/lib/os-release
    local description="${PRETTY_NAME:-${NAME:-sistema desconhecido}}"
    log "Sistema detectado: $description"
    [[ "${ID:-}" == aurora || "$description" == *Aurora* ]] || warn "O sistema não parece ser Aurora; continuando com cuidado."
}
check_config() { [[ -f "$CONFIG_FILE" ]] || { fail "Catálogo não encontrado: $CONFIG_FILE"; exit 1; }; }
check_flathub() { flatpak remotes --columns=name 2>/dev/null | awk 'NF {print $1}' | grep -Fxq "$REMOTE_NAME" || { fail "Repositório Flathub não configurado."; exit 1; }; log "Repositório confirmado: $REMOTE_NAME"; }
scope_flag() { case "$1" in user) printf -- '--user';; system) printf -- '--system';; *) return 1;; esac; }
app_exists() { flatpak info "$(scope_flag "$2")" "$1" >/dev/null 2>&1; }
app_scope() { local id="$1" u=0 s=0; app_exists "$id" user && u=1; app_exists "$id" system && s=1; if ((u&&s)); then printf both; elif ((u)); then printf user; elif ((s)); then printf system; else printf none; fi; }
remote_exists() { flatpak remote-info "$REMOTE_NAME" "$1" >/dev/null 2>&1; }
version_of() { flatpak list "$(scope_flag "$2")" --app --columns=application,version 2>/dev/null | awk -F $'\t' -v id="$1" '$1==id {print $2; exit}'; }
scope_count() { flatpak list "$(scope_flag "$1")" --app --columns=application 2>/dev/null | awk 'NF{n++} END{print n+0}'; }
detect_scope() { [[ "$FORCE_SCOPE" == user || "$FORCE_SCOPE" == system ]] && { printf '%s' "$FORCE_SCOPE"; return; }; local u s; u="$(scope_count user)"; s="$(scope_count system)"; if ((s>u)); then printf system; elif ((u>s)); then printf user; else printf ambiguous; fi; }

load_catalog() {
    local line category name id description priority state extra key
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "${line//[[:space:]]/}" || "$line" == \#* ]] && continue
        IFS='|' read -r category name id description priority state extra <<< "$line"
        if [[ -z "${category:-}" || -z "${name:-}" || -z "${id:-}" ]]; then warn "Linha inválida ignorada: $line"; continue; fi
        [[ -n "${CATEGORY_LABEL[$category]+x}" ]] || { CATEGORIES+=("$category"); CATEGORY_LABEL[$category]="$category"; }
        key="${category}::${id}"
        ENTRY_BY_KEY[$key]="$category|$name|$id|${description:-}|${priority:-}|${state:-}"
        ALL_ENTRIES+=("${ENTRY_BY_KEY[$key]}")
    done < "$CONFIG_FILE"
    TOTAL="${#ALL_ENTRIES[@]}"
    ((TOTAL>0)) || { fail "Nenhum aplicativo ativo no catálogo."; exit 1; }
}

entry_fields() { IFS='|' read -r E_CATEGORY E_NAME E_ID E_DESCRIPTION E_PRIORITY E_STATE <<< "$1"; }
show_entry() {
    entry_fields "$1"; local scope version; scope="$(app_scope "$E_ID")"
    if [[ "$scope" == none ]]; then
        remote_exists "$E_ID" && printf '[AUSENTE] %s (%s)\n' "$E_NAME" "$E_ID" || printf '[NÃO ENCONTRADO] %s (%s)\n' "$E_NAME" "$E_ID"
    elif [[ "$scope" == both ]]; then printf '[DUPLICADO] %s (%s) user+system\n' "$E_NAME" "$E_ID"
    else version="$(version_of "$E_ID" "$scope")"; printf '[INSTALADO] %s (%s) %s versão=%s\n' "$E_NAME" "$E_ID" "$scope" "${version:-desconhecida}"; fi
}
status_entries() { local entry; for entry in "$@"; do show_entry "$entry"; done; }

choose_scope() {
    local detected="$1" choice
    if [[ "$detected" == user || "$detected" == system ]]; then printf '%s' "$detected"; return; fi
    printf '\nEscopo predominante não determinado.\n[1] system\n[2] user\n[0] cancelar\n' >&2
    read -r -p 'Escolha: ' choice
    case "$choice" in 1) printf system;; 2) printf user;; *) return 1;; esac
}
confirm() { local scope="$1" count="$2" answer; printf '\nSerão instalados %s aplicativo(s) ausente(s) no escopo %s.\n' "$count" "$scope"; read -r -p 'Continuar? [s/N]: ' answer; [[ "$answer" =~ ^[SsYy]$ ]]; }

install_entries() {
    local scope="$1" entry category name id description priority state current; local new=0 failed=0
    for entry in "$@"; do [[ "$entry" == "$scope" ]] && continue; entry_fields "$entry"; current="$(app_scope "$E_ID")"; [[ "$current" == none ]] && ((new+=1)); done
    if ((new==0)); then log "Nenhum aplicativo novo selecionado."; return 0; fi
    confirm "$scope" "$new" || { log "Instalação cancelada."; return 0; }
    for entry in "$@"; do [[ "$entry" == "$scope" ]] && continue; entry_fields "$entry"; current="$(app_scope "$E_ID")"; if [[ "$current" != none ]]; then log "PULADO: $E_NAME já instalado em $current."; continue; fi; if ! remote_exists "$E_ID"; then fail "Não encontrado no Flathub: $E_NAME ($E_ID)"; ((failed+=1)); continue; fi; log "Instalando: $E_NAME ($E_ID) em $scope"; if flatpak install "$(scope_flag "$scope")" -y "$REMOTE_NAME" "$E_ID" 2>&1 | tee -a "$LOG_FILE" && app_exists "$E_ID" "$scope"; then log "OK: $E_NAME"; else fail "Falha: $E_NAME ($E_ID)"; ((failed+=1)); fi; done
    log "Resumo: selecionados=$# novos=$new falhas=$failed"
}

category_menu() {
    local category="$1" choice entry n=0; local -a items=()
    for entry in "${ALL_ENTRIES[@]}"; do entry_fields "$entry"; [[ "$E_CATEGORY" == "$category" ]] && items+=("$entry"); done
    while true; do
        printf '\nBloco: %s\n' "$category"
        printf '[1] Instalar todos\n'
        for entry in "${items[@]}"; do ((n+=1)); entry_fields "$entry"; printf '[%s] %s (%s)\n' "$((n+1))" "$E_NAME" "$E_ID"; done
        printf '[0] Voltar\n'
        read -r -p 'Escolha: ' choice
        if [[ "$choice" == 0 ]]; then return; fi
        local scope; scope="$(choose_scope "$(detect_scope)")" || continue
        if [[ "$choice" == 1 ]]; then install_entries "$scope" "${items[@]}"; elif [[ "$choice" =~ ^[0-9]+$ ]] && ((choice>=2 && choice<=n+1)); then install_entries "$scope" "${items[$((choice-2))]}"; else warn "Opção inválida."; fi
        n=0
    done
}
main_menu() {
    local choice i category; while true; do
        printf '\nInstalador Flatpak para Aurora v%s\n' "$SCRIPT_VERSION"
        for i in "${!CATEGORIES[@]}"; do printf '[%s] %s\n' "$((i+1))" "${CATEGORIES[$i]}"; done
        printf '[A] Instalar todos os blocos\n[S] Ver status\n[Q] Sair\n'
        read -r -p 'Escolha: ' choice
        case "$choice" in
            [Aa]) local scope; scope="$(choose_scope "$(detect_scope)")" || continue; install_entries "$scope" "${ALL_ENTRIES[@]}";;
            [Ss]) status_entries "${ALL_ENTRIES[@]}";;
            [Qq]) return 0;;
            *) if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice>=1 && choice<=${#CATEGORIES[@]})); then category_menu "${CATEGORIES[$((choice-1))]}"; else warn "Opção inválida."; fi;;
        esac
    done
}
main() {
    local mode=menu
    while (($#)); do case "$1" in --check) mode=check;; --install) mode=menu;; --status) mode=status;; --all) mode=all;; --help|-h) usage; return 0;; *) fail "Opção desconhecida: $1"; usage; return 2;; esac; shift; done
    require_command flatpak; check_aurora; check_config; check_flathub; load_catalog
    log "Aurora Setup Flatpak v$SCRIPT_VERSION | catálogo=$CONFIG_FILE | log=$LOG_FILE"
    case "$mode" in check) status_entries "${ALL_ENTRIES[@]}";; status) status_entries "${ALL_ENTRIES[@]}";; menu) main_menu;; all) local scope; scope="$(choose_scope "$(detect_scope)")" || return 0; install_entries "$scope" "${ALL_ENTRIES[@]}";; esac
}
main "$@"
